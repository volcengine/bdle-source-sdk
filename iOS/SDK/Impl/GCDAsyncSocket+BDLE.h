//
//  GCDAsyncSocket+BDLE.h
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLESocketConnectionType) {
    BDLESocketConnectionTypeUnknown = 0,
    BDLESocketConnectionTypeShort,  // 短连接
    BDLESocketConnectionTypeLong,   // 长连接
};

@interface GCDAsyncSocket (BDLE)

@property (nonatomic, copy, nullable) NSString *remoteIpAddress;

@property (nonatomic, assign) NSInteger remotePort;

@property (nonatomic, assign) BDLESocketConnectionType connectionType;

@property (nonatomic, copy, nullable) NSString *socketId;

// 剩余多少字节的数据要读，默认是0，读到数据包后会取前4位，得到要读包的字节数
@property (nonatomic, assign) uint32_t leftReadBytes;

@end

NS_ASSUME_NONNULL_END
