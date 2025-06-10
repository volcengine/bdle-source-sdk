//
//  BDLEPrivateProtocol.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEPrivateProtocol.h"
#import <YYModel/YYModel.h>

NSString * const kBDLEPPCmdKey_GetDeviceInfo = @"GetDeviceInfo";
NSString * const kBDLEPPCmdKey_GetMediaInfo = @"GetMediaInfo";
NSString * const kBDLEPPCmdKey_GetStatusInfo = @"GetStatusInfo";
NSString * const kBDLEPPCmdKey_SetLoopMode = @"SetLoopMode";
NSString * const kBDLEPPCmdKey_SetSpeed = @"SetSpeed";
NSString * const kBDLEPPCmdKey_SetDanmaku = @"SetDanmaku";
NSString * const kBDLEPPCmdKey_SetSubtitle = @"SetSubtitle";
NSString * const kBDLEPPCmdKey_SetStretchMode = @"SetStretchMode";
NSString * const kBDLEPPCmdKey_SetSkipInfo = @"SetSkipInfo";
NSString * const kBDLEPPCmdKey_SetResolution = @"SetResolution";
NSString * const kBDLEPPCmdKey_Play = @"Play";
NSString * const kBDLEPPCmdKey_Pause = @"Pause";
NSString * const kBDLEPPCmdKey_Resume = @"Resume";
NSString * const kBDLEPPCmdKey_Stop = @"Stop";
NSString * const kBDLEPPCmdKey_Seek = @"Seek";
NSString * const kBDLEPPCmdKey_PlayDramaId = @"PlayDramaId";
NSString * const kBDLEPPCmdKey_AddDramaList = @"AddDramaList";
NSString * const kBDLEPPCmdKey_ClearDramaList = @"ClearDramaList";
NSString * const kBDLEPPCmdKey_DeleteDramaList = @"DeleteDramaList";
NSString * const kBDLEPPCmdKey_PlayPreDrama = @"PlayPreDrama";
NSString * const kBDLEPPCmdKey_PlayNextDrama = @"PlayNextDrama";
NSString * const kBDLEPPCmdKey_GetVolume = @"GetVolume";
NSString * const kBDLEPPCmdKey_SetVolume = @"SetVolume";
NSString * const kBDLEPPCmdKey_AddVolume = @"AddVolume";
NSString * const kBDLEPPCmdKey_SubVolume = @"SubVolume";
NSString * const kBDLEPPCmdKey_PushMediaInfo = @"PushMediaInfo";
NSString * const kBDLEPPCmdKey_PushStatusInfo = @"PushStatusInfo";
NSString * const kBDLEPPCmdKey_PushRuntimeInfo = @"PushRuntimeInfo";

NSString * const kBDLEPPPlayStatus_NO_MEDIA_PRESENT = @"NO_MEDIA_PRESENT";
NSString * const kBDLEPPPlayStatus_LOADING = @"LOADING";
NSString * const kBDLEPPPlayStatus_PLAYING = @"PLAYING";
NSString * const kBDLEPPPlayStatus_PAUSED_PLAYBACK = @"PAUSED_PLAYBACK";
NSString * const kBDLEPPPlayStatus_STOPPED = @"STOPPED";
NSString * const kBDLEPPPlayStatus_COMPLETED = @"COMPLETED";
NSString * const kBDLEPPPlayStatus_TRANSITIONING = @"TRANSITIONING";
NSString * const kBDLEPPPlayStatus_WAITFORPURCHASING = @"WAITFORPURCHASING";
NSString * const kBDLEPPPlayStatus_ADS = @"ADS";


static NSDictionary *_requestClassMap;
static NSDictionary *_responseClassMap;


// api

@implementation BDLEPPPlayControlInfo

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"danmaku": BDLEPPDanmakuBean.class
    };
}

@end

@implementation BDLEPPStatusInfo

@end

@implementation BDLEPPMediaInfo

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"dramaBeans": BDLEPPDramaBean.class,
        @"danmaku": BDLEPPDanmakuBean.class,
        @"subtitle": BDLEPPSubtitleBean.class
    };
}

@end

@implementation BDLEPPRuntimeInfo

@end

@implementation BDLEPPBaseCmd

