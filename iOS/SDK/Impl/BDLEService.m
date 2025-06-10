//
//  BDLEService.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEService.h"
#import "BDLEDefine.h"
#import "BDLEUtils.h"
#import "BDCLUPnPDevice.h"

@interface BDLEService() {
    NSString *_serviceRef;
    NSString *_serviceBrand;
    NSString *_serviceModel;
    NSString *_serviceAppVersion;
    NSString *_serviceSdkVersion;
    NSString *_serviceOsVersion;
}

@property (nonatomic, strong) BDCLUPnPDevice *upnpDevice;

@property (nonatomic, copy) NSDictionary *localDeviceInfo;

@end

@implementation BDLEService

- (instancetype)initWithDevice:(BDCLUPnPDevice *)device {
    self = [super init];
    if (self) {
        _upnpDevice = device;
        _messageBus = [[BDLEMessageBus alloc] init];
    }
    return self;
}

- (BOOL)isEqualToBDLEService:(BDLEService *)service {
    if (self == service) {
        return YES;
    }
    if (![service isKindOfClass:[BDLEService class]] || service.upnpDevice == nil) {
        return NO;
    }
    return [self.upnpDevice.uuid isEqualToString:service.upnpDevice.uuid];
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToBDLEService:object];
}

- (NSString *)ipAddress {
    return self.upnpDevice.ipAddress;
}

- (NSString *)serviceName {
    return self.upnpDevice.friendlyName;
}

- (NSString *)modelName {
    return self.upnpDevice.modelName;
}

- (NSString *)modelNumber {
    return self.upnpDevice.modelNumber;
}

- (NSString *)modelURL {
    return self.upnpDevice.modelURL;
}

- (NSString *)manufacturer {
    return self.upnpDevice.manufacturer;
}

- (NSString *)manufacturerURL {
    return self.upnpDevice.manufacturerURL;
}

- (NSString *)serviceRef {
    return self.upnpDevice.uuid;
}

- (int)bdleSocketPort {
    return self.upnpDevice.bdleSocketPort;
}

- (NSString *)serviceUniRef {
    return _serviceRef ?: @"";
}

- (NSString *)serviceBrand {
    return _serviceBrand ?: @"";
}

- (NSString *)serviceModel {
    return _serviceModel ?: @"";
}

- (NSNumber *)serviceBitmap {
    return self.messageBus.remoteBitmap;
}

- (NSString *)serviceAppVersion {
    return _serviceAppVersion ?: @"";
}

- (NSString *)serviceSdkVersion {
    return _serviceSdkVersion ?: @"";
}

- (NSString *)serviceOsVersion {
    return _serviceOsVersion ?: @"";
}

- (void)setServiceRef:(NSString *)serviceRef brand:(NSString *)brand model:(NSString *)model {
    if ([serviceRef isKindOfClass:[NSString class]] && serviceRef.length > 0) {
        _serviceRef = [serviceRef copy];
    }
    if ([brand isKindOfClass:[NSString class]] && brand.length > 0) {
        _serviceBrand = [brand copy];
    }
    if ([model isKindOfClass:[NSString class]] && model.length > 0) {
        _serviceModel = [model copy];
    }
}

- (void)setServiceAppVersion:(NSString *)appVersion sdkVersion:(NSString *)sdkVersion osVersion:(NSString *)osVersion {
    if ([appVersion isKindOfClass:[NSString class]] && appVersion.length > 0) {
        _serviceAppVersion = [appVersion copy];
    }
    if ([sdkVersion isKindOfClass:[NSString class]] && sdkVersion.length > 0) {
        _serviceSdkVersion = [sdkVersion copy];
    }
    if ([osVersion isKindOfClass:[NSString class]] && osVersion.length > 0) {
        _serviceOsVersion = [osVersion copy];
    }
}

- (void)setCheckCounter:(NSInteger)checkCounter {
    _upnpDevice.checkCounter = checkCounter;
}

- (NSInteger)checkCounter {
    return _upnpDevice.checkCounter;
}

