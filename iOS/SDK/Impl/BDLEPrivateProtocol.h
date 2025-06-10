//
//  BDLEPrivateProtocol.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BDLEPPDeviceBitmapFlag) {
    BDLEPPDeviceBitmapFlagNone            = 0,
    BDLEPPDeviceBitmapFlagEncrypt         = 1 << 0,
    BDLEPPDeviceBitmapFlagStretch         = 1 << 1,
    BDLEPPDeviceBitmapFlagSpeed           = 1 << 2,
    BDLEPPDeviceBitmapFlagDanmaku         = 1 << 3,
    BDLEPPDeviceBitmapFlag4K              = 1 << 4,
    BDLEPPDeviceBitmapFlagH265            = 1 << 5,
    BDLEPPDeviceBitmapFlagHttps           = 1 << 6,
    BDLEPPDeviceBitmapFlagHighFps         = 1 << 7,
    BDLEPPDeviceBitmapFlagAreaStretch     = 1 << 8,
    BDLEPPDeviceBitmapFlagAutoResolution  = 1 << 9,
    BDLEPPDeviceBitmapFlagCENC            = 1 << 12,
};

// api
@class BDLEPPStatusInfo;
@class BDLEPPBaseCmd;
@class BDLEPPDramaBean;
@class BDLEPPUrlBean;
@class BDLEPPDanmakuBean;
@class BDLEPPSubtitleBean;
@class BDLEPPMediaAssetBean;
@class BDLEPPBaseCmdResponse;
@class BDLEPPCmd;
@class BDLEPPMediaInfo;
@class BDLESourceDeviceInfo;


// cmd
@class BDLEPPAddDramaListCmd;
@class BDLEPPSpeedCmd;
@class BDLEPPPlayDramaIdCmd;
@class BDLEPPResolutionCmd;
@class BDLEPPGetVolumeCmd;
@class BDLEPPGetMediaInfoCmd;
@class BDLEPPSetVolumeCmd;
@class BDLEPPGetStatusInfoCmd;
@class BDLEPPPlayCmd;
@class BDLEPPLoopModeCmd;
@class BDLEPPGetDeviceInfoCmd;
@class BDLEPPSeekCmd;
@class BDLEPPPushStatusInfoCmd;
@class BDLEPPDanmakuCmd;
@class BDLEPPSubtitleCmd;
@class BDLEPPStretchModeCmd;
@class BDLEPPSkipInfoCmd;
@class BDLEPPDeleteDramaListCmd;
@class BDLEPPPushMediaInfoCmd;
@class BDLEPPPushRuntimeInfoCmd;


// request
@class BDLEPPPlayDramaIdRequest;
@class BDLEPPSetSpeedRequest;
@class BDLEPPPlayPreDramaRequest;
@class BDLEPPAddVolumeRequest;
@class BDLEPPSeekRequest;
@class BDLEPPSubVolumeRequest;
@class BDLEPPGetVolumeRequest;
@class BDLEPPPushMediaInfoRequest;
@class BDLEPPPushRuntimeInfoRequest;
@class BDLEPPResumeRequest;
@class BDLEPPPlayRequest;
@class BDLEPPSetVolumeRequest;
@class BDLEPPClearDramaListRequest;
@class BDLEPPSetDanmakuRequest;
@class BDLEPPSetSubtitleRequest;
@class BDLEPPSetStretchModeRequest;
@class BDLEPPSetSkipInfoRequest;
@class BDLEPPGetStatusInfoRequest;
@class BDLEPPSetLoopModeRequest;
@class BDLEPPPlayNextDramaRequest;
@class BDLEPPGetMediaInfoRequest;
@class BDLEPPPauseRequest;
@class BDLEPPStopRequest;
@class BDLEPPPushStatusInfoRequest;
@class BDLEPPSetResolutionRequest;
@class BDLEPPGetDeviceInfoRequest;
@class BDLEPPAddDramaListRequest;


