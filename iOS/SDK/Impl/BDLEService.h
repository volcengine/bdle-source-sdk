//
//  BDLEService.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import "BDLEMessageBus.h"

NS_ASSUME_NONNULL_BEGIN

@class BDCLUPnPDevice, BDCLUPnPServer;

@interface BDLEService : NSObject

@property (nonatomic, strong, readonly) BDCLUPnPDevice *upnpDevice;
@property (nonatomic, strong) BDCLUPnPServer *upnpServer;
@property (nonatomic, strong) BDLEMessageBus *messageBus;

@property (nonatomic, copy, readonly) NSString *ipAddress;
@property (nonatomic, copy, readonly) NSString *serviceName;
@property (nonatomic, copy, readonly) NSString *serviceRef;
@property (nonatomic, copy, readonly) NSString *modelName;
@property (nonatomic, copy, readonly) NSString *modelNumber;
@property (nonatomic, copy, readonly) NSString *modelURL;
@property (nonatomic, copy, readonly) NSString *manufacturer;
@property (nonatomic, copy, readonly) NSString *manufacturerURL;
@property (nonatomic, assign, readonly) int bdleSocketPort;

@property (nonatomic, copy, readonly) NSString *serviceUniRef;
@property (nonatomic, copy, readonly) NSString *serviceBrand;
@property (nonatomic, copy, readonly) NSString *serviceModel;
@property (nonatomic, strong, readonly) NSNumber *serviceBitmap;
@property (nonatomic, copy, readonly) NSString *serviceAppVersion;
@property (nonatomic, copy, readonly) NSString *serviceSdkVersion;
@property (nonatomic, copy, readonly) NSString *serviceOsVersion;

@property (nonatomic, assign) NSInteger checkCounter;

- (instancetype)initWithDevice:(BDCLUPnPDevice *)device;

- (void)sendGetDeviceInfo:(void(^)(NSError * _Nullable error))completion;

- (NSDictionary *)eventExtraDictionary;

@end

NS_ASSUME_NONNULL_END
