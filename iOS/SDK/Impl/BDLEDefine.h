//
//  BDLEDefine.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#ifndef BDLEDefine_h
#define BDLEDefine_h

typedef NS_ENUM(NSInteger, BDLEPlayerLoopMode) {
    BDLEPlayerLoopModeNone = 0,       // 不循环
    BDLEPlayerLoopModeSingle = 1,     // 单个循环
    BDLEPlayerLoopModeList = 2,       // 列表循环
};

typedef NS_ENUM(NSInteger, BDLEPlayerShuffleMode) {
    BDLEPlayerShuffleModeDisable = 0, // 不随机
    BDLEPlayerShuffleModeEnable = 1,  // 启用随机
};

typedef NS_ENUM(NSInteger, BDLEPlayerStretchMode) {
    BDLEPlayerStretchModeScaleAspectFit = 0,  // 默认，等比拉伸，优先保留内容（屏幕两侧有黑边）
    BDLEPlayerStretchModeScaleToFill = 1,     // 强制填满画布（可能导致变形）
    BDLEPlayerStretchModeScaleAspectFill = 2, // 等比拉伸，优先填满画布（超出的内容被裁剪）
};

typedef NS_ENUM(NSUInteger, BDLEPlayStatus) {
    BDLEPlayStatusUnknown = 0,  // 未知状态
    BDLEPlayStatusLoading,      // 视频正在加载
    BDLEPlayStatusPlaying,      // 正在播放
    BDLEPlayStatusPause,        // 暂停
    BDLEPlayStatusStopped,      // 退出播放
    BDLEPlayStatusCompleted,    // 播放完成
    BDLEPlayStatusError,        // 播放错误
};

#endif /* BDLEDefine_h */
