//
//  BDLEBrowser.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEBrowser.h"
#import "BDLEUtils.h"

#import "BDCLUPnPServer.h"
#import "BDCLUPnPDevice.h"
#import "BDLEService.h"

@interface BDLEBrowser() <BDCLUPnPServerDelegate>

@property (nonatomic, strong) BDCLUPnPServer *upnpServer;
@property (nonatomic, strong) NSMutableSet<BDLEService *> *pendingBDLEServiceSet;
@property (nonatomic, strong) NSMutableArray<BDLEService *> *discoveredBDLEServiceArray;
@property (nonatomic, strong) NSTimer *offlineDeviceCheckTimer;

@end

@implementation BDLEBrowser

- (instancetype)init {
    self = [super init];
    if (self) {
        _upnpServer = [[BDCLUPnPServer alloc] init];
        _upnpServer.delegate = self;
        _pendingBDLEServiceSet = [NSMutableSet set];
        _discoveredBDLEServiceArray = [NSMutableArray array];
    }
    return self;
}

- (void)searchServices {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pendingBDLEServiceSet removeAllObjects];
        [self.discoveredBDLEServiceArray removeAllObjects];
    });
    [_upnpServer start];
    [self startOfflineDeviceCheck];
}

- (void)stopSearch {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pendingBDLEServiceSet removeAllObjects];
        [self.discoveredBDLEServiceArray removeAllObjects];
    });
    [self stopOfflineDeviceCheck];
    [_upnpServer stop];
}

- (void)startOfflineDeviceCheck {
    [self stopOfflineDeviceCheck];
    self.offlineDeviceCheckTimer = [NSTimer timerWithTimeInterval:10.0f target:[BDLEWeakProxy proxyWithTarget:self] selector:@selector(checkOfflineDevice) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.offlineDeviceCheckTimer forMode:NSRunLoopCommonModes];
}

- (void)stopOfflineDeviceCheck {
    if (self.offlineDeviceCheckTimer) {
        [self.offlineDeviceCheckTimer invalidate];
        self.offlineDeviceCheckTimer = nil;
    }
}

- (void)checkOfflineDevice {
    bdle_log_info(self, @"[BDLE][Browser] checkOfflineDevice");
    NSArray<BDLEService *> *currentServices = [self.discoveredBDLEServiceArray copy];
    for (BDLEService *service in currentServices) {
        if (service.checkCounter < 0) {
            continue;
        }
        service.checkCounter = -1;
        [_upnpServer checkServiceAlive:service.upnpDevice];
        bdle_log_info(self, @"[BDLE][Browser] checkOfflineDevice -> name:%@, url:%@", service.serviceName, service.upnpDevice.URLHeader);
    }
}

- (void)addBDLEService:(BDLEService *)service {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isExist = NO;
        for (BDLEService *enumService in self.discoveredBDLEServiceArray) {
            if ([enumService.ipAddress isEqualToString:service.ipAddress] &&
                [enumService.serviceName isEqualToString:service.serviceName]) {
                isExist = YES;
                break;
            }
        }
        if (!isExist) {
            [self.discoveredBDLEServiceArray addObject:service];
        }
    });
}

- (void)removeUnavailableBDLEDevice:(BDCLUPnPDevice *)device {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<BDLEService *> *array = [self.discoveredBDLEServiceArray copy];
        NSString *ipAddress = device.ipAddress;
        NSString *serviceName = device.friendlyName;
        NSInteger index = NSNotFound;
        BDLEService *findService = nil;
        for (int i = 0; i < array.count; i++) {
            BDLEService *service = [array objectAtIndex:i];
            if ([service.ipAddress isEqualToString:ipAddress] &&
                [service.serviceName isEqualToString:serviceName]) {
                index = i;
                findService = service;
                break;
            }
        }
        if (findService) {
            [self.discoveredBDLEServiceArray removeObjectAtIndex:index];
            if ([self.delegate respondsToSelector:@selector(bdleBrowser:unavailableBDLEService:)]) {
                [self.delegate bdleBrowser:self unavailableBDLEService:findService];
            }
        }
    });
}

#pragma mark - BDCLUPnPServerDelegate
- (void)upnpSearchChangeWithResults:(NSArray<BDCLUPnPDevice *> *)devices {
    for (BDCLUPnPDevice *device in devices) {
        if (!device.isMediaRender) {
            continue;
        }
        if (device.supportBDLEProtocol) {
            BDLEService *service = [[BDLEService alloc] initWithDevice:device];
            service.upnpServer = self.upnpServer;
            if (device.bdleServiceAvailable) {
                // 已经成功获取过GetDeviceInfo
                [self addBDLEService:service];
            } else if (!device.bdleServiceDIRequesting) {
                // 还没有获取过GetDeviceInfo && 没有开始获取
                device.bdleServiceDIRequesting = YES;
                [self.pendingBDLEServiceSet addObject:service];
                __weak typeof(self) weakSelf = self;
                [service sendGetDeviceInfo:^(NSError *error) {
                    __strong typeof(weakSelf) self = weakSelf;
                    device.bdleServiceDIRequesting = NO;
                    device.bdleServiceAvailable = (error == nil);
                    [self.pendingBDLEServiceSet removeObject:service];
                    if (!error) {
                        [self addBDLEService:service];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(bdleBrowser:didFindBDLEServices:)]) {
                                [self.delegate bdleBrowser:self didFindBDLEServices:[self.discoveredBDLEServiceArray copy]];
                            }
                        });
                    }
                }];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.discoveredBDLEServiceArray.count > 0 && [self.delegate respondsToSelector:@selector(bdleBrowser:didFindBDLEServices:)]) {
            [self.delegate bdleBrowser:self didFindBDLEServices:[self.discoveredBDLEServiceArray copy]];
        }
    });
}

- (void)upnpSearchErrorWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(bdleBrowser:onError:)]) {
        [self.delegate bdleBrowser:self onError:error];
    }
}

- (void)upnpDeviceUnavailable:(BDCLUPnPDevice *)offlineDevice {
    if (offlineDevice.supportBDLEProtocol) {
        [self removeUnavailableBDLEDevice:offlineDevice];
    }
}

@end
