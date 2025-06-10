//
//  BDCLUPnP.h
//  DLNA_UPnP
//
//  Created by ClaudeLi on 16/9/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#ifndef BDCLUPnP_h
#define BDCLUPnP_h

#import "BDCLUPnPServer.h"
#import "BDCLUPnPDevice.h"

static NSString *ssdpAddress = @"239.255.255.250";
static UInt16   ssdpPort = 1900;

static NSString *serviceType_AVTransport        = @"urn:schemas-upnp-org:service:AVTransport:1";
static NSString *serviceType_RenderingControl   = @"urn:schemas-upnp-org:service:RenderingControl:1";
static NSString *serviceType_MediaRender        = @"urn:schemas-upnp-org:device:MediaRenderer:1";
static NSString *serviceType_RootDevice         = @"upnp:rootdevice";

static NSString *serviceId_AVTransport          = @"urn:upnp-org:serviceId:AVTransport";
static NSString *serviceId_RenderingControl     = @"urn:upnp-org:serviceId:RenderingControl";

#endif /* BDCLUPnP_h */
