//
//  BDLEConnection.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEConnection.h"
#import "BDLEService.h"
#import "BDLEUtils.h"
#import "BDCLUPnPServer.h"

static const int32_t kBDLESocketMessageSendTimeoutInS = 5;

@interface BDLEConnection() <BDLEMessageBusDelegate, BDLEMessageBusEventDataSource>

@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, strong) NSMutableDictionary *requestMap;
@property (nonatomic, strong) NSLock *requestMapLock;
@property (nonatomic, strong) BDCLUPnPServer *upnpServer;

@end

@implementation BDLEConnection

- (instancetype)initWithBDLEService:(BDLEService *)bdleService delegate:(NSObject<BDLEConnectionDelegate> *)delegate {
    if (self = [super init]) {
        _isConnecting = NO;
        _isConnected = NO;
        _delegate = delegate;
        _bdleService = bdleService;
        _bdleService.messageBus.delegate = self;
        _bdleService.messageBus.eventDataSource = self;
        _requestMap = [[NSMutableDictionary alloc] init];
        _requestMapLock = [[NSLock alloc] init];
        if (bdleService.upnpServer) {
            _upnpServer = bdleService.upnpServer;
        } else {
            _upnpServer = [[BDCLUPnPServer alloc] init];
        }
    }
    return self;
}

- (void)dealloc {
    [_requestMap removeAllObjects];
}

- (void)connectWithNetworkCheck:(BOOL)needCheckNetwork
                       maxCount:(NSInteger)maxCount
                        timeout:(NSTimeInterval)timeout
                  retryInterval:(NSTimeInterval)retryInterval {
    bdle_log_info(self, @"[BDLE][Connection] %p connectWithNetworkCheck invoked, needCheck: %d, maxCount:%ld, timeout:%ld, interval:%ld", &self, needCheckNetwork, (long)maxCount, (long)timeout, (long)retryInterval);
    if (!needCheckNetwork) {
        [self connect];
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        NSString *ipAddress = self.bdleService.ipAddress;
        int bdlePort = self.bdleService.bdleSocketPort;
        if (BDLE_isEmptyString(ipAddress) || bdlePort == 0) {
            bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck failed, reason: ipAddress(%@) or socketPort(%d) invalid", ipAddress, bdlePort);
            return;
        }
        if (self.isConnecting || self.isConnected) {
            bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck faield, reason: %@", (self.isConnecting ? @"is connecting" : @"has connected"));
            return;
        }
        self.isConnecting = YES;
        self.isConnected = NO;
        [self.upnpServer checkServiceAlive:self.bdleService.upnpDevice maxCount:maxCount timeout:timeout retryInterval:retryInterval urlSession:[NSURLSession sharedSession] completion:^(BOOL isSuccess, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!isSuccess) {
                    bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck checkServiceAlive failed, error:%ld-%@", (long)error.code, error.localizedDescription);
                    self.isConnecting = NO;
                    self.isConnected = NO;
                    if ([self.delegate respondsToSelector:@selector(bdleConnection:onError:)]) {
                        [self.delegate bdleConnection:self onError:error];
                    }
                } else {
                    bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck checkServiceAlive success");
                    dispatch_block_t successActionBlock = ^{
                        __strong typeof(weakSelf) self = weakSelf;
                        self.isConnecting = NO;
                        self.isConnected = YES;
                        NSError *error = nil;
                        if (![self.bdleService.messageBus connect:ipAddress port:bdlePort error:&error]) {
                            bdle_log_info(self, @"[BDLE][Connection] %p connect error: %@", &self, error);
                            if (error) {
                                if ([self.delegate respondsToSelector:@selector(bdleConnection:onError:)]) {
                                    [self.delegate bdleConnection:self onError:error];
                                }
                            }
                        }
                    };
                    bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck checkServiceAlive success then try GetDeviceInfo");
                    [self.bdleService sendGetDeviceInfo:^(NSError * _Nullable error) {
                        if (error) {
                            bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck checkServiceAlive try GetDeviceInfo failed, error:%ld-%@", (long)error.code, error.localizedDescription);
                            if ([self.delegate respondsToSelector:@selector(bdleConnection:onError:)]) {
                                [self.delegate bdleConnection:self onError:error];
                            }
                        } else {
                            bdle_log_info(self, @"[BDLE][Connection] connectWithNetworkCheck checkServiceAlive try GetDeviceInfo success");
                            successActionBlock();
                        }
                    }];
                }
            });
        }];
    });
}

- (void)connect {
    bdle_log_info(self, @"[BDLE][Connection] %p connect invoked", &self);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ipAddress = self.bdleService.ipAddress;
        int bdlePort = self.bdleService.bdleSocketPort;
        if (BDLE_isEmptyString(ipAddress) || bdlePort == 0) {
            bdle_log_info(self, @"[BDLE][Connection] connect failed, reason: ipAddress(%@) or socketPort(%d) invalid", ipAddress, bdlePort);
            return;
        }
        if (self.isConnecting || self.isConnected) {
            bdle_log_info(self, @"[BDLE][Connection] connect faield, reason: %@", (self.isConnecting ? @"is connecting" : @"has connected"));
            return;
        }
        self.isConnecting = YES;
        self.isConnected = NO;
        NSError *error = nil;
        if (![self.bdleService.messageBus connect:ipAddress port:bdlePort error:&error]) {
            bdle_log_info(self, @"[BDLE][Connection] %p connect error: %@", &self, error);
            if (error) {
                if ([self.delegate respondsToSelector:@selector(bdleConnection:onError:)]) {
                    [self.delegate bdleConnection:self onError:error];
                }
            }
        }
    });
}

