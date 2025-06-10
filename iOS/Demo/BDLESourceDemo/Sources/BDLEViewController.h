//
//  BDLEViewController.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <UIKit/UIKit.h>

@class BDLEService;

NS_ASSUME_NONNULL_BEGIN

@interface BDLEViewController : UIViewController

- (instancetype)initWithService:(BDLEService *)service;

@end

NS_ASSUME_NONNULL_END
