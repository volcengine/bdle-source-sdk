//
//  BDCLUPnPSomeItem.m
//  DLNA_UPnP
//
//  Created by ClaudeLi on 2017/7/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "BDCLUPnP.h"
#import "GDataXMLNode.h"

@interface BDCLUPnPDevice() {
    NSInteger _checkCounter;
}
@property (nonatomic, copy) NSString *ipAddress;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) NSString *deviceKey;
@property (nonatomic, assign) BOOL isMediaRender;

@end

@implementation BDCLUPnPDevice

- (instancetype)init {
    if (self = [super init]) {
        _port = -1;
        _ipAddress = nil;
        _isMediaRender = NO;
    }
    return self;
}

- (BDCLServiceModel *)AVTransport {
    if (!_AVTransport) {
        _AVTransport = [[BDCLServiceModel alloc] init];
    }
    return _AVTransport;
}

- (BDCLServiceModel *)RenderingControl {
    if (!_RenderingControl) {
        _RenderingControl = [[BDCLServiceModel alloc] init];
    }
    return _RenderingControl;
}

- (NSString *)URLHeader {
    if (!_URLHeader) {
        _URLHeader = [NSString stringWithFormat:@"%@://%@:%@", [self.location scheme], [self.location host], [self.location port]];
    }
    return _URLHeader;
}

- (void)setArray:(NSArray *)array withRootElement:(GDataXMLElement *)rootElement {
    @autoreleasepool {
        for (int j = 0; j < [array count]; j++) {
            GDataXMLElement *ele = [array objectAtIndex:j];
            if ([ele.name isEqualToString:@"friendlyName"]) {
                self.friendlyName = [ele stringValue];
            } else if ([ele.name isEqualToString:@"modelName"]) {
                self.modelName = [ele stringValue];
            } else if ([ele.name isEqualToString:@"modelNumber"]) {
                self.modelNumber = [ele stringValue];
            } else if ([ele.name isEqualToString:@"deviceType"]) {
                self.type = [ele stringValue];
                NSRange range = [self.type rangeOfString:@"MediaRenderer" options:NSBackwardsSearch|NSCaseInsensitiveSearch];
                if (range.location != NSNotFound) {
                    self.isMediaRender = YES;
                }
            } else if ([ele.name isEqualToString:@"modelURL"]) {
                self.modelURL = [ele stringValue];
            } else if ([ele.name isEqualToString:@"manufacturer"]) {
                self.manufacturer = [ele stringValue];
            } else if ([ele.name isEqualToString:@"manufacturerURL"]) {
                self.manufacturerURL = [ele stringValue];
            } else if ([ele.name isEqualToString:@"serviceList"]) {
                NSArray *serviceListArray = [ele children];
                for (int k = 0; k < [serviceListArray count]; k++) {
                    GDataXMLElement *listEle = [serviceListArray objectAtIndex:k];
                    if ([listEle.name isEqualToString:@"service"]) {
                        NSString *serviceString = [listEle stringValue];
                        if ([serviceString containsString:serviceType_AVTransport] || [serviceString containsString:serviceId_AVTransport]) {
                            [self.AVTransport setArray:[listEle children]];
                        } else if ([serviceString containsString:serviceType_RenderingControl] || [serviceString containsString:serviceId_RenderingControl]) {
                            [self.RenderingControl setArray:[listEle children]];
                        }
                    }
                }
                continue;
            }
        }
    }
}

- (NSString *)description {
    NSString * string = [NSString stringWithFormat:@"\nuuid:%@\nlocation:%@\nURLHeader:%@\nfriendlyName:%@\nmodelName:%@\nmodelNumber:%@\n", self.uuid, self.location, self.URLHeader, self.friendlyName, self.modelName, self.modelNumber];
    return string;
}

- (NSArray<NSString *> *)URLHeaderComponents {
    NSString *string = [self.URLHeader componentsSeparatedByString: @"//"].lastObject;
    if (string.length == 0) {
        return nil;
    } else {
        return [string componentsSeparatedByString: @":"];
    }
}

- (NSString *)ipAddress {
    if (_ipAddress == nil) {
        NSArray<NSString *> *components = [self URLHeaderComponents];
        if (components.count == 0) {
            _ipAddress = @"";
        } else {
            _ipAddress = [components.firstObject copy];
        }
    }
    return _ipAddress;
}

- (NSInteger)port {
    if (_port < 0) {
        NSArray<NSString *> *components = [self URLHeaderComponents];
        if (components.count <= 1) {
            _port = 0;
        } else {
            NSString *portStr = components[1];
            _port = portStr.integerValue;
        }
    }
    return _port;
}

- (NSString *)deviceKey {
    if (_deviceKey == nil) {
        _deviceKey = [NSString stringWithFormat:@"%@:%ld", self.ipAddress, (long)self.port];
    }
    return _deviceKey;
}

- (NSInteger)checkCounter {
    @synchronized (self) {
        return _checkCounter;
    }
}

- (void)setCheckCounter:(NSInteger)checkCounter {
    @synchronized (self) {
        _checkCounter = checkCounter;
    }
}

- (BOOL)supportBDLEProtocol {
    // BDLE的设备，会在Server中包含 BDLE+DLNA/1.0 的标识，能检测到标识即视为BDLE设备
    NSString *bdleIdr = @"BDLE+DLNA";
    if ([self.httpHeaderServer isKindOfClass:[NSString class]] && self.httpHeaderServer.length > 0) {
        NSRange range = [self.httpHeaderServer rangeOfString:bdleIdr options:NSBackwardsSearch|NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation BDCLServiceModel

- (void)setArray:(NSArray *)array {
    @autoreleasepool {
        for (int m = 0; m < array.count; m++) {
            GDataXMLElement *needEle = [array objectAtIndex:m];
            if ([needEle.name isEqualToString:@"serviceType"]) {
                self.serviceType = [needEle stringValue];
            }
            if ([needEle.name isEqualToString:@"serviceId"]) {
                self.serviceId = [needEle stringValue];
            }
            if ([needEle.name isEqualToString:@"controlURL"]) {
                self.controlURL = [needEle stringValue];
            }
            if ([needEle.name isEqualToString:@"eventSubURL"]) {
                self.eventSubURL = [needEle stringValue];
            }
            if ([needEle.name isEqualToString:@"SCPDURL"]) {
                self.SCPDURL = [needEle stringValue];
            }
        }
    }
}

@end
