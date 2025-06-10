//
//  BDLEUtils.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEUtils.h"
#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <arpa/inet.h>
#import <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


BOOL BDLE_isEmptyString(id param) {
    if (!param || ![param isKindOfClass:[NSString class]]) {
        return YES;
    }
    NSString *str = (NSString *)param;
    return (str.length == 0);
}

UIColor* BDLE_colorWithRGB(uint32_t rgbValue) {
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0f
                           green:((rgbValue & 0xFF00) >> 8) / 255.0f
                            blue:(rgbValue & 0xFF) / 255.0f
                           alpha:1.0];
}

@implementation BDLEUtils

+ (NSString *)getRandomUUID {
    return [self getMd5String:[[NSUUID UUID] UUIDString]];
}

+ (NSString *)getMd5String:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
                @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}

+ (NSString *)getIpAddressFromUrl:(NSString *)url {
    NSArray *array = [url componentsSeparatedByString: @"//"];
    if (array.count >= 2) {
        array = [array[1] componentsSeparatedByString: @"/"];
        NSString *result = [[[array firstObject] componentsSeparatedByString: @":"] firstObject];
        if ([result hasPrefix: @"["]) {
            result = [result substringFromIndex:1];
        }
        if ([result hasSuffix: @"]"]) {
            result = [result substringToIndex:result.length - 1];
        }
        return result;
    }
    return @"";
}

+ (NSInteger)getPortFromUrl:(NSString *)url {
    NSArray *array = [url componentsSeparatedByString: @"//"];
    if (array.count >= 2) {
        array = [array[1] componentsSeparatedByString: @"/"];
        NSArray<NSString *> *components = [[array firstObject] componentsSeparatedByString: @":"];
        if (components.count >= 2) {
            NSString *portStr = components[1];
            if ([portStr hasSuffix: @"]"]) {
                portStr = [portStr substringToIndex: portStr.length - 1];
            }
            return portStr.integerValue;
        }
    }
    return 0;
}

+ (NSString *)getLocalWlanIp {
    NSString *ipv4 = nil, *ipv6 = nil;
    NSString *ipv4_bridge = nil, *ipv6_bridge = nil;
    NSString *ipv4_ext = nil, *ipv6_ext = nil;
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces)) {
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface = interface->ifa_next) {
            if (!(interface->ifa_flags & IFF_UP)) {
                continue;
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];
            if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                BOOL isEn0 = strcmp(interface->ifa_name, "en0") == 0;
                BOOL isBridge100 = strcmp(interface->ifa_name, "bridge100") == 0;
                BOOL isEn = strncmp(interface->ifa_name, "en", 2) == 0;
                if (isEn == NO && isBridge100 == NO) {
                    continue;
                }
                if (addr->sin_family == AF_INET) {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        NSString *addStr = [NSString stringWithUTF8String: addrBuf];
                        if ([self ipv4Valid:addStr]) {
                            if (isEn0 || isBridge100) {
                                if (isEn0) {
                                    ipv4 = addStr;
                                } else {
                                    ipv4_bridge = addStr;
                                }
                            } else if (ipv4_ext.length == 0) {
                                ipv4_ext = addStr;
                            }
                        }
                    }
                    if (ipv4_bridge.length > 0) {
                       break;
                    }
                } else {
                    if (ipv4_ext.length > 0) {
                        continue;
                    }
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        if (isEn0 || isBridge100) {
                            if (isEn0) {
                                ipv6 = [NSString stringWithUTF8String: addrBuf];
                            } else {
                                ipv6_bridge = [NSString stringWithUTF8String: addrBuf];
                            }

                        } else {
                            ipv6_ext = [NSString stringWithUTF8String: addrBuf];
                        }
                    }
                }
            }
        }
        freeifaddrs(interfaces);
    }
    if (ipv4_bridge.length > 0) {
        return ipv4_bridge;
    }
    if (ipv4.length > 0) {
        return ipv4;
    }
    if (ipv4_ext.length > 0) {
        return ipv4_ext;
    }
    if (ipv6_bridge.length > 0) {
        return ipv6_bridge;
    }
    if (ipv6.length > 0) {
        return ipv6;
    }
    if (ipv6_ext.length > 0) {
        return ipv6_ext;
    }
    return @"";
}

+ (BOOL)ipv4Valid:(NSString *)ipv4 {
    if (ipv4.length == 0) {
        return NO;
    }
    NSArray *array = [ipv4 componentsSeparatedByString: @"."];
    if (array.count == 0) {
        return NO;
    }
    NSString *first = array.firstObject;
    if (first.length == 0) {
        return NO;
    }
    if ([first isEqualToString:@"169"]) {
        return NO;
    }
    return YES;
}

+ (NSString *)getJsonStringWithoutEscapingSlashes:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if (@available(iOS 13.0, *)) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingWithoutEscapingSlashes error:nil];
        if (jsonData.length == 0) {
            return nil;
        }
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        if (jsonData.length == 0) {
            return nil;
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        return jsonString;
    }
}

@end

@interface BDLEWeakProxy ()

@property (nonatomic, weak) id target;

@end

@implementation BDLEWeakProxy

+ (instancetype)proxyWithTarget:(id)target {
    BDLEWeakProxy *proxy = [BDLEWeakProxy alloc];
    proxy.target = target;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

@end
