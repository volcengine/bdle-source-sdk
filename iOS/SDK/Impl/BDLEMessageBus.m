//
//  BDLEMessageBus.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEMessageBus.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "GCDAsyncSocket+BDLE.h"
#import "BDLEUtils.h"

#define BDLE_SOCKET_MSG_VERSION 1

#define BDLE_ENABLE_SOCKET_LOG 1

@interface BDLESocketRequest : NSObject

// 消息是用哪个socket发出去的
@property (nonatomic, weak) GCDAsyncSocket *socket;

@property (nonatomic, strong) BDLEPPBaseCmd *message;

@property (nonatomic, copy) BDLESocketResponseBlock completion;

@property (nonatomic, assign) double sendTs;
@property (nonatomic, assign) double ackTs;

- (NSString *)messageId;

@end

@implementation BDLESocketRequest

- (NSString *)messageId {
    if (self.message) {
        return self.message.messageId;
    }
    return nil;
}

@end



@interface BDLEMessageBus () <GCDAsyncSocketDelegate> {
    // 所有连接共用这两个tag
    long _socketWriteTag;
    long _socketReadTag;
}

// 真正发送的请求队列
@property (nonatomic, strong) NSMutableArray<BDLESocketRequest *> *requestQueue;
@property (nonatomic, strong) NSLock *requestQueueLock;

// 缓存的请求队列，短连请求会先存到这里，等连接上之后取出并发送
@property (nonatomic, strong) NSMutableArray<BDLESocketRequest *> *requestCacheQueue;
@property (nonatomic, strong) NSLock *requestCacheLock;

@property (nonatomic, strong) NSLock *readDataLock;

@property (nonatomic, strong) NSMutableArray<GCDAsyncSocket *> *shortConnectionPool;
@property (nonatomic, strong) NSLock *shortConnectionPoolLock;

// key=ip+port
@property (nonatomic, strong) NSMutableDictionary<NSString *, GCDAsyncSocket *> *longConnectionDict;

@property (nonatomic, copy) NSString *latestConnectId;

@property (nonatomic, copy) NSData *unhandleData;

@property (nonatomic, copy) NSString *ipAddress;
@property (nonatomic, assign) int port;

@end

@implementation BDLEMessageBus

- (instancetype)init {
    if (self = [super init]) {
        _requestQueue = [NSMutableArray array];
        _requestCacheQueue = [NSMutableArray array];
        _requestQueueLock = [[NSLock alloc] init];
        _requestCacheLock = [[NSLock alloc] init];
        _readDataLock = [[NSLock alloc] init];
        _shortConnectionPool = [NSMutableArray array];
        _shortConnectionPoolLock = [[NSLock alloc] init];
        _longConnectionDict = [NSMutableDictionary dictionary];
        _socketWriteTag = 0;
        _socketReadTag = 0;
    }
    return self;
}

- (void)dealloc {
    NSString *cmds = [self requestQueueCmds];
    bdle_log_info(self, @"[BDLE][Socket] %p msgBus dealloc, reqQueueCnt=%ld, cmds=%@", &self, (long)_requestQueue.count, cmds);
}

- (BOOL)connect:(NSString *)ipAddress port:(int)port error:(NSError **)error {
    bdle_log_info(self, @"[BDLE][Socket] %p connect invoked, ip=%@:%d", &self, ipAddress, port);
    NSString *key = [self deviceCacheKey:ipAddress port:port];
    if (self.longConnectionDict[key]) {
        // 创建长连接，但该设备的长连接已经存在
        bdle_log_info(self, @"[BDLE][Socket] connect failed, reason=already_exists");
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"bdle.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"connection exists"}];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(messageBus:didConnected:)]) {
                [self.delegate messageBus:self didConnected:nil];
            }
        });
        return YES;
    }
    self.ipAddress = ipAddress;
    self.port = port;

    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    self.longConnectionDict[key] = socket;
    socket.socketId = [BDLEUtils getRandomUUID];
    socket.connectionType = BDLESocketConnectionTypeLong;
    socket.remoteIpAddress = ipAddress;
    socket.remotePort = port;
    bdle_log_info(self, @"[BDLE][Socket] connect success, ip=%@:%d, socketId=%@", ipAddress, port, socket.socketId);
    BOOL ret = [socket connectToHost:ipAddress onPort:port error:error];
    return ret;
}