+ (NSDictionary *)requestClassMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _requestClassMap = @{
            kBDLEPPCmdKey_GetDeviceInfo: BDLEPPGetDeviceInfoRequest.class,
            kBDLEPPCmdKey_GetMediaInfo: BDLEPPGetMediaInfoRequest.class,
            kBDLEPPCmdKey_GetStatusInfo: BDLEPPGetStatusInfoRequest.class,
            kBDLEPPCmdKey_SetLoopMode: BDLEPPSetLoopModeRequest.class,
            kBDLEPPCmdKey_SetSpeed: BDLEPPSetSpeedRequest.class,
            kBDLEPPCmdKey_SetDanmaku: BDLEPPSetDanmakuRequest.class,
            kBDLEPPCmdKey_SetSubtitle: BDLEPPSetSubtitleRequest.class,
            kBDLEPPCmdKey_SetStretchMode: BDLEPPSetStretchModeRequest.class,
            kBDLEPPCmdKey_SetSkipInfo: BDLEPPSetSkipInfoRequest.class,
            kBDLEPPCmdKey_SetResolution: BDLEPPSetResolutionRequest.class,
            kBDLEPPCmdKey_Play: BDLEPPPlayRequest.class,
            kBDLEPPCmdKey_Pause: BDLEPPPauseRequest.class,
            kBDLEPPCmdKey_Resume: BDLEPPResumeRequest.class,
            kBDLEPPCmdKey_Stop: BDLEPPStopRequest.class,
            kBDLEPPCmdKey_Seek: BDLEPPSeekRequest.class,
            kBDLEPPCmdKey_PlayDramaId: BDLEPPPlayDramaIdRequest.class,
            kBDLEPPCmdKey_AddDramaList: BDLEPPAddDramaListRequest.class,
            kBDLEPPCmdKey_ClearDramaList: BDLEPPClearDramaListRequest.class,
            kBDLEPPCmdKey_PlayPreDrama: BDLEPPPlayPreDramaRequest.class,
            kBDLEPPCmdKey_PlayNextDrama: BDLEPPPlayNextDramaRequest.class,
            kBDLEPPCmdKey_GetVolume: BDLEPPGetVolumeRequest.class,
            kBDLEPPCmdKey_SetVolume: BDLEPPSetVolumeRequest.class,
            kBDLEPPCmdKey_AddVolume: BDLEPPAddVolumeRequest.class,
            kBDLEPPCmdKey_SubVolume: BDLEPPSubVolumeRequest.class,
            kBDLEPPCmdKey_PushMediaInfo: BDLEPPPushMediaInfoRequest.class,
            kBDLEPPCmdKey_PushStatusInfo: BDLEPPPushStatusInfoRequest.class,
            kBDLEPPCmdKey_PushRuntimeInfo: BDLEPPPushRuntimeInfoRequest.class
        };
    });
    
    return _requestClassMap;
}
    
+ (NSDictionary *)responseClassMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _responseClassMap = @{
            kBDLEPPCmdKey_GetDeviceInfo: BDLEPPGetDeviceInfoResponse.class,
            kBDLEPPCmdKey_GetMediaInfo: BDLEPPGetMediaInfoResponse.class,
            kBDLEPPCmdKey_GetStatusInfo: BDLEPPGetStatusInfoResponse.class,
            kBDLEPPCmdKey_SetLoopMode: BDLEPPSetLoopModeResponse.class,
            kBDLEPPCmdKey_SetSpeed: BDLEPPSetSpeedResponse.class,
            kBDLEPPCmdKey_SetDanmaku: BDLEPPSetDanmakuResponse.class,
            kBDLEPPCmdKey_SetSubtitle: BDLEPPSetSubtitleResponse.class,
            kBDLEPPCmdKey_SetStretchMode: BDLEPPSetStretchModeResponse.class,
            kBDLEPPCmdKey_SetSkipInfo: BDLEPPSetSkipInfoResponse.class,
            kBDLEPPCmdKey_SetResolution: BDLEPPSetResolutionResponse.class,
            kBDLEPPCmdKey_Play: BDLEPPPlayResponse.class,
            kBDLEPPCmdKey_Pause: BDLEPPPauseResponse.class,
            kBDLEPPCmdKey_Resume: BDLEPPResumeResponse.class,
            kBDLEPPCmdKey_Stop: BDLEPPStopResponse.class,
            kBDLEPPCmdKey_Seek: BDLEPPSeekResponse.class,
            kBDLEPPCmdKey_PlayDramaId: BDLEPPPlayDramaIdResponse.class,
            kBDLEPPCmdKey_AddDramaList: BDLEPPAddDramaListResponse.class,
            kBDLEPPCmdKey_ClearDramaList: BDLEPPClearDramaListResponse.class,
            kBDLEPPCmdKey_PlayPreDrama: BDLEPPPlayPreDramaResponse.class,
            kBDLEPPCmdKey_PlayNextDrama: BDLEPPPlayNextDramaResponse.class,
            kBDLEPPCmdKey_GetVolume: BDLEPPGetVolumeResponse.class,
            kBDLEPPCmdKey_SetVolume: BDLEPPSetVolumeResponse.class,
            kBDLEPPCmdKey_AddVolume: BDLEPPAddVolumeResponse.class,
            kBDLEPPCmdKey_SubVolume: BDLEPPSubVolumeResponse.class,
            kBDLEPPCmdKey_PushMediaInfo: BDLEPPPushMediaInfoResponse.class,
            kBDLEPPCmdKey_PushStatusInfo: BDLEPPPushStatusInfoResponse.class,
            kBDLEPPCmdKey_PushRuntimeInfo: BDLEPPPushRuntimeInfoResponse.class
        };
    });
    
    return _responseClassMap;
}

