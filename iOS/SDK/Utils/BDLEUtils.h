//
//  BDLEUtils.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define bdle_log_verbose(target, format, ...)\
@autoreleasepool {\
NSString *bdle_log_message = [NSString stringWithFormat: format, ##__VA_ARGS__, nil];\
NSString *fileInfo = [NSString stringWithFormat: @"%s, %s, %d", __FILE_NAME__, __FUNCTION__, __LINE__];\
NSLog(@"[V] %@ | %@", fileInfo, bdle_log_message);\
}

#define bdle_log_info(target, format, ...)\
@autoreleasepool {\
NSString *bdle_log_message = [NSString stringWithFormat: format, ##__VA_ARGS__, nil];\
NSString *fileInfo = [NSString stringWithFormat: @"%s, %s, %d", __FILE_NAME__, __FUNCTION__, __LINE__];\
NSLog(@"[I] %@ | %@", fileInfo, bdle_log_message);\
}


#ifndef BDLE_isEmptyString
FOUNDATION_EXPORT BOOL BDLE_isEmptyString(id param);
#endif

#ifndef BDLE_colorWithRGB
FOUNDATION_EXPORT UIColor* BDLE_colorWithRGB(uint32_t rgbValue);
#endif

@interface BDLEUtils : NSObject

+ (NSString *)getRandomUUID;

+ (NSString *)getMd5String:(NSString *)string;

+ (NSString *)getIpAddressFromUrl:(NSString *)url;

+ (NSInteger)getPortFromUrl:(NSString *)url;

+ (NSString *)getLocalWlanIp;

+ (NSString *)getJsonStringWithoutEscapingSlashes:(NSDictionary *)dict;

@end

@interface BDLEWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
