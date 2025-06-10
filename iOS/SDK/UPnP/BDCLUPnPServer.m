//
//  BDCLUPnPServer.m
//  DLNA_UPnP
//
//  Created by ClaudeLi on 2017/7/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "BDCLUPnP.h"
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "GDataXMLNode.h"
#import "BDCLUPnPDevice.h"
#import "BDLEUtils.h"
#import "NSObject+BDLEContext.h"

static NSString * const kBDCLUPnPRequestContextTag = @"bdle_request";

@interface BDCLUPnPServer () <GCDAsyncUdpSocketDelegate>

/// 用于发送M-SEARCH组播消息，以及接收端单播响应消息
@property (nonatomic, strong) GCDAsyncUdpSocket *unicastUdpSocket;
/// 用于监听SSDP组播消息
@property (nonatomic, strong) GCDAsyncUdpSocket *multicastUdpSocket;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) dispatch_queue_t serviceAliveCheckQueue;

// key: usn(uuid) string,  value: device
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDCLUPnPDevice *> *deviceDictionary;

@property (nonatomic, assign) BOOL unicastUdpSocketInited;
@property (nonatomic, assign) BOOL udpSocketInited;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSUInteger cycleIndex;

@property (nonatomic, assign) NSInteger cacheDeviceCount;

@end

@implementation BDCLUPnPServer

@synthesize delegate = _delegate;

- (void)dealloc {
    [self.timer invalidate];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _deviceDictionary = [NSMutableDictionary dictionary];
        _unicastUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _multicastUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _operationQueue = [NSOperationQueue new];
        // 在一些较老机型上，如果不对并行数进行限制，会导致系统创建过多线程并卡死，导致任务得不到执行
        _operationQueue.maxConcurrentOperationCount = 32;
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 15.0f;
        sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        _urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
        _serviceAliveCheckQueue = dispatch_queue_create("bdle_service_check_queue", DISPATCH_QUEUE_CONCURRENT);
        _cacheDeviceCount = 10;
    }
    return self;
}


- (void)start {
    NSError *unicastError = nil;
    if (self.unicastUdpSocketInited == NO) {
        // Unicast，使用随机端口号
        [self.unicastUdpSocket bindToPort:0 error:&unicastError];
        if (!unicastError) {
            [self.unicastUdpSocket beginReceiving:&unicastError];
        }
        if (!unicastError) {
            self.unicastUdpSocketInited = YES;
        }
    }
    if (unicastError) {
        [self onError:unicastError];
    }

    NSError *multicastError = nil;
    if (self.udpSocketInited == NO) {
        // Multicast
        [self.multicastUdpSocket enableReusePort:YES error:&multicastError];
        [self.multicastUdpSocket bindToPort:ssdpPort error:&multicastError];

        if (!multicastError) {
            [self.multicastUdpSocket beginReceiving:&multicastError];
        }

        if (!multicastError) {
            [self.multicastUdpSocket joinMulticastGroup:ssdpAddress onInterface:[BDLEUtils getLocalWlanIp] error:&multicastError];
        }

        if (!multicastError) {
            self.udpSocketInited = YES;
        }
    }
    if (multicastError) {
        [self onError:multicastError];
    }

    [self search];
}

- (void)stop {
    [_unicastUdpSocket close];
    [_multicastUdpSocket close];
    self.unicastUdpSocketInited = NO;
    self.udpSocketInited = NO;
    [self.urlSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDataTask *t in dataTasks) {
            if ([t.bdleContextId isEqualToString:kBDCLUPnPRequestContextTag]) {
                [t cancel];
            }
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timer invalidate];
        [self.deviceDictionary removeAllObjects];
        [self onChange];
    });
}

- (void)search {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.deviceDictionary removeAllObjects];
        BOOL shouldStartTimer = self.unicastUdpSocketInited || self.udpSocketInited;
        if (shouldStartTimer) {
            self.cycleIndex = 0;
            [self sendUdpSearchPacket];
            if (self.timer) {
                [self.timer invalidate];
                self.timer = nil;
            }
            self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:[BDLEWeakProxy proxyWithTarget:self] selector:@selector(sendUdpSearchPacket) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    });
}


