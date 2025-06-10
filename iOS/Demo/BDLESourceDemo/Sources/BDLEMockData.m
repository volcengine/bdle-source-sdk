//
//  BDLEMockData.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEMockData.h"
#import <BDLESource/BDLEUtils.h>

// CC0 Videos
#error Replace This Macro First!
#define MOCK_URL_HOST @"<#place_your_host_here#>"
#define MOCK_URL_1_480P @"bdle_hya_avc_480p_30_500k.mp4"
#define MOCK_URL_1_720P @"bdle_hya_avc_720p_30_1m.mp4"
#define MOCK_URL_1_1080P @"bdle_hya_avc_1080p_30_2m.mp4"

#define MOCK_URL_2_540P @"bdle_vir_avc_540p_60_600k.mp4"
#define MOCK_URL_2_720P @"bdle_vir_avc_720p_60_1m.mp4"
#define MOCK_URL_2_1080P @"bdle_vir_avc_1080p_60_2m.mp4"
#define MOCK_URL_2_2K @"bdle_vir_avc_2k_60_6m.mp4"
#define MOCK_URL_2_4K @"bdle_vir_avc_4k_60_15m.mp4"

#define MOCK_URL_3_720P @"bdle_uma_avc_720p_30_1m.mp4"
#define MOCK_URL_3_1080P @"bdle_uma_avc_1080p_30_2m.mp4"
#define MOCK_URL_3_4K @"bdle_uma_avc_4k_30_10m.mp4"

@implementation BDLEMockData

+ (NSString *)mockUrl:(NSString *)fileName {
    return [NSString stringWithFormat:@"%@%@", MOCK_URL_HOST, fileName];
}

+ (BDLEPPDramaBean *)mockDataDramaBean_1 {
    BDLEPPDramaBean *drama = [[BDLEPPDramaBean alloc] init];
    drama.dramaId = [BDLEUtils getMd5String:@"mock_data_1"];

    NSArray *urlArr = @[
        [self mockUrl:MOCK_URL_1_480P],
        [self mockUrl:MOCK_URL_1_720P],
        [self mockUrl:MOCK_URL_1_1080P],
    ];
    NSArray *resArr = @[@"流畅 480P", @"准高清 720P", @"高清 1080P"];
    NSArray *wArr = @[@(480), @(720), @(1080)];
    NSArray *hArr = @[@(854), @(1280), @(1920)];
    NSArray *isDefaultArr = @[@(NO), @(NO), @(YES)];
    NSMutableArray *urlBeans = [NSMutableArray array];
    for (int i = 0; i < urlArr.count; i++) {
        BDLEPPUrlBean *urlBean = [[BDLEPPUrlBean alloc] init];
        urlBean.urlType = @"online";
        urlBean.url = urlArr[i];
        urlBean.resolution = resArr[i];
        urlBean.width = [wArr[i] integerValue];
        urlBean.height = [hArr[i] integerValue];
        urlBean.isDefault = [isDefaultArr[i] boolValue];
        [urlBeans addObject:urlBean];
    }
    drama.urlBeans = [urlBeans copy];

    BDLEPPMediaAssetBean *asset = [[BDLEPPMediaAssetBean alloc] init];
    asset.title = @"测试视频-竖屏/短视频/264/30帧";
    drama.mediaAssetBean = asset;
    return drama;
}

+ (BDLEPPDramaBean *)mockDataDramaBean_2 {
    BDLEPPDramaBean *drama = [[BDLEPPDramaBean alloc] init];
    drama.dramaId = [BDLEUtils getMd5String:@"mock_data_2"];

    NSArray *urlArr = @[
        [self mockUrl:MOCK_URL_2_540P],
        [self mockUrl:MOCK_URL_2_720P],
        [self mockUrl:MOCK_URL_2_1080P],
        [self mockUrl:MOCK_URL_2_2K],
        [self mockUrl:MOCK_URL_2_4K],
    ];
    NSArray *resArr = @[@"流畅 540P", @"准高清 720P", @"高清 1080P", @"超高清 2K", @"极致尊享 4K"];
    NSArray *wArr = @[@(960), @(1280), @(1920), @(2560), @(3840)];
    NSArray *hArr = @[@(540), @(720), @(1080), @(1440), @(2160)];
    NSArray *isDefaultArr = @[@(NO), @(NO), @(YES), @(NO), @(NO)];
    NSMutableArray *urlBeans = [NSMutableArray array];
    for (int i = 0; i < urlArr.count; i++) {
        BDLEPPUrlBean *urlBean = [[BDLEPPUrlBean alloc] init];
        urlBean.urlType = @"online";
        urlBean.url = urlArr[i];
        urlBean.resolution = resArr[i];
        urlBean.width = [wArr[i] integerValue];
        urlBean.height = [hArr[i] integerValue];
        urlBean.isDefault = [isDefaultArr[i] boolValue];
        [urlBeans addObject:urlBean];
    }
    drama.urlBeans = [urlBeans copy];

    BDLEPPMediaAssetBean *asset = [[BDLEPPMediaAssetBean alloc] init];
    asset.title = @"测试视频-横屏264/60帧/4K高码率";
    asset.startPosition = 0;
    BDLEPPSkipInfoBean *skipInfo = [[BDLEPPSkipInfoBean alloc] init];
    skipInfo.skipHead = @[@"0", @"10000"];
    skipInfo.skipTail = @[@"36000", @"-1"];
    asset.skipInfo = skipInfo;
    drama.mediaAssetBean = asset;
    return drama;
}

+ (BDLEPPDramaBean *)mockDataDramaBean_3 {
    BDLEPPDramaBean *drama = [[BDLEPPDramaBean alloc] init];
    drama.dramaId = [BDLEUtils getMd5String:@"mock_data_3"];

    NSArray *urlArr = @[
        [self mockUrl:MOCK_URL_3_720P],
        [self mockUrl:MOCK_URL_3_1080P],
        [self mockUrl:MOCK_URL_3_4K],
    ];
    NSArray *resArr = @[@"720P", @"1080P", @"4K"];
    NSArray *wArr = @[@(1280), @(1920), @(3840)];
    NSArray *hArr = @[@(720), @(1080), @(2160)];
    NSArray *isDefaultArr = @[@(NO), @(NO), @(YES)];
    NSMutableArray *urlBeans = [NSMutableArray array];
    for (int i = 0; i < urlArr.count; i++) {
        BDLEPPUrlBean *urlBean = [[BDLEPPUrlBean alloc] init];
        urlBean.urlType = @"online";
        urlBean.url = urlArr[i];
        urlBean.resolution = resArr[i];
        urlBean.width = [wArr[i] integerValue];
        urlBean.height = [hArr[i] integerValue];
        urlBean.isDefault = [isDefaultArr[i] boolValue];
        [urlBeans addObject:urlBean];
    }
    drama.urlBeans = [urlBeans copy];

    BDLEPPMediaAssetBean *asset = [[BDLEPPMediaAssetBean alloc] init];
    asset.title = @"测试视频-横屏264/30帧/4K低码率";
    drama.mediaAssetBean = asset;
    return drama;
}

@end