- (NSString *)jsonString {
    return [self yy_modelToJSONString];
}

+ (instancetype)modelWithJSON:(id)json {
    return [self yy_modelWithJSON:json];
}

@end
        
@implementation BDLEPPDramaBean

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"urlBeans": BDLEPPUrlBean.class
    };
}

@end
        
@implementation BDLEPPUrlBean

@end
        
@implementation BDLEPPDanmakuBean

@end

@implementation BDLEPPSubtitleBean

@end

@implementation BDLEPPSkipInfoBean

@end
        
@implementation BDLEPPMediaAssetBean

@end



@implementation BDLEPPEncryptResponse

@end
        
@implementation BDLEPPBaseCmdResponse

@end
        
@implementation BDLEPPCmd

+ (instancetype)cmd {
    BDLEPPCmd *cmd = [self new];
    
    return cmd;
}

@end

// cmd

@implementation BDLEPPAddDramaListCmd

+ (instancetype)cmd {
    BDLEPPAddDramaListCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_AddDramaList;
    
    return cmd;
}

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"dramaBeans": BDLEPPDramaBean.class
    };
}

@end
        
@implementation BDLEPPSpeedCmd

+ (instancetype)cmd {
    BDLEPPSpeedCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetSpeed;
    
    return cmd;
}

@end
        
@implementation BDLEPPPlayDramaIdCmd

+ (instancetype)cmd {
    BDLEPPPlayDramaIdCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_PlayDramaId;
    
    return cmd;
}

@end
        
@implementation BDLEPPResolutionCmd

+ (instancetype)cmd {
    BDLEPPResolutionCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetResolution;
    
    return cmd;
}

@end
        
@implementation BDLEPPGetVolumeCmd

+ (instancetype)cmd {
    BDLEPPGetVolumeCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_GetVolume;
    
    return cmd;
}

@end
        
@implementation BDLEPPGetMediaInfoCmd

+ (instancetype)cmd {
    BDLEPPGetMediaInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_GetMediaInfo;
    
    return cmd;
}

@end
        
@implementation BDLEPPSetVolumeCmd

+ (instancetype)cmd {
    BDLEPPSetVolumeCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetVolume;
    
    return cmd;
}

@end
        
@implementation BDLEPPGetStatusInfoCmd

+ (instancetype)cmd {
    BDLEPPGetStatusInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_GetStatusInfo;
    
    return cmd;
}

@end
        
@implementation BDLEPPPlayCmd

+ (instancetype)cmd {
    BDLEPPPlayCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_Play;
    
    return cmd;
}

@end
        
@implementation BDLEPPLoopModeCmd

+ (instancetype)cmd {
    BDLEPPLoopModeCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetLoopMode;
    
    return cmd;
}

@end
        
@implementation BDLEPPGetDeviceInfoCmd

+ (instancetype)cmd {
    BDLEPPGetDeviceInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_GetDeviceInfo;
    
    return cmd;
}

@end
        
@implementation BDLEPPSeekCmd

+ (instancetype)cmd {
    BDLEPPSeekCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_Seek;
    
    return cmd;
}