// response
@class BDLEPPPauseResponse;
@class BDLEPPGetMediaInfoResponse;
@class BDLEPPPlayDramaIdResponse;
@class BDLEPPPlayResponse;
@class BDLEPPSubVolumeResponse;
@class BDLEPPGetStatusInfoResponse;
@class BDLEPPPushStatusInfoResponse;
@class BDLEPPPushMediaInfoResponse;
@class BDLEPPPushRuntimeInfoResponse;
@class BDLEPPClearDramaListResponse;
@class BDLEPPAddDramaListResponse;
@class BDLEPPSetResolutionResponse;
@class BDLEPPSetSpeedResponse;
@class BDLEPPAddVolumeResponse;
@class BDLEPPPlayPreDramaResponse;
@class BDLEPPSetDanmakuResponse;
@class BDLEPPSetSubtitleResponse;
@class BDLEPPSetStretchModeResponse;
@class BDLEPPSetSkipInfoResponse;
@class BDLEPPPlayNextDramaResponse;
@class BDLEPPSetVolumeResponse;
@class BDLEPPSetLoopModeResponse;
@class BDLEPPSeekResponse;
@class BDLEPPResumeResponse;
@class BDLEPPStopResponse;
@class BDLEPPGetDeviceInfoResponse;
@class BDLEPPGetVolumeResponse;


FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_GetDeviceInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_GetMediaInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_GetStatusInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetLoopMode;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetSpeed;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetDanmaku;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetSubtitle;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetStretchMode;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetSkipInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetResolution;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_Play;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_Pause;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_Resume;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_Stop;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_Seek;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PlayDramaId;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_AddDramaList;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_ClearDramaList;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PlayPreDrama;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PlayNextDrama;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_GetVolume;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SetVolume;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_AddVolume;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_SubVolume;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PushMediaInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PushStatusInfo;
FOUNDATION_EXTERN NSString * const kBDLEPPCmdKey_PushRuntimeInfo;

FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_NO_MEDIA_PRESENT;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_LOADING;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_PLAYING;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_PAUSED_PLAYBACK;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_STOPPED;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_COMPLETED;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_TRANSITIONING;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_WAITFORPURCHASING;
FOUNDATION_EXTERN NSString * const kBDLEPPPlayStatus_ADS;

// api

@interface BDLEPPPlayControlInfo : NSObject

@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) NSInteger loopMode;
@property (nonatomic, assign) NSInteger shuffle;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) NSInteger stretch;
@property (nonatomic, assign) NSInteger skip;
@property (nonatomic, assign) NSInteger inheritConfig;
@property (nonatomic, assign) NSInteger featureConfig;
@property (nonatomic, strong) BDLEPPDanmakuBean *danmaku;

@end

@interface BDLEPPStatusInfo : NSObject 

@property (nonatomic, copy) NSString *status;
@property (nonatomic, assign) int64_t duration;
@property (nonatomic, assign) int64_t position;
@property (nonatomic, assign) float speed;

@end

@interface BDLEPPMediaInfo : NSObject

@property (nonatomic, copy) NSString *vid;
@property (nonatomic, copy) NSString *dramaId;
@property (nonatomic, copy) NSArray<BDLEPPDramaBean *> *dramaBeans;
@property (nonatomic, assign) NSInteger loopMode;
@property (nonatomic, assign) NSInteger shuffle;
@property (nonatomic, assign) float speed;
@property (nonatomic, strong) BDLEPPDanmakuBean *danmaku;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, assign) NSInteger resolutionMode;
@property (nonatomic, assign) NSInteger stretch;
@property (nonatomic, strong) BDLEPPSubtitleBean *subtitle;
@property (nonatomic, assign) NSInteger skip;
@property (nonatomic, copy) NSArray *speeds;

@end


@interface BDLEPPRuntimeInfo : NSObject

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *messageId;

@end


@interface BDLEPPBaseCmd : NSObject

@property (nonatomic, assign) NSInteger version;
@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, copy) NSString *connectId;
@property (nonatomic, strong) BDLEPPCmd *body;


@property (class, nonatomic, copy, readonly) NSDictionary *requestClassMap;
@property (class, nonatomic, copy, readonly) NSDictionary *responseClassMap;

- (nullable NSString *)jsonString;
+ (nullable instancetype)modelWithJSON:(id)json;

@end


@interface BDLEPPDramaBean : NSObject 

@property (nonatomic, copy) NSString *dramaId;
@property (nonatomic, copy) NSArray<BDLEPPUrlBean *> *urlBeans;
@property (nonatomic, strong) BDLEPPMediaAssetBean *mediaAssetBean;

@end


@interface BDLEPPUrlBean : NSObject 

@property (nonatomic, copy) NSString *urlType;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, assign) NSInteger bitrate;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, copy) NSString *extra;

@end


@interface BDLEPPDanmakuBean : NSObject 

@property (nonatomic, assign) NSInteger switchStatus;
@property (nonatomic, assign) NSInteger area;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) float alpha;
@property (nonatomic, assign) float speed;

@end

@interface BDLEPPSubtitleBean : NSObject

