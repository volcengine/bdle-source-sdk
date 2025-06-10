//
//  BDLEMessageBus.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import "BDLEPrivateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLESocketRequestType) {
    BDLESocketRequestTypeUnknown = 0,
    BDLESocketRequestTypeShortConnection,
    BDLESocketRequestTypeLongConnection,
};

typedef void(^BDLESocketResponseBlock)(NSDictionary * _Nullable response, NSError * _Nullable error);

@class BDLEMessageBus;

@protocol BDLEMessageBusDelegate <NSObject>

@optional
- (void)messageBus:(BDLEMessageBus *)bus didConnected:(NSError * _Nullable)error;
- (void)messageBus:(BDLEMessageBus *)bus didDisconnected:(NSError * _Nullable)error;
- (void)messageBus:(BDLEMessageBus *)bus didReceiveSinkRequest:(BDLEPPBaseCmd *)request;

@end

@protocol BDLEMessageBusEventDataSource <NSObject>

@optional
- (NSDictionary *)messageBus:(BDLEMessageBus *)bus eventExtraDictionary:(NSString *)eventName;

@end

@interface BDLEMessageBus : NSObject

@property (nonatomic, strong) NSNumber *remoteBitmap;

@property (nonatomic, weak) id<BDLEMessageBusDelegate> delegate;

@property (nonatomic, weak) id<BDLEMessageBusEventDataSource> eventDataSource;

- (BOOL)connect:(NSString *)ipAddress port:(int)port error:(NSError **)error;

- (void)disconnect;

- (void)sendMessageRequest:(BDLEPPBaseCmd *)message
                      type:(BDLESocketRequestType)type
                 ipAddress:(NSString *)ipAddress
                      port:(int)port
                completion:(BDLESocketResponseBlock _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
