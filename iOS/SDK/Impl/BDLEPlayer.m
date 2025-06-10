//
//  BDLEPlayer.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEPlayer.h"
#import "BDLEConnection.h"
#import "BDLEService.h"
#import "BDLEPlayerItem.h"
#import "BDLEUtils.h"

@interface BDLEPlayer () <BDLEConnectionNotifyDelegate>

@property (nonatomic, weak) NSTimer *mediaStatusQueryTimer;
@property (nonatomic, assign) BDLEPlayStatus playStatus;
@property (nonatomic, assign) int64_t currentPosition;
@property (nonatomic, assign) int64_t totalDuration;
@property (nonatomic, copy) NSString *currentDramaId;
@property (nonatomic, strong) BDLEPPMediaInfo *currentMediaInfo;
@property (nonatomic, strong) NSMutableDictionary *dramaBeanCache;

@end

@implementation BDLEPlayer

- (instancetype)initWithConnection:(BDLEConnection *)connection {
    if (self = [super init]) {
        self.connection = connection;
        self.connection.notifyDelegate = self;
        self.dramaBeanCache = [[NSMutableDictionary alloc] init];
        bdle_log_info(self, @"[BDLE][Player] player init %p", &self);
    }
    return self;
}

- (void)dealloc {
    if (_mediaStatusQueryTimer) {
        [_mediaStatusQueryTimer invalidate];
        _mediaStatusQueryTimer = nil;
    }
    bdle_log_info(self, @"[BDLE][Player] player dealloced %p", &self);
}


- (void)playWithItem:(BDLEPlayerItem *)item completionBlock:(void(^)(NSError * _Nullable error))completion {
    bdle_log_info(self, @"[BDLE][Player] %@ play with item, isFakePlay: %ld, dramaCnt: %ld", self.connection.bdleService.serviceName, (long)item.fakePlay, (long)item.dramaBeans.count);

    if (item.fakePlay) {
        if (completion) {
            completion(nil);
        }
        return;
    }

    BDLEPPPlayCmd *cmd = [BDLEPPPlayCmd cmd];
    cmd.connectId = [BDLEUtils getRandomUUID];
    cmd.startDramaId = item.startDramaId;
    // 业务侧的时间戳是秒级，需要在协议侧换算为毫秒级
    for (BDLEPPDramaBean *drama in item.dramaBeans) {
        drama.mediaAssetBean.startPosition = drama.mediaAssetBean.startPosition * 1000;
    }
    cmd.dramaBeans = item.dramaBeans;
    cmd.playControlInfo = item.playControlInfo;
    BDLEPPPlayRequest *request = [BDLEPPPlayRequest requestWithBody:cmd];
    request.connectId = cmd.connectId;

    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!error) {
            [self addDramaCache:cmd.dramaBeans];
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)pause {
    BDLEPPPauseRequest *request = [BDLEPPPauseRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)resumePlay {
    BDLEPPResumeRequest *request = [BDLEPPResumeRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)stop {
    bdle_log_info(self, @"[BDLE][Player] %@ stop invoked", self.connection.bdleService.serviceName);
    // 主动结束时直接销毁timer
    [self stopMediaStatusQueryTimer];

    BDLEPPStopRequest *request = [BDLEPPStopRequest request];
    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        bdle_log_info(self, @"[BDLE][Player] %@ stop with result: %@", self.connection.bdleService.serviceName, error);
        if (!error) {
            [self.dramaBeanCache removeAllObjects];
            self.currentMediaInfo = nil;
        }
    }];
}

- (void)getVolume:(void(^ _Nullable)(NSInteger volume, BOOL success))completion {
    BDLEPPGetVolumeRequest *request = [BDLEPPGetVolumeRequest request];
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:[BDLEPPGetVolumeResponse class]]) {
            BDLEPPGetVolumeResponse *cvtResp = (BDLEPPGetVolumeResponse *)response;
            NSInteger volume = [cvtResp body].volume;
            if (completion) {
                completion(volume, YES);
            }
        } else {
            if (completion) {
                completion(0, NO);
            }
        }
    }];
}

