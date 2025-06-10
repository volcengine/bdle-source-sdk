//
//  BDLEBrowser.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDLEBrowser, BDLEService;

@protocol BDLEBrowserDelegate <NSObject>

@optional
- (void)bdleBrowser:(BDLEBrowser *)browser onError:(NSError *)error;
- (void)bdleBrowser:(BDLEBrowser *)browser didFindBDLEServices:(NSArray<BDLEService *> *)services;
- (void)bdleBrowser:(BDLEBrowser *)browser unavailableBDLEService:(BDLEService *)service;

@end

@interface BDLEBrowser : NSObject

@property (nonatomic, weak) NSObject<BDLEBrowserDelegate> *delegate;

- (void)searchServices;
- (void)stopSearch;

@end

NS_ASSUME_NONNULL_END
