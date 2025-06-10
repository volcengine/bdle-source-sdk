//
//  main.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