- (void)disconnect {
    bdle_log_info(self, @"[BDLE][Socket] %p disconnect invoked", &self);
    for (GCDAsyncSocket *sock in [self.longConnectionDict allValues]) {
        bdle_log_info(self, @"[BDLE][Socket] disconnect for socket, %@", sock.socketId);
        [sock disconnect];
    }
    [self.longConnectionDict removeAllObjects];
}

- (void)sendMessageRequest:(BDLEPPBaseCmd *)message
                      type:(BDLESocketRequestType)type
                 ipAddress:(NSString *)ipAddress
                      port:(int)port
                completion:(BDLESocketResponseBlock _Nullable)completion {
    [self.requestCacheLock lock];
    bdle_log_info(self, @"[BDLE][Socket] sendMessageRequest, reqQueueCnt=%ld, cmds=%@", (long)self.requestQueue.count, [self requestQueueCmds]);
    if (BDLE_isEmptyString(message.messageId)) {
        message.version = BDLE_SOCKET_MSG_VERSION;
        message.messageId = [BDLEUtils getRandomUUID];
    }
    if (!BDLE_isEmptyString(message.connectId)) {
        // 如果消息包含了connectId，则更新到缓存
        self.latestConnectId = message.connectId;
    }
    // 先检查是否有长连
    NSString *key = [self deviceCacheKey:ipAddress port:port];
    if (self.longConnectionDict[key]) {
        // 能找到长连，直接用长连发
        bdle_log_info(self, @"[BDLE][Socket] sendMessageRequest using exist long connection");
        GCDAsyncSocket *socket = self.longConnectionDict[key];
        [self doSendSocketMessageInternal:socket message:message completion:completion];
    } else {
        // 没找到长连，创建一个短连，并缓存消息，等短连完成连接，再发这条消息
        GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        [self.shortConnectionPoolLock lock];
        [self.shortConnectionPool addObject:socket];
        [self.shortConnectionPoolLock unlock];
        socket.socketId = [BDLEUtils getRandomUUID];
        socket.connectionType = BDLESocketConnectionTypeShort;
        socket.remoteIpAddress = ipAddress;
        socket.remotePort = port;

        NSError *error = nil;
        [socket connectToHost:ipAddress onPort:port error:&error];

        bdle_log_info(self, @"[BDLE][Socket] sendMessageRequest using short connection, socket=%@(%@) connectToHost, ip=%@:%d, messageId=%@", socket, socket.socketId, ipAddress, port, message.messageId);

        // 先把消息缓存，待短连完成连接以后，再取出缓存发送
        BDLESocketRequest *request = [[BDLESocketRequest alloc] init];
        request.socket = socket;
        request.message = message;
        request.completion = completion;
        [self.requestCacheQueue addObject:request];
    }
    [self.requestCacheLock unlock];
}