- (void)setVolume:(NSInteger)volume {
    BDLEPPSetVolumeCmd *cmd = [BDLEPPSetVolumeCmd cmd];
    cmd.volume = volume;
    BDLEPPSetVolumeRequest *request = [BDLEPPSetVolumeRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)addVolume {
    BDLEPPAddVolumeRequest *request = [BDLEPPAddVolumeRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)reduceVolume {
    BDLEPPSubVolumeRequest *request = [BDLEPPSubVolumeRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setPlaySpeed:(float)speed {
    BDLEPPSpeedCmd *cmd = [BDLEPPSpeedCmd cmd];
    cmd.speed = speed;
    BDLEPPSetSpeedRequest *request = [BDLEPPSetSpeedRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)seekTo:(NSInteger)seekTime {
    BDLEPPSeekCmd *cmd = [BDLEPPSeekCmd cmd];
    // 业务侧的时间戳是秒级，需要在协议侧换算为毫秒级
    cmd.position = (seekTime * 1000);
    BDLEPPSeekRequest *request = [BDLEPPSeekRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)playDramaWithDramaId:(NSString *)dramaId {
    [self playDramaWithDramaId:dramaId completionBlock:nil];
}

- (void)playDramaWithDramaId:(NSString *)dramaId completionBlock:(void(^ _Nullable)(NSError * _Nullable error))completion {
    BDLEPPPlayDramaIdCmd *cmd = [BDLEPPPlayDramaIdCmd cmd];
    cmd.startDramaId = dramaId;
    BDLEPPPlayDramaIdRequest *request = [BDLEPPPlayDramaIdRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)playPreDrama {
    BDLEPPPlayPreDramaRequest *request = [BDLEPPPlayPreDramaRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)playNextDrama {
    BDLEPPPlayNextDramaRequest *request = [BDLEPPPlayNextDramaRequest request];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)addDramaList:(NSArray<BDLEPPDramaBean *> *)dramaList beforeDramaId:(NSString *)dramaId completionBlock:(void (^)(NSError * _Nullable))completion {
    BDLEPPAddDramaListCmd *cmd = [BDLEPPAddDramaListCmd cmd];
    cmd.insertBeforeDramaId = dramaId;
    cmd.dramaBeans = dramaList;
    BDLEPPAddDramaListRequest *request = [BDLEPPAddDramaListRequest requestWithBody:cmd];
    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!error) {
            [self addDramaCache:cmd.dramaBeans];
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)deleteDramaList:(NSArray<NSString *> *)dramaIds {
    BDLEPPDeleteDramaListCmd *cmd = [BDLEPPDeleteDramaListCmd cmd];
    cmd.dramaIds = dramaIds;
    BDLEPPDeleteDramaListRequest *request = [BDLEPPDeleteDramaListRequest requestWithBody:cmd];
    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!error) {
            [self removeDramaCache:dramaIds];
        }
    }];
}

- (void)clearDramaList {
    BDLEPPClearDramaListRequest *request = [BDLEPPClearDramaListRequest request];
    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!error) {
            [self.dramaBeanCache removeAllObjects];
        }
    }];
}

- (void)setLoopMode:(BDLEPlayerLoopMode)loopMode shuffle:(BDLEPlayerShuffleMode)shuffle {
    BDLEPPLoopModeCmd *cmd = [BDLEPPLoopModeCmd cmd];
    cmd.loopMode = loopMode;
    cmd.shuffle = shuffle;
    BDLEPPSetLoopModeRequest *request = [BDLEPPSetLoopModeRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setStretchMode:(BDLEPlayerStretchMode)stretchMode {
    BDLEPPStretchModeCmd *cmd = [BDLEPPStretchModeCmd cmd];
    cmd.stretch = stretchMode;
    BDLEPPSetStretchModeRequest *request = [BDLEPPSetStretchModeRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setSkipHeadTail:(BOOL)enableSkip {
    BDLEPPSkipInfoCmd *cmd = [BDLEPPSkipInfoCmd cmd];
    cmd.skip = enableSkip ? 1 : 0;
    BDLEPPSetSkipInfoRequest *request = [BDLEPPSetSkipInfoRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setDanmaku:(BDLEPPDanmakuBean *)danmaku {
    BDLEPPDanmakuCmd *cmd = [BDLEPPDanmakuCmd cmd];
    cmd.danmaku = danmaku;
    BDLEPPSetDanmakuRequest *request = [BDLEPPSetDanmakuRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setSubtitle:(BDLEPPSubtitleBean *)subtitle {
    BDLEPPSubtitleCmd *cmd = [BDLEPPSubtitleCmd cmd];
    cmd.subtitle = subtitle;
    BDLEPPSetSubtitleRequest *request = [BDLEPPSetSubtitleRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)setResolution:(NSString *)resolution urlType:(NSString *)urlType url:(NSString *)url mode:(NSInteger)mode {
    if (mode == 0 && BDLE_isEmptyString(resolution)) {
        return;
    }
    BDLEPPResolutionCmd *cmd = [BDLEPPResolutionCmd cmd];
    if (mode == 0) {
        cmd.resolution = resolution;
        if (BDLE_isEmptyString(urlType) && BDLE_isEmptyString(url)) {
            // 通过本地缓存匹配url数据
            if (self.currentMediaInfo) {
                NSString *currDramaId = self.currentMediaInfo.dramaId;
                if (!BDLE_isEmptyString(currDramaId)) {
                    // dramaId存在
                    BDLEPPDramaBean *theDrama = [self.dramaBeanCache objectForKey:currDramaId];
                    if (theDrama) {
                        // 找到了这一集，接下来尝试用这个清晰度去匹配url
                        for (BDLEPPUrlBean *urlBean in theDrama.urlBeans) {
                            if ([urlBean.resolution isEqualToString:resolution ?: @""]) {
                                // 命中了对应的清晰度
                                cmd.urlType = urlBean.urlType;
                                cmd.url = urlBean.url;
                                break;
                            }
                        }
                    }
                }
            }
        } else {
            cmd.urlType = urlType;
            cmd.url = url;
        }
    } else {
        cmd.resolutionMode = mode;
    }
    BDLEPPSetResolutionRequest *request = [BDLEPPSetResolutionRequest requestWithBody:cmd];
    [self.connection sendRequest:request completionHandler:nil];
}

- (void)getStatusInfo {
    __weak typeof(self) weakSelf = self;
    BDLEPPGetStatusInfoRequest *request = [BDLEPPGetStatusInfoRequest request];
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if ([response isKindOfClass:[BDLEPPGetStatusInfoResponse class]]) {
            BDLEPPGetStatusInfoCmd *cmd = (BDLEPPGetStatusInfoCmd *)[response body];
            BDLEPPStatusInfo *statusInfo = cmd.statusInfo;
            [self onStatusInfoUpdate:statusInfo];
        }
    }];
}

- (void)getMediaInfo {
    BDLEPPGetMediaInfoRequest *request = [BDLEPPGetMediaInfoRequest request];
    __weak typeof(self) weakSelf = self;
    [self.connection sendRequest:request completionHandler:^(BDLEPPBaseCmdResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if ([response isKindOfClass:[BDLEPPGetMediaInfoResponse class]]) {
            BDLEPPGetMediaInfoCmd *cmd = (BDLEPPGetMediaInfoCmd *)[response body];
            BDLEPPMediaInfo *mediaInfo = cmd.mediaInfo;
            [self onMediaInfoUpdate:mediaInfo];
        }
    }];
}

- (NSArray<NSString *> *)remoteDramaIds {

    if (!self.currentMediaInfo || !([self.currentMediaInfo.dramaBeans isKindOfClass:[NSArray class]] && self.currentMediaInfo.dramaBeans.count > 0)) {
        return @[];
    }
    NSMutableArray *result = [NSMutableArray array];
    for (BDLEPPDramaBean *bean in self.currentMediaInfo.dramaBeans) {
        [result addObject:(bean.dramaId ?: @"")];
    }
    return [result copy];
}

#pragma mark - BDLEConnectionNotifyDelegate
- (void)bdleConnection:(BDLEConnection *)connection didReceiveSinkRequest:(BDLEPPBaseCmd *)request {
    NSString *cmd = request.body.cmd;
    if ([cmd isEqualToString:kBDLEPPCmdKey_PushStatusInfo] && [request isKindOfClass:[BDLEPPPushStatusInfoRequest class]]) {
        BDLEPPPushStatusInfoRequest *cvtRequest = (BDLEPPPushStatusInfoRequest *)request;
        BDLEPPStatusInfo *info = [cvtRequest body].statusInfo;
        [self onStatusInfoUpdate:info];
    } else if ([cmd isEqualToString:kBDLEPPCmdKey_PushMediaInfo] && [request isKindOfClass:[BDLEPPPushMediaInfoRequest class]]) {
        BDLEPPPushMediaInfoRequest *cvtRequest = (BDLEPPPushMediaInfoRequest *)request;
        BDLEPPMediaInfo *info = [cvtRequest body].mediaInfo;
        [self onMediaInfoUpdate:info];
    } else if ([cmd isEqualToString:kBDLEPPCmdKey_PushRuntimeInfo] && [request isKindOfClass:[BDLEPPPushRuntimeInfoRequest class]]) {
        BDLEPPPushRuntimeInfoRequest *cvtRequest = (BDLEPPPushRuntimeInfoRequest *)request;
        BDLEPPRuntimeInfo *info = [cvtRequest body].error;
        [self onReceiveRuntimeInfo:info];
    }
}

#pragma mark - Private
- (void)startMediaStatusQueryTimer {
    bdle_log_info(self, @"[BDLE][Player] start query timer invoked");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.mediaStatusQueryTimer) {
            bdle_log_info(self, @"[BDLE][Player] kill exist timer when start: %@", self.mediaStatusQueryTimer);
            [self.mediaStatusQueryTimer invalidate];
            self.mediaStatusQueryTimer = nil;
        }
        NSTimeInterval interval = 1.0f;
        self.mediaStatusQueryTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:[BDLEWeakProxy proxyWithTarget:self] selector:@selector(mediaStatusQueryTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.mediaStatusQueryTimer forMode:NSRunLoopCommonModes];
        bdle_log_info(self, @"[BDLE][Player] start query timer: %@", self.mediaStatusQueryTimer);
    });
}

- (void)stopMediaStatusQueryTimer {
    bdle_log_info(self, @"[BDLE][Player] stop query timer invoked");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self.mediaStatusQueryTimer) {
            bdle_log_info(self, @"[BDLE][Player] stop query timer: %@", self.mediaStatusQueryTimer);
            [self.mediaStatusQueryTimer invalidate];
            self.mediaStatusQueryTimer = nil;
        }
    });
}

- (void)mediaStatusQueryTimerFired:(NSTimer *)timer {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        bdle_log_info(self, @"[BDLE][Player] fire query timer: %@", self.mediaStatusQueryTimer);
        [self getStatusInfo];
    });
}

- (void)onStatusInfoUpdate:(BDLEPPStatusInfo *)statusInfo {
    NSString *status = statusInfo.status;
    // 更新状态
    if (!BDLE_isEmptyString(statusInfo.status)) {
        NSNumber *statusNum = [[self class] stateMap][statusInfo.status];
        if (statusNum) {
            BDLEPlayStatus playStatus = [statusNum integerValue];
            if (_playStatus != playStatus) {
                _playStatus = playStatus;

                if ([status isEqualToString:kBDLEPPPlayStatus_PLAYING]) {
                    // 开启轮询
                    [self startMediaStatusQueryTimer];
                } else {
                    // 销毁轮询
                    [self stopMediaStatusQueryTimer];
                }

                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if ([self.delegate respondsToSelector:@selector(bdlePlayer:onStatusUpdate:)]) {
                        if (playStatus == BDLEPlayStatusStopped) {
                            // 跟DLNA的思路对齐，如果是Stop，检查是否是播到了视频最后5s，如果是则返回Complete
                            if (self.currentPosition > 0 && self.totalDuration > 0 && self.currentPosition + 5 >= self.totalDuration) {
                                self.playStatus = BDLEPlayStatusCompleted;
                            }
                        }
                        [self.delegate bdlePlayer:self onStatusUpdate:self.playStatus];
                    }
                });
            }
        }
    }

    // 更新进度
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if ([self.delegate respondsToSelector:@selector(bdlePlayer:onProgressUpdate:duration:)]) {
            int64_t currPos = (int64_t)ceil(statusInfo.position / 1000.0);
            int64_t duration = (int64_t)ceil(statusInfo.duration / 1000.0);
            self.currentPosition = currPos;
            self.totalDuration = duration;
            [self.delegate bdlePlayer:self onProgressUpdate:currPos duration:duration];
        }
    });
}

