//
//  NSObject+BDLEContext.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "NSObject+BDLEContext.h"
#import <objc/runtime.h>

@implementation NSObject (BDLEContext)

- (void)setBdleContextId:(NSString *)bdleContextId {
    objc_setAssociatedObject(self, @selector(bdleContextId), bdleContextId, OBJC_ASSOCIATION_COPY);
}

- (NSString *)bdleContextId {
    return objc_getAssociatedObject(self, @selector(bdleContextId));
}

@end
