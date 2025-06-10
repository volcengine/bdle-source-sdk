//
//  BDCLUPnPDevice.h
//  DLNA_UPnP
//
//  Created by ClaudeLi on 2017/7/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDCLServiceModel, GDataXMLElement;

@interface BDCLUPnPDevice : NSObject

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, copy) NSString *URLHeader;
@property (nonatomic, copy, readonly) NSString *ipAddress;
@property (nonatomic, assign, readonly) NSInteger port;
@property (nonatomic, copy) NSString *friendlyName;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, copy) NSString *modelNumber;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *modelURL;
@property (nonatomic, copy) NSString *manufacturer;
@property (nonatomic, copy) NSString *manufacturerURL;
@property (nonatomic, copy) NSString *httpHeaderServer;
@property (nonatomic, assign, readonly) BOOL isMediaRender;

@property (nonatomic, strong) BDCLServiceModel *AVTransport;
@property (nonatomic, strong) BDCLServiceModel *RenderingControl;

@property (nonatomic, readonly) NSString *deviceKey;
@property (nonatomic, assign) NSInteger checkCounter;

// BDLE
@property (nonatomic, assign, readonly) BOOL supportBDLEProtocol;
@property (nonatomic, assign) int bdleSocketPort;
@property (nonatomic, assign) BOOL bdleServiceDIRequesting;
@property (nonatomic, assign) BOOL bdleServiceAvailable;

- (void)setArray:(NSArray *)array withRootElement:(GDataXMLElement *)rootElement;

@end

@interface BDCLServiceModel : NSObject

@property (nonatomic, copy) NSString *serviceType;
@property (nonatomic, copy) NSString *serviceId;
@property (nonatomic, copy) NSString *controlURL;
@property (nonatomic, copy) NSString *eventSubURL;
@property (nonatomic, copy) NSString *SCPDURL;

- (void)setArray:(NSArray *)array;

@end

