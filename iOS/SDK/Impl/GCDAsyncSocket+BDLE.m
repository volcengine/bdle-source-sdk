//
//  GCDAsyncSocket+BDLE.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "GCDAsyncSocket+BDLE.h"
#import <objc/runtime.h>

@implementation GCDAsyncSocket (BDLE)

- (void)setRemoteIpAddress:(NSString *)remoteIpAddress {
    objc_setAssociatedObject(self, @selector(remoteIpAddress), remoteIpAddress, OBJC_ASSOCIATION_COPY);
}

- (NSString *)remoteIpAddress {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRemotePort:(NSInteger)remotePort {
    objc_setAssociatedObject(self, @selector(remotePort), @(remotePort), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)remotePort {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setConnectionType:(BDLESocketConnectionType)connectionType {
    objc_setAssociatedObject(self, @selector(connectionType), @(connectionType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDLESocketConnectionType)connectionType {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setSocketId:(NSString *)socketId {
    objc_setAssociatedObject(self, @selector(socketId), socketId, OBJC_ASSOCIATION_COPY);
}

- (NSString *)socketId {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setLeftReadBytes:(uint32_t)leftReadBytes {
    objc_setAssociatedObject(self, @selector(leftReadBytes), @(leftReadBytes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (uint32_t)leftReadBytes {
    return [objc_getAssociatedObject(self, _cmd) unsignedIntValue];
}

@end