- (void)onMediaInfoUpdate:(BDLEPPMediaInfo *)mediaInfo {
    self.currentMediaInfo = mediaInfo;
    if (!BDLE_isEmptyString(mediaInfo.dramaId)) {
        if (![_currentDramaId isEqualToString:mediaInfo.dramaId]) {
            _currentDramaId = mediaInfo.dramaId;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(bdlePlayer:onDramaIdUpdate:)]) {
                    [self.delegate bdlePlayer:self onDramaIdUpdate:mediaInfo.dramaId];
                }
            });
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(bdlePlayer:onMediaInfoUpdate:)]) {
            [self.delegate bdlePlayer:self onMediaInfoUpdate:mediaInfo];
        }
    });
}

- (void)onReceiveRuntimeInfo:(BDLEPPRuntimeInfo *)runtimeInfo {
    bdle_log_info(self, @"[BDLE][Player] on receive runtime info, type=%@, code=%ld, msg=%@", runtimeInfo.type, (long)runtimeInfo.code, runtimeInfo.msg);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(bdlePlayer:onReceiveRuntimeInfo:code:message:)]) {
            [self.delegate bdlePlayer:self onReceiveRuntimeInfo:runtimeInfo.type code:runtimeInfo.code message:runtimeInfo.msg];
        }
    });
}