@property (nonatomic, assign) NSInteger switchStatus;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *startTime;

@end

@interface BDLEPPSkipInfoBean : NSObject

// 单位ms，跳过片头（可选）
@property (nonatomic, copy) NSArray<NSString *> *skipHead;

// 单位ms，跳过片尾（可选），skipTail[1] == "-1"代表视频结尾，例如："skipTail":["567000","-1"]
@property (nonatomic, copy) NSArray<NSString *> *skipTail;

@end

@interface BDLEPPMediaAssetBean : NSObject 

@property (nonatomic, copy) NSString *vid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *creator;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *album;
@property (nonatomic, copy) NSString *albumArtUrl;
@property (nonatomic, copy) NSString *danmakuUrl;
@property (nonatomic, copy) NSString *lyrics;
@property (nonatomic, assign) int64_t duration;
@property (nonatomic, assign) BOOL isLike;
@property (nonatomic, assign) NSInteger diggCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, copy) NSString *codec;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, assign) NSInteger mediaType;
@property (nonatomic, assign) int64_t startPosition;
@property (nonatomic, copy) NSString *extra;
@property (nonatomic, copy) NSString *publisher;
@property (nonatomic, copy) NSString *customDlnaXmlElement;
@property (nonatomic, assign) NSInteger oversea;
@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, copy) NSArray<NSString *> *audioTrackList;
@property (nonatomic, assign) NSInteger audioTrack;
@property (nonatomic, copy) NSString *agentType;
@property (nonatomic, copy) NSString *cencKey;
@property (nonatomic, strong) BDLEPPSubtitleBean *subtitle;
@property (nonatomic, strong) BDLEPPSkipInfoBean *skipInfo;
@property (nonatomic, strong) id ads;

@end


@interface BDLEPPEncryptResponse : NSObject

@property (nonatomic, strong) NSNumber *encrypt;
@property (nonatomic, strong) id content;

@end


@interface BDLEPPBaseCmdResponse : BDLEPPBaseCmd 

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy) NSString *msg;

@end


// cmd
@interface BDLEPPCmd : NSObject

@property (nonatomic, copy) NSString *cmd;

+ (instancetype)cmd;

@end


@interface BDLEPPAddDramaListCmd : BDLEPPCmd

@property (nonatomic, copy) NSArray<BDLEPPDramaBean *> *dramaBeans;
@property (nonatomic, copy) NSString *insertBeforeDramaId;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPSpeedCmd : BDLEPPCmd 

@property (nonatomic, assign) float speed;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPPlayDramaIdCmd : BDLEPPCmd 

@property (nonatomic, copy) NSString *connectId;
@property (nonatomic, copy) NSString *startDramaId;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPResolutionCmd : BDLEPPCmd 

// online/local
@property (nonatomic, copy) NSString *urlType;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) NSInteger resolutionMode;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPGetVolumeCmd : BDLEPPCmd 

@property (nonatomic, assign) NSInteger volume;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPGetMediaInfoCmd : BDLEPPCmd 

@property (nonatomic, strong) BDLEPPMediaInfo *mediaInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPSetVolumeCmd : BDLEPPCmd 

@property (nonatomic, assign) NSInteger volume;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPGetStatusInfoCmd : BDLEPPCmd 

@property (nonatomic, strong) BDLEPPStatusInfo *statusInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPPlayCmd : BDLEPPCmd 

@property (nonatomic, copy) NSString *connectId;
@property (nonatomic, copy) NSString *startDramaId;
@property (nonatomic, copy) NSArray<BDLEPPDramaBean *> *dramaBeans;
@property (nonatomic, strong) BDLEPPPlayControlInfo *playControlInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPLoopModeCmd : BDLEPPCmd 

@property (nonatomic, assign) NSInteger loopMode;
@property (nonatomic, assign) NSInteger shuffle;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPGetDeviceInfoCmd : BDLEPPCmd 

@property (nonatomic, strong) NSDictionary *deviceInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPSeekCmd : BDLEPPCmd 

@property (nonatomic, assign) int64_t position;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPPushStatusInfoCmd : BDLEPPCmd 

@property (nonatomic, strong) BDLEPPStatusInfo *statusInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPDanmakuCmd : BDLEPPCmd 

@property (nonatomic, strong) BDLEPPDanmakuBean *danmaku;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPSubtitleCmd : BDLEPPCmd

@property (nonatomic, strong) BDLEPPSubtitleBean *subtitle;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPStretchModeCmd : BDLEPPCmd