- (NSString *)getSearchStringWithSTString:(NSString *)stString {
    return [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nHOST: %@:%d\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: %@\r\nUSER-AGENT: iOS UPnP/1.1 mccree/1.0\r\n\r\n", ssdpAddress, ssdpPort, stString];
}

- (void)sendUdpSearchPacket {
    GCDAsyncUdpSocket *udpSocket = self.unicastUdpSocketInited ? self.unicastUdpSocket : self.multicastUdpSocket;
    NSData *sendAVTransportData = [[self getSearchStringWithSTString:serviceType_AVTransport] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sendRootDeviceData = [[self getSearchStringWithSTString:serviceType_RootDevice] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sendMediaRenderData = [[self getSearchStringWithSTString:serviceType_MediaRender] dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:sendAVTransportData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:1];
    [udpSocket sendData:sendRootDeviceData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:1];
    [udpSocket sendData:sendMediaRenderData toHost:ssdpAddress port:ssdpPort withTimeout:-1 tag:1];
    self.cycleIndex++;
    if (self.cycleIndex > 60) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)checkServiceAlive:(BDCLUPnPDevice *)upnpDevice {
    __weak typeof(self) weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self checkServiceAlive:upnpDevice count:1 maxCount:3 timeout:0 retryInterval:1.0 shouldOfflineDevice:YES urlSession:nil completion:nil];
    }];
}

- (void)checkServiceAlive:(BDCLUPnPDevice *)upnpDevice
                 maxCount:(NSInteger)maxCount
                  timeout:(NSTimeInterval)timeout
            retryInterval:(NSTimeInterval)retryInterval
               urlSession:(NSURLSession *)aUrlSession
               completion:(void (^)(BOOL isSuccess, NSError *error))completion {
    __weak typeof(self) weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self checkServiceAlive:upnpDevice count:1 maxCount:maxCount timeout:timeout retryInterval:retryInterval shouldOfflineDevice:NO urlSession:aUrlSession completion:completion];
    }];
}

- (void)checkServiceAlive:(BDCLUPnPDevice *)upnpDevice
                    count:(NSInteger)count
                 maxCount:(NSInteger)maxCount
                  timeout:(NSTimeInterval)timeout
            retryInterval:(NSTimeInterval)retryInterval
      shouldOfflineDevice:(BOOL)shouldOfflineDevice
               urlSession:(NSURLSession *)aUrlSession
               completion:(void (^)(BOOL isSuccess, NSError *error))completion {
    __weak typeof(self) weakSelf = self;
    [self checkDevice:upnpDevice timeout:timeout urlSession:aUrlSession completion:^(BOOL isSuccess, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            if (completion) {
                completion(isSuccess, error);
            }
            return;
        }
        if (isSuccess) {
            upnpDevice.checkCounter = 0;
            if (completion) {
                completion(isSuccess, error);
            }
        } else {
            if (count >= maxCount) {
                if (shouldOfflineDevice) {
                    [self handleDeviceOffline:upnpDevice];
                }
                if (completion) {
                    completion(NO, error);
                }
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryInterval * NSEC_PER_SEC)), self.serviceAliveCheckQueue, ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if (shouldOfflineDevice && upnpDevice.checkCounter > -1) {
                        // found by other threads during the check proces, ignore
                        return;
                    }
                    [self checkServiceAlive:upnpDevice count:(count + 1) maxCount:maxCount timeout:timeout retryInterval:retryInterval shouldOfflineDevice:shouldOfflineDevice urlSession:aUrlSession completion:completion];
                });
            }
        }
    }];
}

- (void)checkDevice:(BDCLUPnPDevice *)upnpDevice
            timeout:(NSTimeInterval)timeout
         urlSession:(NSURLSession *)aUrlSession
         completion:(void (^)(BOOL isSuccess, NSError *error))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:upnpDevice.location cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0f];
    request.HTTPMethod = @"GET";
    if (timeout > 0) {
        request.timeoutInterval = timeout;
    }
    NSURLSession *session = (aUrlSession ?: self.urlSession);
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        BOOL isSuccess = NO;
        if (response != nil && data != nil) {
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            isSuccess = ([resp statusCode] == 200);
        }
        if (completion) {
            completion(isSuccess, error);
        }
    }];
    task.bdleContextId = kBDCLUPnPRequestContextTag;
    [task resume];
}