- (void)addDramaCache:(NSArray<BDLEPPDramaBean *> *)dramaArr {
    for (BDLEPPDramaBean *theBean in dramaArr) {
        if (!BDLE_isEmptyString(theBean.dramaId)) {
            self.dramaBeanCache[theBean.dramaId] = theBean;
        }
    }
}

- (void)removeDramaCache:(NSArray *)dramaIds {
    for (NSString *dramaId in dramaIds) {
        if (!BDLE_isEmptyString(dramaId)) {
            self.dramaBeanCache[dramaId] = nil;
        }
    }
}

#pragma mark - Util
+ (NSDictionary *)stateMap {
    return @{
        kBDLEPPPlayStatus_NO_MEDIA_PRESENT: @(BDLEPlayStatusUnknown),
        kBDLEPPPlayStatus_LOADING: @(BDLEPlayStatusLoading),
        kBDLEPPPlayStatus_PLAYING: @(BDLEPlayStatusPlaying),
        kBDLEPPPlayStatus_PAUSED_PLAYBACK: @(BDLEPlayStatusPause),
        kBDLEPPPlayStatus_STOPPED: @(BDLEPlayStatusStopped),
        kBDLEPPPlayStatus_COMPLETED: @(BDLEPlayStatusCompleted),
        kBDLEPPPlayStatus_WAITFORPURCHASING: @(BDLEPlayStatusPause),
        kBDLEPPPlayStatus_ADS: @(BDLEPlayStatusPause)
    };
}

@end
