//
//  BDLEToolboxView.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLEDebugItemType) {
    BDLEDebugItemTypeNone,
    BDLEDebugItemTypePlay,
    BDLEDebugItemTypePause,
    BDLEDebugItemTypeResume,
    BDLEDebugItemTypeStop,
    BDLEDebugItemTypeSeek,
    BDLEDebugItemTypePlayPreDrama,
    BDLEDebugItemTypePlayNextDrama,
    BDLEDebugItemTypePlayDramaId,
    BDLEDebugItemTypeAddDramaList,
    BDLEDebugItemTypeDeleteDramaList,
    BDLEDebugItemTypeSetDanmaku,
    BDLEDebugItemTypeSetSkipInfo,
    BDLEDebugItemTypeGetVolume,
    BDLEDebugItemTypeSetVolume,
    BDLEDebugItemTypeAddVolume,
    BDLEDebugItemTypeSubVolume,
    BDLEDebugItemTypeGetStatusInfo,
    BDLEDebugItemTypeGetMediaInfo,
    BDLEDebugItemTypeGetStatusAndMediaInfo,
    BDLEDebugItemTypeGetDeviceInfo,
};

@class BDLEPPMediaInfo;

@interface BDLEDebugItem : NSObject

@property (nonatomic, assign) BDLEDebugItemType type;
@property (nonatomic, copy) NSString *title;

+ (instancetype)itemWithType:(BDLEDebugItemType)type title:(NSString *)title;

@end

@protocol BDLEToolboxViewDelegate <NSObject>

@optional
- (void)toolboxDidSelectSpeed;
- (void)toolboxDidSelectResolution;
- (void)toolboxDidSelectSubtitle;
- (void)toolboxDidSelectLoopMode;
- (void)toolboxDidSelectShuffle;
- (void)toolboxDidSelectStretch;

@end

@interface BDLEToolboxView : UIView

@property (nonatomic, weak) id<BDLEToolboxViewDelegate> delegate;

- (void)reloadUIWithData:(BDLEPPMediaInfo *)mediaInfo;

@end

NS_ASSUME_NONNULL_END