@end
        
@implementation BDLEPPPushStatusInfoCmd

+ (instancetype)cmd {
    BDLEPPPushStatusInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_PushStatusInfo;
    
    return cmd;
}

@end
        
@implementation BDLEPPDanmakuCmd

+ (instancetype)cmd {
    BDLEPPDanmakuCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetDanmaku;
    
    return cmd;
}

@end

@implementation BDLEPPSubtitleCmd

+ (instancetype)cmd {
    BDLEPPSubtitleCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetSubtitle;

    return cmd;
}

@end

@implementation BDLEPPStretchModeCmd

+ (instancetype)cmd {
    BDLEPPStretchModeCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetStretchMode;

    return cmd;
}

@end

@implementation BDLEPPSkipInfoCmd

+ (instancetype)cmd {
    BDLEPPSkipInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_SetSkipInfo;

    return cmd;
}

@end

@implementation BDLEPPDeleteDramaListCmd

+ (instancetype)cmd {
    BDLEPPDeleteDramaListCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_DeleteDramaList;
    
    return cmd;
}

@end
        
@implementation BDLEPPPushMediaInfoCmd

+ (instancetype)cmd {
    BDLEPPPushMediaInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_PushMediaInfo;
    
    return cmd;
}

@end

@implementation BDLEPPPushRuntimeInfoCmd

+ (instancetype)cmd {
    BDLEPPPushRuntimeInfoCmd *cmd = [super cmd];
    cmd.cmd = kBDLEPPCmdKey_PushRuntimeInfo;

    return cmd;
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"error" : BDLEPPRuntimeInfo.class
    };
}

@end

// request

@implementation BDLEPPPlayDramaIdRequest