- (NSDictionary *)localDeviceInfo {
    if (!_localDeviceInfo) {
        NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
        mutDict[@"browseId"] = [BDLEUtils getRandomUUID];
        mutDict[@"clientId"] = [BDLEUtils getRandomUUID];
        mutDict[@"name"] = [UIDevice currentDevice].name;
        mutDict[@"platform"] = @"iOS";
        mutDict[@"packageName"] = [[NSBundle mainBundle] bundleIdentifier];
        mutDict[@"version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        mutDict[@"osVersion"] = [UIDevice currentDevice].systemVersion;
        mutDict[@"bitmap"] = @(BDLEPPDeviceBitmapFlagEncrypt | BDLEPPDeviceBitmapFlagStretch | BDLEPPDeviceBitmapFlagSpeed);
        mutDict[@"copyright"] = @"BDLE/1.0";
        _localDeviceInfo = [mutDict copy];
    }
    return _localDeviceInfo;
}

- (void)sendGetDeviceInfo:(void (^)(NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    BDLEPPGetDeviceInfoCmd *cmd = [BDLEPPGetDeviceInfoCmd cmd];
    cmd.deviceInfo = [self localDeviceInfo];

    BDLEPPGetDeviceInfoRequest *request = [BDLEPPGetDeviceInfoRequest requestWithBody:cmd];
    [self.messageBus sendMessageRequest:request
                                   type:BDLESocketRequestTypeShortConnection
                              ipAddress:self.ipAddress
                                   port:self.bdleSocketPort
                             completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!error && [response[@"body"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *body = response[@"body"];
            NSDictionary *deviceInfo = body[@"deviceInfo"];
            NSString *serviceRef = deviceInfo[@"deviceId"];
            NSString *serviceBrand = deviceInfo[@"deviceBrand"];
            NSString *serviceModel = deviceInfo[@"deviceModel"];
            NSString *serviceAppVersion = deviceInfo[@"appVersion"];
            NSString *serviceSdkVersion = deviceInfo[@"version"];
            NSString *serviceOsVersion = deviceInfo[@"osVersion"];
            NSNumber *bitmap = deviceInfo[@"bitmap"];
            [self setServiceRef:serviceRef brand:serviceBrand model:serviceModel];
            [self setServiceAppVersion:serviceAppVersion sdkVersion:serviceSdkVersion osVersion:serviceOsVersion];
            self.messageBus.remoteBitmap = bitmap;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error);
            }
        });
    }];
}

- (NSDictionary *)eventExtraDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([self.serviceUniRef isKindOfClass:[NSString class]] && self.serviceUniRef.length > 0) {
        dict[@"tv_service_unique_ref"] = self.serviceUniRef;
    }
    if ([self.serviceBrand isKindOfClass:[NSString class]] && self.serviceBrand.length > 0) {
        dict[@"tv_service_brand"] = self.serviceBrand;
    }
    if ([self.serviceModel isKindOfClass:[NSString class]] && self.serviceModel.length > 0) {
        dict[@"tv_service_model"] = self.serviceModel;
    }
    if ([self.serviceBitmap isKindOfClass:[NSNumber class]] && self.serviceBitmap.stringValue.length > 0) {
        dict[@"tv_service_bitmap"] = self.serviceBitmap.stringValue;
    }
    if ([self.serviceAppVersion isKindOfClass:[NSString class]] && self.serviceAppVersion.length > 0) {
        dict[@"tv_service_app_version"] = self.serviceAppVersion;
    }
    if ([self.serviceSdkVersion isKindOfClass:[NSString class]] && self.serviceSdkVersion.length > 0) {
        dict[@"tv_service_sdk_version"] = self.serviceSdkVersion;
    }
    if ([self.serviceOsVersion isKindOfClass:[NSString class]] && self.serviceOsVersion.length > 0) {
        dict[@"tv_service_os_version"] = self.serviceOsVersion;
    }
    if ([self.manufacturer isKindOfClass:[NSString class]] && self.manufacturer.length > 0) {
        dict[@"manufacturer"] = self.manufacturer;
    }
    return [dict copy];
}


@end