- (void)handleDeviceOffline:(BDCLUPnPDevice *)device {
    if (device.checkCounter > -1) {
        // not in check list, ignore
        return;
    }
    [self removeDeviceWithKey:device.deviceKey];
    device.checkCounter = 0;
}

#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    [self onError:error];
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(nullable id)filterContext {
    [self judgeDeviceWithData:data];
}

- (void)judgeDeviceWithData:(NSData *)data {
    @autoreleasepool {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([string hasPrefix:@"NOTIFY"]) {
            NSString *serviceType = [self headerValueForKey:@"NT:" inData:string];
            if (![serviceType isEqualToString:serviceType_AVTransport] &&
                ![serviceType isEqualToString:serviceType_MediaRender] &&
                ![serviceType isEqualToString:serviceType_RootDevice]) {
                return;
            }
            NSString *location = [self headerValueForKey:@"Location:" inData:string];
            NSString *usn = [self headerValueForKey:@"USN:" inData:string];
            NSString *ssdp = [self headerValueForKey:@"NTS:" inData:string];
            if ([self isNilString:ssdp] || [self isNilString:usn] || [self isNilString:location]) {
                return;
            }
            NSString *ipAddress = [BDLEUtils getIpAddressFromUrl:location];
            NSInteger port = [BDLEUtils getPortFromUrl:location];
            NSString *deviceKey = [NSString stringWithFormat:@"%@:%ld", ipAddress, (long)port];
            NSString *bdlePort = [self headerValueForKey:@"BDLEPORT:" inData:string];
            if ([ssdp isEqualToString:@"ssdp:alive"]) {
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    BDCLUPnPDevice *upnpDevice = [self.deviceDictionary objectForKey:deviceKey];
                    if (!upnpDevice) {
                        [self.operationQueue addOperationWithBlock:^{
                            __strong typeof(weakSelf) self = weakSelf;
                            [self getDeviceWithLocation:location withUSN:usn completion:^(BDCLUPnPDevice * _Nullable device, NSError * _Nullable error) {
                                __strong typeof(weakSelf) self = weakSelf;
                                if (device && [device supportBDLEProtocol]) {
                                    if (device.bdleSocketPort == 0 && [bdlePort isKindOfClass:[NSString class]] && bdlePort.length > 0) {
                                        device.bdleSocketPort = [bdlePort intValue];
                                    }
                                    [self addDevice:device];
                                }
                            }];
                        }];
                    }
                });
            } else if ([ssdp isEqualToString:@"ssdp:byebye"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self removeDeviceWithKey:deviceKey];
                });
            }
        } else if ([string hasPrefix:@"HTTP/1.1"]) {
            NSString *location = [self headerValueForKey:@"Location:" inData:string];
            NSString *usn = [self headerValueForKey:@"USN:" inData:string];
            if ([self isNilString:usn] || [self isNilString:location]) {
                return;
            }
            NSString *ipAddress = [BDLEUtils getIpAddressFromUrl:location];
            NSInteger port = [BDLEUtils getPortFromUrl:location];
            NSString *deviceKey = [NSString stringWithFormat:@"%@:%ld", ipAddress, (long)port];
            NSString *bdlePort = [self headerValueForKey:@"BDLEPORT:" inData:string];
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                BDCLUPnPDevice *upnpDevice = [self.deviceDictionary objectForKey:deviceKey];
                if (!upnpDevice) {
                    [self.operationQueue addOperationWithBlock:^{
                        __strong typeof(weakSelf) self = weakSelf;
                        [self getDeviceWithLocation:location withUSN:usn completion:^(BDCLUPnPDevice * _Nullable device, NSError * _Nullable error) {
                            __strong typeof(weakSelf) self = weakSelf;
                            if (device && [device supportBDLEProtocol]) {
                                if (device.bdleSocketPort == 0 && [bdlePort isKindOfClass:[NSString class]] && bdlePort.length > 0) {
                                    device.bdleSocketPort = [bdlePort intValue];
                                }
                                [self addDevice:device];
                            }
                        }];
                    }];
                }
            });
        }
    }
}

- (void)addDevice:(BDCLUPnPDevice *)device {
    if (!device) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *key = device.deviceKey;
        BDCLUPnPDevice *aDevice = [self.deviceDictionary objectForKey:key];
        if (aDevice) {
            aDevice.checkCounter = 0;
        } else {
            device.checkCounter = 0;
            [self.deviceDictionary setObject:device forKey:key];
            [self onChange];
        }
    });
}

