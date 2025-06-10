//
//  BDCLUPnPServer.h
//  DLNA_UPnP
//
//  Created by ClaudeLi on 2017/7/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDCLUPnPDevice;
@protocol BDCLUPnPServerDelegate <NSObject>
@required
/**
 搜索结果

 @param devices 设备数组
 */
- (void)upnpSearchChangeWithResults:(NSArray<BDCLUPnPDevice *> *)devices;

@optional
/**
 搜索失败

 @param error error
 */
- (void)upnpSearchErrorWithError:(NSError *)error;
/**
 设备离线

 @param offlineDevice 离线设备
 */
- (void)upnpDeviceUnavailable:(BDCLUPnPDevice *)offlineDevice;

@end

@interface BDCLUPnPServer : NSObject

@property (nonatomic, weak) id<BDCLUPnPServerDelegate> delegate;

/**
 启动Server并搜索
 */
- (void)start;

/**
 停止
 */
- (void)stop;

/**
 搜索
 */
- (void)search;

/**
 检测设备是否在线

 @param upnpDevice 待检测的设备
 */
- (void)checkServiceAlive:(BDCLUPnPDevice *)upnpDevice;

/**
 检测设备是否在线
 @param upnpDevice 待检测的设备
 @param maxCount 最大尝试次数
 @param timeout 单次request超时时间
 @param retryInterval retry时间间隔
 @param aUrlSession 可以传入自定义urlsession，防止用默认的server的urlsession在停止搜索后cancel掉所有请求
 @param completion callback
 */
- (void)checkServiceAlive:(BDCLUPnPDevice *)upnpDevice
                 maxCount:(NSInteger)maxCount
                  timeout:(NSTimeInterval)timeout
            retryInterval:(NSTimeInterval)retryInterval
               urlSession:(NSURLSession *)aUrlSession
               completion:(void (^)(BOOL isSuccess, NSError *error))completion;

@end