#pragma mark - Private
- (void)doSendSocketMessageInternal:(GCDAsyncSocket *)socket message:(BDLEPPBaseCmd *)message completion:(BDLESocketResponseBlock _Nullable)completion {
    bdle_log_info(self, @"[BDLE][Socket] doSendSocketMessageInternal invoked, socketId=%@, msgId=%@", socket.socketId, message.messageId);

    NSString *messageString = [message jsonString];
    if (BDLE_isEmptyString(messageString)) {
        bdle_log_info(self, @"[BDLE][Socket] doSendSocketMessageInternal failed, reason=json_string_invalid");
        NSError *error = [NSError errorWithDomain:@"bdle.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"message json invalid"}];
        completion(nil, error);
        return;
    }
    NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    if (messageData.length == 0) {
        bdle_log_info(self, @"[BDLE][Socket] doSendSocketMessageInternal failed, reason=json_string2data_failed");
        NSError *error = [NSError errorWithDomain:@"bdle.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"message json convert data failed"}];
        completion(nil, error);
        return;
    }
    NSError *convertError;
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:messageData options:kNilOptions error:&convertError];
    if (convertError || ![messageDict isKindOfClass:[NSDictionary class]]) {
        bdle_log_info(self, @"[BDLE][Socket] doSendSocketMessageInternal failed, reason=json_data2dict_failed");
        NSError *error = [NSError errorWithDomain:@"bdle.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"message json convert dict failed"}];
        completion(nil, error);
        return;
    }

    if (![message.body.cmd isEqualToString:kBDLEPPCmdKey_PushMediaInfo] &&
        ![message.body.cmd isEqualToString:kBDLEPPCmdKey_PushStatusInfo] &&
        ![message.body.cmd isEqualToString:kBDLEPPCmdKey_PushRuntimeInfo]) {
        [self.requestQueueLock lock];
        BDLESocketRequest *request = [[BDLESocketRequest alloc] init];
        request.socket = socket;
        request.message = message;
        request.completion = completion;
        request.sendTs = CFAbsoluteTimeGetCurrent();
        [self.requestQueue addObject:request];
        [self.requestQueueLock unlock];
    }
    // 要发送消息出去时，追加connectId
    if (BDLE_isEmptyString(message.connectId) && !BDLE_isEmptyString(self.latestConnectId)) {
        message.connectId = self.latestConnectId;
    }

    // 发消息埋点
    NSMutableDictionary *eventParams;
    if ([self.eventDataSource respondsToSelector:@selector(messageBus:eventExtraDictionary:)]) {
        eventParams = [[self.eventDataSource messageBus:self eventExtraDictionary:message.body.cmd] mutableCopy];
    } else {
        eventParams = [NSMutableDictionary dictionary];
    }

    NSDictionary *convertedDict = @{@"encrypt": @(0), @"content": messageDict ?: @{}};
    NSString *convertedString = [BDLEUtils getJsonStringWithoutEscapingSlashes:convertedDict];
    NSData *data = [convertedString dataUsingEncoding:NSUTF8StringEncoding];
    if ([data isKindOfClass:[NSData class]] && data.length > 0) {
        uint32_t dataLength = (uint32_t)data.length;
        NSMutableData *msgData = [NSMutableData data];
        [msgData appendBytes:&dataLength length:sizeof(dataLength)];
        [msgData appendData:data];
        [socket writeData:msgData withTimeout:-1 tag:_socketWriteTag];
        bdle_log_info(self, @"[BDLE][Socket] doSendSocketMessageInternal, writeData, socket=%@, msg=%@, tag=%ld, messageId=%@", socket, convertedString, _socketWriteTag, message.messageId);

#if BDLE_ENABLE_SOCKET_LOG
        if (![message.body.cmd isEqualToString:kBDLEPPCmdKey_GetStatusInfo]) {
            bdle_log_info(self, @"[BDLE][Socket] 🔺UplinkMsg(%@)(%ld): %@", message.body.cmd, _socketWriteTag, convertedString);
        } else {
            bdle_log_info(self, @"[BDLE][Socket] 🔺UpPollingMsg(%@)(%ld): %@", message.body.cmd, _socketWriteTag, convertedString);
        }
#endif
        _socketWriteTag += 1;
    }
}

- (NSString *)deviceCacheKey:(NSString *)ipAddress port:(int)port {
    return [NSString stringWithFormat:@"%@:%d", ipAddress, port];
}

// 数据拆包（可递归）
- (void)handlePacketSticking:(GCDAsyncSocket *)sock data:(NSData *)data tag:(long)tag {
    bdle_log_info(self, @"[BDLE][Socket] handlePacketSticking invoked, data.length=%ld", data.length);
    if (![data isKindOfClass:[NSData class]]) {
        return;
    }

    NSData *unhandledData = data;
    static int uint32Size = sizeof(uint32_t);
    if (sock.leftReadBytes <= 0) {
        bdle_log_info(self, @"[BDLE][Socket] handlePacketSticking sock.leftReadBytes<=0, unhandledData.length=%ld", unhandledData.length);
        // socket当前没有要读的数据，先拿一个数据包长度
        if (unhandledData.length <= uint32Size) {
            // 要读取的数据甚至不包含一个完整的长度包
            bdle_log_info(self, @"[BDLE][Socket] socket(%@) didReadData with tag(%ld) parsed into invalid packet, len=%ld", sock.socketId, tag, (long)unhandledData.length);
            return;
        }
        // 解析出待读取的数据长度
        const void *bytes = [unhandledData bytes];
        uint32_t dataLength;
        memcpy(&dataLength, bytes, uint32Size);
        dataLength = CFSwapInt32HostToLittle(dataLength);
        sock.leftReadBytes = dataLength;
        bdle_log_info(self, @"[BDLE][Socket] socket(%@) didReadData with tag(%ld) parsed into length packet, value=%u", sock.socketId, tag, dataLength);

        // 成功解析出数据长度后，把前面的4字节丢弃
        unhandledData = [unhandledData subdataWithRange:NSMakeRange(uint32Size, unhandledData.length - uint32Size)];
        bdle_log_info(self, @"[BDLE][Socket] handlePacketSticking parsedLenPkt.length=%u, unhandledData.length=%ld", dataLength, unhandledData.length);
    }
    // 需要填充数据
    if (sock.leftReadBytes > 0) {
        NSData *contentData = nil;
        if (unhandledData.length >= sock.leftReadBytes) {
            // 本地数据足够填充这次消息
            contentData = [unhandledData subdataWithRange:NSMakeRange(0, sock.leftReadBytes)];
            NSString *logStr = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
            bdle_log_info(self, @"[BDLE][Socket] socket(%@) didReadData with tag(%ld) parsed into data packet, data=%@, readLength=%u, dataTotalLength=%ld", sock.socketId, tag, logStr, sock.leftReadBytes, data.length);

#if BDLE_ENABLE_SOCKET_LOG
            NSString *cmd = [self getRegexPartFrom:logStr keyword:@"cmd"];
            if (![cmd isEqualToString:kBDLEPPCmdKey_GetStatusInfo] && logStr.length > 0) {
                bdle_log_info(self, @"[BDLE][Socket] ⬇️DownlinkMsg(%@)(%ld): %@", cmd, tag, logStr);
            } else {
                bdle_log_info(self, @"[BDLE][Socket] ⬇️DownPollingMsg(%@)(%ld): %@", cmd, tag, logStr);
            }
#endif

            sock.leftReadBytes = 0;
            [self handleParseMessage:sock data:contentData];
            if (unhandledData.length > contentData.length) {
                unhandledData = [unhandledData subdataWithRange:NSMakeRange(contentData.length, unhandledData.length - contentData.length)];
                bdle_log_info(self, @"[BDLE][Socket] trigger recursion parse, leftToReadLength: %ld", unhandledData.length);
                [self handlePacketSticking:sock data:unhandledData tag:tag];
            }
        } else {
            // 本次数据不足以填充这次消息，先把数据存起来
            if (self.unhandleData) {
                NSMutableData *currUnhandled = [self.unhandleData mutableCopy];
                [currUnhandled appendData:unhandledData];
                self.unhandleData = currUnhandled;
            } else {
                self.unhandleData = unhandledData;
            }
            bdle_log_info(self, @"[BDLE][Socket] data split, needRead: %u, currHave: %ld", sock.leftReadBytes, self.unhandleData.length);
        }
    }
    bdle_log_info(self, @"[BDLE][Socket] handlePacketSticking all done, unhandledData.length=%ld", unhandledData.length);
}

// 消费消息
- (void)handleParseMessage:(GCDAsyncSocket *)sock data:(NSData *)contentData {
    if (!contentData) {
        return;
    }

    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:contentData options:kNilOptions error:&error];
    if (!error) {
        id content = jsonDict[@"content"];
        NSDictionary *trueContent;
        if (!content) {
            return;
        }
        if (![content isKindOfClass:[NSDictionary class]]) {
            return;
        }

        trueContent = content;
        if (trueContent) {
            BDLEPPBaseCmd *respCmd = [BDLEPPBaseCmd modelWithJSON:trueContent];
            if ([respCmd.body.cmd isEqualToString:kBDLEPPCmdKey_PushMediaInfo] ||
                [respCmd.body.cmd isEqualToString:kBDLEPPCmdKey_PushStatusInfo] ||
                [respCmd.body.cmd isEqualToString:kBDLEPPCmdKey_PushRuntimeInfo]) {
                // 推送消息
                [self handleRequestMessage:sock cmd:respCmd jsonDict:trueContent];
            } else {
                [self handleResponseMessage:sock cmd:respCmd jsonDict:trueContent];
            }
        }
    }

    // 对于短连请求，连接和请求应该是1v1的关系，不应该存在两个请求共用一个连接的情况
    // 如果sock是短连通路，那么在消费完首个下行消息之后就可以回收了
    if (sock.connectionType == BDLESocketConnectionTypeShort) {
        bdle_log_info(self, @"[BDLE][Socket] socket:%@(%@) disconnect, ip=%@:%ld", sock, sock.socketId, sock.remoteIpAddress, (long)sock.remotePort);
        [sock disconnect];
        [self.shortConnectionPoolLock lock];
        [self.shortConnectionPool removeObject:sock];
        [self.shortConnectionPoolLock unlock];
    }
}

// 推送消息（由接收端主动发起）
- (void)handleRequestMessage:(GCDAsyncSocket *)sock cmd:(BDLEPPBaseCmd *)cmd jsonDict:(NSDictionary *)jsonDict {
    if (BDLE_isEmptyString(cmd.body.cmd)) {
        return;
    }

    // 回复response包给接收端
    Class respClass = [BDLEPPBaseCmd responseClassMap][cmd.body.cmd];
    if ([respClass isSubclassOfClass:[BDLEPPBaseCmdResponse class]]) {
        BDLEPPBaseCmdResponse *resp = [BDLEPPBaseCmdResponse new];
        resp.code = 0;
        resp.msg = @"";
        resp.version = 1;
        resp.messageId = cmd.messageId;
        resp.connectId = cmd.connectId;
        BDLEPPCmd *respBody = [BDLEPPCmd new];
        respBody.cmd = cmd.body.cmd;
        resp.body = respBody;
        [self sendMessageRequest:resp type:BDLESocketRequestTypeLongConnection ipAddress:self.ipAddress port:self.port completion:nil];
    }

    Class metaClass = [BDLEPPBaseCmd requestClassMap][cmd.body.cmd];
    if ([metaClass isSubclassOfClass:[BDLEPPBaseCmd class]] && [metaClass respondsToSelector:@selector(modelWithJSON:)]) {
        BDLEPPBaseCmd *cvtCmd = [metaClass performSelector:@selector(modelWithJSON:) withObject:jsonDict];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(messageBus:didReceiveSinkRequest:)]) {
                [self.delegate messageBus:self didReceiveSinkRequest:cvtCmd];
            }
        });
    }
}

