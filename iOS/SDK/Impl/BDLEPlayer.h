//
//  BDLEPlayer.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import "BDLEPrivateProtocol.h"
#import "BDLEDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class BDLEPlayer, BDLEConnection, BDLEPlayerItem;

@protocol BDLEPlayerDelegate <NSObject>

@optional
- (void)bdlePlayer:(BDLEPlayer *)player onStatusUpdate:(BDLEPlayStatus)status;
- (void)bdlePlayer:(BDLEPlayer *)player onProgressUpdate:(NSInteger)progress duration:(NSInteger)duration;
- (void)bdlePlayer:(BDLEPlayer *)player onDramaIdUpdate:(NSString *)dramaId;
- (void)bdlePlayer:(BDLEPlayer *)player onMediaInfoUpdate:(BDLEPPMediaInfo *)mediaInfo;
- (void)bdlePlayer:(BDLEPlayer *)player onReceiveRuntimeInfo:(NSString *)type code:(NSInteger)code message:(NSString *)message;

@end

@interface BDLEPlayer : NSObject

@property (nonatomic, weak) NSObject<BDLEPlayerDelegate> *delegate;
@property (nonatomic, strong) BDLEConnection *connection;


- (instancetype)initWithConnection:(BDLEConnection *)connection;

- (void)playWithItem:(BDLEPlayerItem *)item completionBlock:(void(^ _Nullable)(NSError * _Nullable error))completion;

- (void)pause;

- (void)resumePlay;

- (void)stop;

- (void)addVolume;

- (void)reduceVolume;

- (void)getVolume:(void(^ _Nullable)(NSInteger volume, BOOL success))completion;

- (void)setVolume:(NSInteger)volume;

- (void)setPlaySpeed:(float)speed;

- (void)seekTo:(NSInteger)seekTime;

- (void)playDramaWithDramaId:(NSString *)dramaId;

- (void)playDramaWithDramaId:(NSString *)dramaId completionBlock:(void(^ _Nullable)(NSError * _Nullable error))completion;

- (void)playPreDrama;

- (void)playNextDrama;

- (void)addDramaList:(NSArray<BDLEPPDramaBean *> *)dramaList beforeDramaId:(NSString * _Nullable)dramaId completionBlock:(void(^ _Nullable)(NSError *_Nullable error))completion;

- (void)deleteDramaList:(NSArray<NSString *> *)dramaIds;

- (void)clearDramaList;

- (void)setLoopMode:(BDLEPlayerLoopMode)loopMode shuffle:(BDLEPlayerShuffleMode)shuffle;

- (void)setStretchMode:(BDLEPlayerStretchMode)stretchMode;

- (void)setSkipHeadTail:(BOOL)enableSkip;

- (void)setDanmaku:(BDLEPPDanmakuBean *)danmaku;

- (void)setSubtitle:(BDLEPPSubtitleBean *)subtitle;

- (void)setResolution:(NSString * _Nullable)resolution
              urlType:(NSString * _Nullable)urlType
                  url:(NSString * _Nullable)url
                 mode:(NSInteger)mode;

- (void)getStatusInfo;

- (void)getMediaInfo;

- (NSArray<NSString *> *)remoteDramaIds;

@end

NS_ASSUME_NONNULL_END
