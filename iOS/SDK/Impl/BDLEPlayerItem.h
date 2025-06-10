//
//  BDLEPlayerItem.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import "BDLEPrivateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLEPlayerItem : NSObject

@property (nonatomic, copy) NSString *startDramaId;
@property (nonatomic, copy) NSArray<BDLEPPDramaBean *> *dramaBeans;
@property (nonatomic, strong) BDLEPPPlayControlInfo *playControlInfo;
@property (nonatomic, assign) BOOL fakePlay;

@end

NS_ASSUME_NONNULL_END