- (void)disconnect {
    bdle_log_info(self, @"[BDLE][Connection] %p disconnect invoked", &self);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isConnected) {
            [self.bdleService.messageBus disconnect];
        }
        self.isConnecting = NO;
        self.isConnected = NO;
    });
}

#pragma mark - BDLEMessageBusDelegate
- (void)messageBus:(BDLEMessageBus *)bus didConnected:(NSError *)error {
    bdle_log_info(self, @"[BDLE][Connection] %p socket callback didConnected, bus: %p", &self, &bus);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isConnecting = NO;
        self.isConnected = YES;
        if ([self.delegate respondsToSelector:@selector(bdleConnection:didConnectToService:)]) {
            [self.delegate bdleConnection:self didConnectToService:self.bdleService];
        }
    });
}

- (void)messageBus:(BDLEMessageBus *)bus didDisconnected:(NSError *)error {
    bdle_log_info(self, @"[BDLE][Connection] %p socket callback didDisconnected, bus: %p", &self, &bus);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isConnecting = NO;
        self.isConnected = NO;
        if ([self.delegate respondsToSelector:@selector(bdleConnection:didDisonnectToService:)]) {
            [self.delegate bdleConnection:self didDisonnectToService:self.bdleService];
        }
    });
}

- (void)messageBus:(BDLEMessageBus *)bus didReceiveSinkRequest:(BDLEPPBaseCmd *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.notifyDelegate respondsToSelector:@selector(bdleConnection:didReceiveSinkRequest:)]) {
            [self.notifyDelegate bdleConnection:self didReceiveSinkRequest:request];
        }
    });
}

#pragma mark - BDLEMessageBusEventDataSource
- (NSDictionary *)messageBus:(BDLEMessageBus *)bus eventExtraDictionary:(NSString *)eventName {
    return self.bdleService.eventExtraDictionary;
}

#pragma mark - BDLEPPSessionProtocol
- (void)sendRequest:(BDLEPPBaseCmd *)request completionHandler:(void (^)(BDLEPPBaseCmdResponse * _Nullable, NSError * _Nullable))completionHandler {
    [self sendRequest:request retryCount:3 completionHandler:completionHandler];
}

- (void)sendRequest:(BDLEPPBaseCmd *)request retryCount:(NSInteger)retryCount completionHandler:(void (^)(BDLEPPBaseCmdResponse * _Nullable, NSError * _Nullable))completionHandler {
    [self.requestMapLock lock];
    self.requestMap[request.messageId ?: @""] = request;
    [self.requestMapLock unlock];
    __weak typeof(self) weakSelf = self;
    [self.bdleService.messageBus sendMessageRequest:request
                                               type:BDLESocketRequestTypeLongConnection
                                          ipAddress:self.bdleService.ipAddress
                                               port:self.bdleService.bdleSocketPort
                                         completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.requestMapLock lock];
        self.requestMap[request.messageId ?: @""] = nil;
        [self.requestMapLock unlock];
        if (completionHandler) {
            BDLEPPBaseCmdResponse *respCmd = nil;
            NSString *cmd = response[@"body"][@"cmd"];
            if (!BDLE_isEmptyString(cmd)) {
                Class metaClass = [BDLEPPBaseCmd responseClassMap][cmd];
                if ([metaClass isSubclassOfClass:[BDLEPPBaseCmd class]] && [metaClass respondsToSelector:@selector(modelWithJSON:)]) {
                    respCmd = [metaClass performSelector:@selector(modelWithJSON:) withObject:response];
                }
            }
            completionHandler(respCmd, error);
        }
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kBDLESocketMessageSendTimeoutInS * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        BDLEPPBaseCmd *cachedReq = nil;
        [self.requestMapLock lock];
        cachedReq = self.requestMap[request.messageId ?: @""];
        self.requestMap[request.messageId ?: @""] = nil;
        [self.requestMapLock unlock];
        if (cachedReq) {
            // 5s后这个请求还没有被移除，证明它的resp一直没有被触发，视为超时
            if (retryCount > 0) {
                bdle_log_info(self, @"[BDLE][Connection] sendRequest retry, cmd=%@, currCnt=%ld", request.body.cmd, retryCount);
                [self sendRequest:request retryCount:(retryCount - 1) completionHandler:completionHandler];
            } else {
                // 重试次数耗尽
                bdle_log_info(self, @"[BDLE][Connection] sendRequest retry times reach limit, cmd=%@", request.body.cmd);
                if (completionHandler) {
                    NSError *error = [NSError errorWithDomain:@"bdle.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"retry times reach limit"}];
                    completionHandler(nil, error);
                }
            }
        }

    });
}

@end