- (void)removeDeviceWithKey:(NSString *)deviceKey {
    if (!deviceKey || ![deviceKey isKindOfClass:[NSString class]] || deviceKey.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        BDCLUPnPDevice *aDevice = [self.deviceDictionary objectForKey:deviceKey];
        if (aDevice) {
            [self.deviceDictionary removeObjectForKey:deviceKey];
            [self onChange];
            if ([self.delegate respondsToSelector:@selector(upnpDeviceUnavailable:)]) {
                [self.delegate upnpDeviceUnavailable:aDevice];
            }
        }
    });
}

- (void)onChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.deviceDictionary.count > 0 && [self.delegate respondsToSelector:@selector(upnpSearchChangeWithResults:)]) {
            [self.delegate upnpSearchChangeWithResults:self.deviceDictionary.allValues];
        }
    });
}

- (void)onError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(upnpSearchErrorWithError:)]) {
            [self.delegate upnpSearchErrorWithError:error];
        }
    });
}

#pragma mark - Private Method
- (NSString *)headerValueForKey:(NSString *)key inData:(NSString *)data {
    NSString *str = [NSString stringWithFormat:@"%@", data];
    
    NSRange keyRange = [str rangeOfString:key options:NSCaseInsensitiveSearch];
    
    if (keyRange.location == NSNotFound) {
        return @"";
    }
    
    str = [str substringFromIndex:keyRange.location + keyRange.length];
    
    NSRange enterRange = [str rangeOfString:@"\r\n"];
    if (enterRange.location != NSNotFound) {
        str = [str substringToIndex:enterRange.location];
    }
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)getDeviceWithLocation:(NSString *)location withUSN:(NSString *)usn completion:(void (^)(BDCLUPnPDevice * _Nullable device, NSError * _Nullable error))completion {
    NSURL *URL = [NSURL URLWithString:location];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0];
    request.HTTPMethod = @"GET";
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        BOOL isSuccess = NO;
        NSString *serverStr = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse.allHeaderFields[@"SERVER"] isKindOfClass:[NSString class]] && [httpResponse.allHeaderFields[@"SERVER"] length] > 0) {
                serverStr = httpResponse.allHeaderFields[@"SERVER"];
            } else if ([httpResponse.allHeaderFields[@"Server"] isKindOfClass:[NSString class]] && [httpResponse.allHeaderFields[@"Server"] length] > 0) {
                serverStr = httpResponse.allHeaderFields[@"Server"];
            } else {
                serverStr = httpResponse.allHeaderFields[@"server"];
            }
        }

        BDCLUPnPDevice *device = nil;
        if (error) {
            [self onError:error];
        } else {
            if (response != nil && data != nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200) {
                    device = [[BDCLUPnPDevice alloc] init];
                    device.location = URL;
                    device.uuid = usn;
                    device.httpHeaderServer = serverStr;
                    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
                    GDataXMLElement *xmlEle = [xmlDoc rootElement];
                    NSArray *xmlArray = [xmlEle children];
                    BOOL hasDeviceNode = NO;
                    for (int i = 0; i < [xmlArray count]; i++) {
                        GDataXMLElement *element = [xmlArray objectAtIndex:i];
                        if ([[element name] isEqualToString:@"device"]) {
                            [device setArray:[element children] withRootElement:xmlEle];
                            hasDeviceNode = YES;
                            continue;
                        }
                    }
                    if (!hasDeviceNode) {
                        device = nil;
                    } else {
                        isSuccess = YES;
                    }
                }
            }
        }
        if (completion) {
            completion(device, error);
        }
    }];
    task.bdleContextId = kBDCLUPnPRequestContextTag;
    [task resume];
}


- (BOOL)isNilString:(NSString *)_str {
    if (!_str || ![_str isKindOfClass:[NSString class]]) {
        return YES;
    }
    _str = [NSString stringWithFormat:@"%@", _str];
    if (!_str.length) {
        return YES;
    }
    if ([_str isEqualToString:@"null"] ||
        [_str isEqualToString:@"(null)"] ||
        [_str isEqualToString:@"<null>"]) {
        return YES;
    }
    return NO;
}

@end