// 请求结果消息（对于发送端请求的回复）
- (void)handleResponseMessage:(GCDAsyncSocket *)sock cmd:(BDLEPPBaseCmd *)cmd jsonDict:(NSDictionary *)jsonDict {
    NSString *messageId = cmd.messageId;
    if (BDLE_isEmptyString(messageId)) {
        return;
    }
    BDLESocketRequest *targetReq = nil;
    [self.requestQueueLock lock];
    for (BDLESocketRequest *request in self.requestQueue) {
        // 遍历requestQueue，通过messageId，找到对应的那个request
        if ([request.messageId isEqualToString:messageId] && request.socket == sock) {
            targetReq = request;
            break;
        }
    }
    NSInteger elapsed = -1;
    if (targetReq) {
        // 找到请求，则触发请求的callback
        targetReq.ackTs = CFAbsoluteTimeGetCurrent();
        elapsed = (NSInteger)((targetReq.ackTs - targetReq.sendTs) * 1000);
        bdle_log_info(self, @"[BDLE][Socket] track message: %@(%@) elapsed=%ldms", targetReq.messageId, targetReq.message.body.cmd, (long)elapsed);
        if (targetReq.completion) {
            targetReq.completion(jsonDict, nil);
        }

        // 执行完ack之后，从请求队列里移除这个请求
        [self.requestQueue removeObject:targetReq];
    }
    [self.requestQueueLock unlock];
}