+ (instancetype)requestWithBody:(BDLEPPPlayDramaIdCmd *)body {
    BDLEPPPlayDramaIdRequest *request = [BDLEPPPlayDramaIdRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPSetSpeedRequest

+ (instancetype)requestWithBody:(BDLEPPSpeedCmd *)body {
    BDLEPPSetSpeedRequest *request = [BDLEPPSetSpeedRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPPlayPreDramaRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_PlayPreDrama; 

    BDLEPPPlayPreDramaRequest *request = [BDLEPPPlayPreDramaRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPAddVolumeRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_AddVolume; 

    BDLEPPAddVolumeRequest *request = [BDLEPPAddVolumeRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPSeekRequest

+ (instancetype)requestWithBody:(BDLEPPSeekCmd *)body {
    BDLEPPSeekRequest *request = [BDLEPPSeekRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPSubVolumeRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_SubVolume; 

    BDLEPPSubVolumeRequest *request = [BDLEPPSubVolumeRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPGetVolumeRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_GetVolume; 

    BDLEPPGetVolumeRequest *request = [BDLEPPGetVolumeRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPPushMediaInfoRequest

+ (instancetype)requestWithBody:(BDLEPPPushMediaInfoCmd *)body {
    BDLEPPPushMediaInfoRequest *request = [BDLEPPPushMediaInfoRequest new];
    request.body = body;
    
    return request;
}

- (BDLEPPPushMediaInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPPushMediaInfoCmd.class]) {
        return (BDLEPPPushMediaInfoCmd *)[super body];
    } else {
        BDLEPPPushMediaInfoCmd *newBody = [BDLEPPPushMediaInfoCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPPushMediaInfoCmd *cmd = [BDLEPPPushMediaInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end

@implementation BDLEPPPushRuntimeInfoRequest

+ (instancetype)requestWithBody:(BDLEPPPushRuntimeInfoCmd *)body {
    BDLEPPPushRuntimeInfoRequest *request = [BDLEPPPushRuntimeInfoRequest new];
    request.body = body;

    return request;
}

- (BDLEPPPushRuntimeInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPPushRuntimeInfoCmd.class]) {
        return (BDLEPPPushRuntimeInfoCmd *)[super body];
    } else {
        BDLEPPPushRuntimeInfoCmd *newBody = [BDLEPPPushRuntimeInfoCmd cmd];
        newBody.cmd = body.cmd;

        return newBody;
    }

    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPPushRuntimeInfoCmd *cmd = [BDLEPPPushRuntimeInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;

    return YES;
}

@end

@implementation BDLEPPResumeRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_Resume; 

    BDLEPPResumeRequest *request = [BDLEPPResumeRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPPlayRequest

+ (instancetype)requestWithBody:(BDLEPPPlayCmd *)body {
    BDLEPPPlayRequest *request = [BDLEPPPlayRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPSetVolumeRequest

+ (instancetype)requestWithBody:(BDLEPPSetVolumeCmd *)body {
    BDLEPPSetVolumeRequest *request = [BDLEPPSetVolumeRequest new];
    request.body = body;
    
    return request;
}

@end


@implementation BDLEPPClearDramaListRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_ClearDramaList;
    
    BDLEPPClearDramaListRequest *request = [BDLEPPClearDramaListRequest new];
    request.body = body;
    
    return request;
}
    
@end

        
@implementation BDLEPPDeleteDramaListRequest

+ (instancetype)requestWithBody:(BDLEPPDeleteDramaListCmd *)body {
    BDLEPPDeleteDramaListRequest *request = [BDLEPPDeleteDramaListRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPSetDanmakuRequest

+ (instancetype)requestWithBody:(BDLEPPDanmakuCmd *)body {
    BDLEPPSetDanmakuRequest *request = [BDLEPPSetDanmakuRequest new];
    request.body = body;
    
    return request;
}

@end

@implementation BDLEPPSetSubtitleRequest

+ (instancetype)requestWithBody:(BDLEPPSubtitleCmd *)body {
    BDLEPPSetSubtitleRequest *request = [BDLEPPSetSubtitleRequest new];
    request.body = body;

    return request;
}

@end

@implementation BDLEPPSetStretchModeRequest

+ (instancetype)requestWithBody:(BDLEPPStretchModeCmd *)body {
    BDLEPPSetStretchModeRequest *request = [BDLEPPSetStretchModeRequest new];
    request.body = body;

    return request;
}

@end

@implementation BDLEPPSetSkipInfoRequest

+ (instancetype)requestWithBody:(BDLEPPSkipInfoCmd *)body {
    BDLEPPSetSkipInfoRequest *request = [BDLEPPSetSkipInfoRequest new];
    request.body = body;

    return request;
}

@end

@implementation BDLEPPGetStatusInfoRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_GetStatusInfo; 

    BDLEPPGetStatusInfoRequest *request = [BDLEPPGetStatusInfoRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPSetLoopModeRequest

+ (instancetype)requestWithBody:(BDLEPPLoopModeCmd *)body {
    BDLEPPSetLoopModeRequest *request = [BDLEPPSetLoopModeRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPPlayNextDramaRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_PlayNextDrama; 

    BDLEPPPlayNextDramaRequest *request = [BDLEPPPlayNextDramaRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPGetMediaInfoRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_GetMediaInfo; 

    BDLEPPGetMediaInfoRequest *request = [BDLEPPGetMediaInfoRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPPauseRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_Pause; 

    BDLEPPPauseRequest *request = [BDLEPPPauseRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPStopRequest

+ (instancetype)request {
    BDLEPPCmd *body = [BDLEPPCmd new];
    body.cmd = kBDLEPPCmdKey_Stop; 

    BDLEPPStopRequest *request = [BDLEPPStopRequest new];
    request.body = body;
    
    return request;
}
    
@end
        
@implementation BDLEPPPushStatusInfoRequest

+ (instancetype)requestWithBody:(BDLEPPPushStatusInfoCmd *)body {
    BDLEPPPushStatusInfoRequest *request = [BDLEPPPushStatusInfoRequest new];
    request.body = body;
    
    return request;
}

- (BDLEPPPushStatusInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPPushStatusInfoCmd.class]) {
        return (BDLEPPPushStatusInfoCmd *)[super body];
    } else {
        BDLEPPPushStatusInfoCmd *newBody = [BDLEPPPushStatusInfoCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPPushStatusInfoCmd *cmd = [BDLEPPPushStatusInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end
        
@implementation BDLEPPSetResolutionRequest

+ (instancetype)requestWithBody:(BDLEPPResolutionCmd *)body {
    BDLEPPSetResolutionRequest *request = [BDLEPPSetResolutionRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPGetDeviceInfoRequest

+ (instancetype)requestWithBody:(BDLEPPGetDeviceInfoCmd *)body {
    BDLEPPGetDeviceInfoRequest *request = [BDLEPPGetDeviceInfoRequest new];
    request.body = body;
    
    return request;
}

@end
        
@implementation BDLEPPAddDramaListRequest

+ (instancetype)requestWithBody:(BDLEPPAddDramaListCmd *)body {
    BDLEPPAddDramaListRequest *request = [BDLEPPAddDramaListRequest new];
    request.body = body;
    
    return request;
}

@end
        

// response

@implementation BDLEPPPauseResponse

@end
        
@implementation BDLEPPGetMediaInfoResponse

- (BDLEPPGetMediaInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPGetMediaInfoCmd.class]) {
        return (BDLEPPGetMediaInfoCmd *)[super body];
    } else {
        BDLEPPGetMediaInfoCmd *newBody = [BDLEPPGetMediaInfoCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPGetMediaInfoCmd *cmd = [BDLEPPGetMediaInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end
        
@implementation BDLEPPPlayDramaIdResponse

@end
        
@implementation BDLEPPPlayResponse

@end
        
@implementation BDLEPPSubVolumeResponse

@end
        
@implementation BDLEPPGetStatusInfoResponse

- (BDLEPPGetStatusInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPGetStatusInfoCmd.class]) {
        return (BDLEPPGetStatusInfoCmd *)[super body];
    } else {
        BDLEPPGetStatusInfoCmd *newBody = [BDLEPPGetStatusInfoCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPGetStatusInfoCmd *cmd = [BDLEPPGetStatusInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end
        
@implementation BDLEPPPushStatusInfoResponse

- (BDLEPPCmd *)body {
    BDLEPPCmd *cmd = [BDLEPPCmd cmd];
    cmd.cmd = @"PushStatusInfo";
    
    return cmd;
}

@end
        
@implementation BDLEPPPushMediaInfoResponse

- (BDLEPPCmd *)body {
    BDLEPPCmd *cmd = [BDLEPPCmd cmd];
    cmd.cmd = @"PushMediaInfo";
    
    return cmd;
}

@end

@implementation BDLEPPPushRuntimeInfoResponse

- (BDLEPPCmd *)body {
    BDLEPPCmd *cmd = [BDLEPPCmd cmd];
    cmd.cmd = @"PushRuntimeInfo";

    return cmd;
}

@end

@implementation BDLEPPClearDramaListResponse

@end
        
@implementation BDLEPPAddDramaListResponse

@end
        
@implementation BDLEPPSetResolutionResponse

@end
        
@implementation BDLEPPSetSpeedResponse

@end
        
@implementation BDLEPPAddVolumeResponse

@end
        
@implementation BDLEPPPlayPreDramaResponse

@end
        
@implementation BDLEPPSetDanmakuResponse

@end

@implementation BDLEPPSetSubtitleResponse

@end

@implementation BDLEPPSetStretchModeResponse

@end

@implementation BDLEPPSetSkipInfoResponse

@end

@implementation BDLEPPPlayNextDramaResponse

@end
        
@implementation BDLEPPSetVolumeResponse

@end
        
@implementation BDLEPPSetLoopModeResponse

@end
        
@implementation BDLEPPSeekResponse

@end
        
@implementation BDLEPPResumeResponse

@end
        
@implementation BDLEPPStopResponse

@end
        
@implementation BDLEPPGetDeviceInfoResponse

- (BDLEPPGetDeviceInfoCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPGetDeviceInfoCmd.class]) {
        return (BDLEPPGetDeviceInfoCmd *)[super body];
    } else {
        BDLEPPGetDeviceInfoCmd *newBody = [BDLEPPGetDeviceInfoCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPGetDeviceInfoCmd *cmd = [BDLEPPGetDeviceInfoCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end
        
@implementation BDLEPPGetVolumeResponse

- (BDLEPPGetVolumeCmd *)body {
    BDLEPPCmd *body = [super body];
    if ([body isKindOfClass:BDLEPPGetVolumeCmd.class]) {
        return (BDLEPPGetVolumeCmd *)[super body];
    } else {
        BDLEPPGetVolumeCmd *newBody = [BDLEPPGetVolumeCmd cmd];
        newBody.cmd = body.cmd;
        
        return newBody;
    }
    
    return nil;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    BDLEPPGetVolumeCmd *cmd = [BDLEPPGetVolumeCmd yy_modelWithDictionary:dict[@"body"]];
    self.body = cmd;
    
    return YES;
}
    
@end
        