@property (nonatomic, assign) NSInteger stretch;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPSkipInfoCmd : BDLEPPCmd

@property (nonatomic, assign) NSInteger skip;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPPushMediaInfoCmd : BDLEPPCmd 

@property (nonatomic, strong) BDLEPPMediaInfo *mediaInfo;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPPushRuntimeInfoCmd : BDLEPPCmd

@property (nonatomic, strong) BDLEPPRuntimeInfo *error;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end


@interface BDLEPPDeleteDramaListCmd : BDLEPPCmd

@property (nonatomic, copy) NSArray<NSString *> *dramaIds;

- (instancetype)init __attribute__((unavailable("use +cmd instead")));

@end



// request

@interface BDLEPPPlayDramaIdRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPPlayDramaIdCmd *)body;

@end


@interface BDLEPPSetSpeedRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPSpeedCmd *)body;

@end


@interface BDLEPPPlayPreDramaRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPAddVolumeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPSeekRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPSeekCmd *)body;

@end


@interface BDLEPPSubVolumeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPGetVolumeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPPushMediaInfoRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPPushMediaInfoCmd *)body;

- (BDLEPPPushMediaInfoCmd *)body;

@end


@interface BDLEPPPushRuntimeInfoRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPPushRuntimeInfoCmd *)body;

- (BDLEPPPushRuntimeInfoCmd *)body;

@end


@interface BDLEPPResumeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPPlayRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPPlayCmd *)body;

@end


@interface BDLEPPSetVolumeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPSetVolumeCmd *)body;

@end


@interface BDLEPPClearDramaListRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPDeleteDramaListRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPDeleteDramaListCmd *)body;

@end


@interface BDLEPPSetDanmakuRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPDanmakuCmd *)body;

@end


@interface BDLEPPSetSubtitleRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPSubtitleCmd *)body;

@end


@interface BDLEPPSetStretchModeRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPStretchModeCmd *)body;

@end


@interface BDLEPPSetSkipInfoRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPSkipInfoCmd *)body;

@end


@interface BDLEPPGetStatusInfoRequest : BDLEPPBaseCmd

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPSetLoopModeRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPLoopModeCmd *)body;

@end


@interface BDLEPPPlayNextDramaRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPGetMediaInfoRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPPauseRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPStopRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)request;

@end


@interface BDLEPPPushStatusInfoRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPPushStatusInfoCmd *)body;

- (BDLEPPPushStatusInfoCmd *)body;

@end


@interface BDLEPPSetResolutionRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPResolutionCmd *)body;

@end


@interface BDLEPPGetDeviceInfoRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPGetDeviceInfoCmd *)body;

@end


@interface BDLEPPAddDramaListRequest : BDLEPPBaseCmd 

- (instancetype)init __attribute__((unavailable("use +request or +requestWithBody: instead")));
+ (instancetype)requestWithBody:(BDLEPPAddDramaListCmd *)body;

@end



// response

@interface BDLEPPPauseResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPGetMediaInfoResponse : BDLEPPBaseCmdResponse 

- (BDLEPPGetMediaInfoCmd *)body;

@end


@interface BDLEPPPlayDramaIdResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPPlayResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSubVolumeResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPGetStatusInfoResponse : BDLEPPBaseCmdResponse 

- (BDLEPPGetStatusInfoCmd *)body;

@end


@interface BDLEPPPushStatusInfoResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPPushMediaInfoResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPPushRuntimeInfoResponse : BDLEPPBaseCmdResponse


@end


@interface BDLEPPClearDramaListResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPAddDramaListResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetResolutionResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetSpeedResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPAddVolumeResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPPlayPreDramaResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetDanmakuResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetSubtitleResponse : BDLEPPBaseCmdResponse


@end


@interface BDLEPPSetStretchModeResponse : BDLEPPBaseCmdResponse


@end


@interface BDLEPPSetSkipInfoResponse : BDLEPPBaseCmdResponse


@end


@interface BDLEPPPlayNextDramaResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetVolumeResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSetLoopModeResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPSeekResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPResumeResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPStopResponse : BDLEPPBaseCmdResponse 


@end


@interface BDLEPPGetDeviceInfoResponse : BDLEPPBaseCmdResponse 

- (BDLEPPGetDeviceInfoCmd *)body;

@end


@interface BDLEPPGetVolumeResponse : BDLEPPBaseCmdResponse 

- (BDLEPPGetVolumeCmd *)body;

@end

NS_ASSUME_NONNULL_END