#if BDLE_ENABLE_SOCKET_LOG
- (NSString *)getRegexPartFrom:(NSString *)source keyword:(NSString *)keyword {
    if (BDLE_isEmptyString(source) || BDLE_isEmptyString(keyword)) {
        return nil;
    }
    NSString *ret = @"";
    NSString *searchKey1 = [NSString stringWithFormat:@"\"%@\":\"([^\"]*)\"", keyword];
    NSString *searchKey2 = [NSString stringWithFormat:@"\"%@\":([^\"]*)", keyword];
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:searchKey1 options:0 error:nil];
    NSTextCheckingResult *match = [regex1 firstMatchInString:source options:0 range:NSMakeRange(0, source.length)];
    if (!match) {
        NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:searchKey2 options:0 error:nil];
        match = [regex2 firstMatchInString:source options:0 range:NSMakeRange(0, source.length)];
    }
    if (match) {
        NSRange matchRange = [match rangeAtIndex:1];
        ret = [source substringWithRange:matchRange];
    }
    return ret;
}
#endif

- (NSString *)requestQueueCmds {
    if (self.requestQueue.count == 0) {
        return @"";
    }
    NSInteger enumCnt = MIN(self.requestQueue.count, 50);
    NSMutableString *cmds = [@"" mutableCopy];
    for (int i = 0; i < enumCnt; i++) {
        BDLESocketRequest *req = self.requestQueue[i];
        [cmds appendFormat:@"%@", req.message.body.cmd];
        [cmds appendString:(i < enumCnt - 1 ? @"," : @"")];
    }
    return [cmds copy];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self.requestCacheLock lock];
    bdle_log_info(self, @"[BDLE][Socket] callback: didConnectToHost, socket=%@(%@), ip=%@:%ld, cacheQueueCnt=%ld", sock, sock.socketId, host, (long)port, (long)self.requestCacheQueue.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sock.connectionType == BDLESocketConnectionTypeLong && [self.delegate respondsToSelector:@selector(messageBus:didConnected:)]) {
            // 只有长连需要通知上层
            [self.delegate messageBus:self didConnected:nil];
        }
    });
    [sock readDataWithTimeout:-1 tag:_socketReadTag++];
    bdle_log_info(self, @"[BDLE][Socket] invoke readData(didConnect), tag=%ld", (long)_socketReadTag);
    // 遍历短连请求缓存，看是否有请求需要通过当前socket发送
    NSMutableArray *targetToRemove = [NSMutableArray array];
    for (BDLESocketRequest *req in self.requestCacheQueue) {
        if (req.socket == sock) {
            bdle_log_info(self, @"[BDLE][Socket] fire req in cacheQueue, msgId=%@", req.messageId);
            [self doSendSocketMessageInternal:req.socket message:req.message completion:req.completion];
            [targetToRemove addObject:req];
        }
    }
    for (BDLESocketRequest *req in targetToRemove) {
        [self.requestCacheQueue removeObject:req];
    }
    bdle_log_info(self, @"[BDLE][Socket] remove fired req, cacheQueueCnt=%ld", (long)self.requestCacheQueue.count);
    [self.requestCacheLock unlock];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    bdle_log_info(self, @"[BDLE][Socket] callback: didDisconnect, socket=%@(%@), errCode=%ld, errMsg=%@", sock, sock.socketId, err.code, err.localizedDescription);
    if (sock.connectionType == BDLESocketConnectionTypeShort) {
        [self.shortConnectionPoolLock lock];
        [self.shortConnectionPool removeObject:sock];
        [self.shortConnectionPoolLock unlock];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sock.connectionType == BDLESocketConnectionTypeLong && [self.delegate respondsToSelector:@selector(messageBus:didDisconnected:)]) {
            // 只有长连需要通知上层
            NSError *error = [NSError errorWithDomain:@"bdle.error" code:err.code userInfo:@{NSLocalizedDescriptionKey: err.localizedDescription ?: @""}];
            [self.delegate messageBus:self didDisconnected:error];
        } else if (sock.connectionType == BDLESocketConnectionTypeShort && err != nil) {
            // 短连出现异常断开连接
            // 检查短连请求缓存，看是否有请求需要通过当前socket发送，需要走当前socket发送的短连没有机会再发送，需要移除并返回失败
            NSMutableArray *targetToRemove = [NSMutableArray array];
            for (BDLESocketRequest *req in self.requestCacheQueue) {
                if (req.socket == sock) {
                    bdle_log_info(self, @"[BDLE][Socket] kill req in cacheQueue, msgId=%@", req.messageId);
                    [targetToRemove addObject:req];
                }
            }
            for (BDLESocketRequest *req in targetToRemove) {
                if (req.completion) {
                    NSError *error = [NSError errorWithDomain:@"bdle.error" code:err.code userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"short connection disconnect, cmd=%@, err=%@", req.message.body.cmd, err.localizedDescription]}];
                    req.completion(nil, error);
                }
                [self.requestCacheQueue removeObject:req];
            }
        }
    });
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    bdle_log_info(self, @"[BDLE][Socket] callback: didWriteData, socket=%@(%@), tag=%ld", sock, sock.socketId, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.readDataLock lock];
    bdle_log_info(self, @"[BDLE][Socket] callback: didReadData(start), socket=%@(%@), tag=%ld, dataLength=%ld", sock, sock.socketId, tag, data.length);
    if (self.unhandleData) {
        NSMutableData *unhandled = [self.unhandleData mutableCopy];
        [unhandled appendData:data];
        self.unhandleData = nil;
        [self handlePacketSticking:sock data:unhandled tag:tag];
    } else {
        [self handlePacketSticking:sock data:data tag:tag];
    }
    [sock readDataWithTimeout:-1 tag:_socketReadTag++];
    bdle_log_info(self, @"[BDLE][Socket] invoke readData(didReadData), tag=%ld", (long)_socketReadTag);
    [self.readDataLock unlock];
}

@end

