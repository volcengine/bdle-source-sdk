//
//  BDLEConnection.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDLEService, BDLEConnection;
@class BDLEPPBaseCmd, BDLEPPBaseCmdResponse;

@protocol BDLEConnectionDelegate <NSObject>

- (void)bdleConnection:(BDLEConnection *)connection onError:(NSError *)error;
- (void)bdleConnection:(BDLEConnection *)connection didConnectToService:(BDLEService *)service;
- (void)bdleConnection:(BDLEConnection *)connection didDisonnectToService:(BDLEService *)service;

@end

// 收到Sink端推送回调
@protocol BDLEConnectionNotifyDelegate <NSObject>

- (void)bdleConnection:(BDLEConnection *)connection didReceiveSinkRequest:(BDLEPPBaseCmd *)request;

@end

@interface BDLEConnection : NSObject

@property (nonatomic, weak) id<BDLEConnectionDelegate> delegate;
@property (nonatomic, weak) id<BDLEConnectionNotifyDelegate> notifyDelegate;
@property (nonatomic, strong, readonly) BDLEService *bdleService;
@property (nonatomic, assign, readonly) BOOL isConnected;

- (instancetype)initWithBDLEService:(BDLEService * _Nullable)bdleService delegate:(NSObject<BDLEConnectionDelegate> * _Nullable)delegate;
- (void)connect;
- (void)connectWithNetworkCheck:(BOOL)needCheckNetwork
                       maxCount:(NSInteger)maxCount
                        timeout:(NSTimeInterval)timeout
                  retryInterval:(NSTimeInterval)retryInterval;
- (void)disconnect;

- (void)sendRequest:(BDLEPPBaseCmd *)request completionHandler:(void (^ _Nullable)(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
