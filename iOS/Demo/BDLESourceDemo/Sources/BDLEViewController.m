//
//  BDLEViewController.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEViewController.h"
#import "BDLEToolboxView.h"
#import "BDLEMockData.h"
#import <Masonry/Masonry.h>

#import <BDLESource/BDLEService.h>
#import <BDLESource/BDLEConnection.h>
#import <BDLESource/BDLEPlayer.h>
#import <BDLESource/BDLEPlayerItem.h>
#import <BDLESource/BDLEUtils.h>

typedef NS_ENUM(NSInteger, BDLEConnectionStatus) {
    BDLEConnectionStatusUnconnected = 0,
    BDLEConnectionStatusConnecting,
    BDLEConnectionStatusConnected,
};

@interface BDLEViewController () <UITableViewDelegate, UITableViewDataSource, BDLEToolboxViewDelegate, BDLEConnectionDelegate, BDLEPlayerDelegate>

// Core
@property (nonatomic, strong) BDLEService *service;
@property (nonatomic, strong) BDLEConnection *connection;
@property (nonatomic, strong) BDLEPlayer *player;

// UI
@property (nonatomic, assign) BOOL cmdTableViewEnabled;
@property (nonatomic, strong) UITextView *statusTextView;
@property (nonatomic, strong) UITableView *logTableView;
@property (nonatomic, strong) UITableView *cmdTableView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) BDLEToolboxView *toolboxView;
@property (nonatomic, assign) BOOL isSliderSliding;
@property (nonatomic, strong) NSMutableArray<NSString *> *logArray;
@property (nonatomic, copy) NSArray<BDLEDebugItem *> *cmdArray;

// Status
@property (nonatomic, strong) NSMutableArray<BDLEPPDramaBean *> *currentDramaBeanArray;
@property (nonatomic, assign) NSInteger currentPlayIndex;
@property (nonatomic, copy) NSString *currentDramaId;
@property (nonatomic, assign) BDLEConnectionStatus connectionStatus;
@property (nonatomic, assign) BDLEPlayerLoopMode currentLoopMode;
@property (nonatomic, assign) BDLEPlayerShuffleMode currentShuffleMode;
@property (nonatomic, assign) BDLEPlayStatus currentPlayStatus;
@property (nonatomic, strong) BDLEPPMediaInfo *currentMediaInfo;

@end

@implementation BDLEViewController

- (instancetype)initWithService:(BDLEService *)service {
    if (self = [super init]) {
        self.service = service;
        self.connection = [[BDLEConnection alloc] initWithBDLEService:self.service delegate:self];
        self.connectionStatus = BDLEConnectionStatusUnconnected;
        self.currentLoopMode = BDLEPlayerLoopModeNone;
        self.currentShuffleMode = BDLEPlayerShuffleModeDisable;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStylePlain target:self action:@selector(onConnect:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(onQuit:)];
    [self buildUI];
    [self updateUIStatus];
    [self updateStatusViewText];
}

- (void)buildUI {
    [self.view addSubview:self.statusTextView];
    [self.view addSubview:self.slider];
    [self.view addSubview:self.toolboxView];
    [self.view addSubview:self.cmdTableView];
    [self.view addSubview:self.logTableView];

    [self.statusTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(64);
    }];

    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statusTextView.mas_bottom);
        make.left.right.equalTo(self.statusTextView);
        make.height.mas_equalTo(44);
    }];

    [self.toolboxView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.slider.mas_bottom);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(64);
    }];

    [self.cmdTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.toolboxView.mas_bottom);
        make.left.bottom.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.3);
    }];

    [self.logTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.cmdTableView);
        make.left.equalTo(self.cmdTableView.mas_right);
        make.right.equalTo(self.view);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationItem.hidesBackButton = NO;
}

- (void)updateUIStatus {
    self.navigationItem.title = [NSString stringWithFormat:@"%@(%@)", self.service.serviceName, self.connectionStatusDesc];
    if (self.connectionStatus == BDLEConnectionStatusConnecting) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"连接";
    } else if (self.connectionStatus == BDLEConnectionStatusConnected) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.title = @"断开";
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.title = @"连接";
    }

    self.slider.enabled = (self.currentMediaInfo != nil && self.connectionStatus == BDLEConnectionStatusConnected);
    self.cmdTableViewEnabled = (self.connectionStatus == BDLEConnectionStatusConnected);
}

- (NSString *)connectionStatusDesc {
    if (self.connectionStatus == BDLEConnectionStatusConnecting) {
        return @"连接中...";
    } else if (self.connectionStatus == BDLEConnectionStatusConnected) {
        return @"已连接";
    } else {
        return @"未连接";
    }
}

- (void)onConnect:(id)sender {
    if (self.connectionStatus == BDLEConnectionStatusConnected) {
        // 当前已连接，执行断开
        NSLog(@"[Demo] start disconnect: %@, ip:%@, port:%d", self.service.serviceName, self.service.ipAddress, self.service.bdleSocketPort);
        [self addLog:[NSString stringWithFormat:@"disconnect from %@", self.service.ipAddress]];
        self.connectionStatus = BDLEConnectionStatusUnconnected;
        [self updateUIStatus];
        [self.connection disconnect];
    } else {
        // 当前未连接，执行连接
        NSLog(@"[Demo] start connect: %@, ip:%@, port:%d", self.service.serviceName, self.service.ipAddress, self.service.bdleSocketPort);
        [self addLog:[NSString stringWithFormat:@"start connect to %@:%d", self.service.ipAddress, self.service.bdleSocketPort]];
        self.connectionStatus = BDLEConnectionStatusConnecting;
        [self updateUIStatus];
        [self.connection connect];
    }
}

- (void)onQuit:(id)sender {
    if (self.connectionStatus == BDLEConnectionStatusConnected) {
        [self showAlertWithTitle:@"" message:@"需要先断开连接才可以退出" tfPlaceholders:@[] tfDefaultValues:@[] tfKeyboardTypes:@[] confirmBlock:^(NSArray<NSString *> *tfValues) {}];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Private
- (void)addLog:(NSString *)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDate *date = [NSDate date];
        static NSDateFormatter *fmt = nil;
        if (!fmt) {
            fmt = [[NSDateFormatter alloc] init];
            fmt.dateFormat = @"HH:mm:ss.SSS";
        }
        NSString *dateStr = [fmt stringFromDate:date];
        [self.logArray addObject:[NSString stringWithFormat:@"[%@] %@", dateStr, log]];
        [self.logTableView reloadData];
    });
}

- (void)updateStatusViewText {
    NSMutableString *mutStr = [[NSMutableString alloc] init];
    NSString *dramaTitle = @"无";
    if (self.currentDramaId.length > 0) {
        for (BDLEPPDramaBean *item in self.currentDramaBeanArray) {
            if ([item.dramaId isEqualToString:self.currentDramaId]) {
                dramaTitle = item.mediaAssetBean.title;
                break;
            }
        }
    }
    [mutStr appendFormat:@"当前剧集：%@", dramaTitle];

    NSString *playStatusStr;
    if (self.currentPlayStatus == BDLEPlayStatusUnknown) {
        playStatusStr = @"Unknown";
    } else if (self.currentPlayStatus == BDLEPlayStatusLoading) {
        playStatusStr = @"Loading";
    } else if (self.currentPlayStatus == BDLEPlayStatusPlaying) {
        playStatusStr = @"Playing";
    } else if (self.currentPlayStatus == BDLEPlayStatusPause) {
        playStatusStr = @"Pause";
    } else if (self.currentPlayStatus == BDLEPlayStatusStopped) {
        playStatusStr = @"Stopped";
    } else if (self.currentPlayStatus == BDLEPlayStatusCompleted) {
        playStatusStr = @"Completed";
    } else if (self.currentPlayStatus == BDLEPlayStatusError) {
        playStatusStr = @"Error";
    }
    [mutStr appendFormat:@"\n当前状态：%@", playStatusStr];

    NSLog(@"===%ld, %@", mutStr.length, mutStr);
    self.statusTextView.text = [mutStr copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusTextView.contentOffset = CGPointZero;
        [self.statusTextView scrollRangeToVisible:NSMakeRange(0, 1)];
    });

    [self.toolboxView reloadUIWithData:self.currentMediaInfo];
}

- (void)handleDebugItemDidSelected:(BDLEDebugItem *)item {
    if (item.type == BDLEDebugItemTypePlay) {
        // 播放单个/多个文件
        NSString *playId = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.ids"] ?: @"1,2,3";
        NSString *index = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.index"] ?: @"";
        NSString *loop = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.loop"] ?: @"0,0";
        NSString *speed = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.speed"] ?: @"1.0";
        NSString *stretch = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.stretch"] ?: @"";
        NSString *skip = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.skip"] ?: @"";
        NSString *inherit = [[NSUserDefaults standardUserDefaults] valueForKey:@"demo.bdle.play.inherit"] ?: @"";

        [self showAlertWithTitle:@"Play"
                         message:@"输入要播放的ID，以,分割\n【其它输入框】\n(0)起播索引(1)循环,随机(2)倍速(3)拉伸(4)跳过片头片尾(5)是否切集继承[421]"
                  tfPlaceholders:@[@"ID数组，例: 1,2", @"startIndex,默认0", @"loop,shuffle", @"speed", @"stretch", @"skip", @"inherit"]
                 tfDefaultValues:@[playId, index, loop, speed, stretch, skip, inherit]
                 tfKeyboardTypes:@[@(UIKeyboardTypeDefault)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            [self addLog:@"play drama list"];
            NSArray *dramaIds = [tfValues[0] componentsSeparatedByString:@","];
            NSMutableArray<BDLEPPDramaBean *> *ppDramaBeans = [NSMutableArray array];
            for (NSString *drid in dramaIds) {
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"mockDataDramaBean_%d", [drid intValue]]);
                if ([[BDLEMockData class] respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
                    BDLEPPDramaBean *ppDrama = [[BDLEMockData class] performSelector:selector];
#pragma clang diagnostic pop
                    if (ppDrama) {
                        [ppDramaBeans addObject:ppDrama];
                    }
                }
            }
            NSInteger startIndex = [tfValues[1] integerValue];
            NSString *loopCfg = tfValues[2];
            NSArray *loopCfgArr = [loopCfg componentsSeparatedByString:@","];

            BDLEPlayerItem *bdlePlayerItem = [[BDLEPlayerItem alloc] init];
            bdlePlayerItem.dramaBeans = ppDramaBeans;
            if (startIndex < ppDramaBeans.count) {
                bdlePlayerItem.startDramaId = ppDramaBeans[startIndex].dramaId;
            }
            BDLEPPPlayControlInfo *playControlInfo = [[BDLEPPPlayControlInfo alloc] init];
            playControlInfo.loopMode = [loopCfgArr[0] integerValue];
            playControlInfo.shuffle = [loopCfgArr[1] integerValue];
            playControlInfo.speed = [tfValues[3] floatValue];
            playControlInfo.stretch = [tfValues[4] integerValue];
            playControlInfo.skip = [tfValues[5] integerValue];
            playControlInfo.inheritConfig = [tfValues[6] integerValue];
            playControlInfo.featureConfig = 0;
            bdlePlayerItem.playControlInfo = playControlInfo;
            __weak typeof(self) weakSelf = self;
            [self.player playWithItem:bdlePlayerItem completionBlock:^(NSError * _Nullable error) {
                __strong typeof(weakSelf) self = weakSelf;
                [self.currentDramaBeanArray removeAllObjects];
                [self.currentDramaBeanArray addObjectsFromArray:ppDramaBeans];
                self.currentPlayIndex = 0;
            }];

            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[0] ?: @"") forKey:@"demo.bdle.play.ids"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[1] ?: @"") forKey:@"demo.bdle.play.index"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[2] ?: @"") forKey:@"demo.bdle.play.loop"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[3] ?: @"") forKey:@"demo.bdle.play.speed"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[4] ?: @"") forKey:@"demo.bdle.play.stretch"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[5] ?: @"") forKey:@"demo.bdle.play.skip"];
            [[NSUserDefaults standardUserDefaults] setValue:(tfValues[6] ?: @"") forKey:@"demo.bdle.play.inherit"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    } else if (item.type == BDLEDebugItemTypePause) {
        [self addLog:@"pause"];
        [self.player pause];
    } else if (item.type == BDLEDebugItemTypeResume) {
        [self addLog:@"resume"];
        [self.player resumePlay];
    } else if (item.type == BDLEDebugItemTypeStop) {
        [self addLog:@"stop"];
        [self.player stop];
        [self.currentDramaBeanArray removeAllObjects];
        self.currentPlayIndex = 0;
        self.currentMediaInfo = nil;
        [self updateStatusViewText];
        self.slider.value = 0;
        self.slider.enabled = NO;
    } else if (item.type == BDLEDebugItemTypePlayPreDrama) {
        [self addLog:@"play prev drama"];
        [self.player playPreDrama];
        if (self.currentPlayIndex > 0) {
            self.currentPlayIndex = self.currentPlayIndex - 1;
        }
    } else if (item.type == BDLEDebugItemTypePlayNextDrama) {
        [self addLog:@"play next drama"];
        [self.player playNextDrama];
        if (self.currentPlayIndex < self.currentDramaBeanArray.count - 1) {
            self.currentPlayIndex = self.currentPlayIndex + 1;
        }
    } else if (item.type == BDLEDebugItemTypePlayDramaId) {
        [self showAlertWithTitle:@"PlayDramaId"
                         message:@"输入指定剧集的ID"
                  tfPlaceholders:@[@"ID"]
                 tfDefaultValues:nil
                 tfKeyboardTypes:@[@(UIKeyboardTypeNumberPad)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            NSString *dramaIdx = tfValues[0];
            SEL selector = NSSelectorFromString([NSString stringWithFormat:@"mockDataDramaBean_%d", [dramaIdx intValue]]);
            if ([[BDLEMockData class] respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
                BDLEPPDramaBean *ppDrama = [[BDLEMockData class] performSelector:selector];
#pragma clang diagnostic pop
                if (ppDrama) {
                    NSString *dramaId = ppDrama.dramaId;
                    [self addLog:[NSString stringWithFormat:@"play drama id: %@", dramaIdx]];
                    [self.player playDramaWithDramaId:dramaId];
                } else {
                    [self addLog:[NSString stringWithFormat:@"play drama id unsupported: %@", dramaIdx]];
                }
            } else {
                [self addLog:[NSString stringWithFormat:@"play drama id unsupported: %@", dramaIdx]];
            }
        }];
    } else if (item.type == BDLEDebugItemTypeAddDramaList) {
        [self showAlertWithTitle:@"AddDramaList"
                         message:@"输入要播放的ID，以,分割"
                  tfPlaceholders:@[@"ID数组，例: 1,2", @"insertBefore,默认不填"]
                 tfDefaultValues:@[@"", @""]
                 tfKeyboardTypes:@[@(UIKeyboardTypeDefault)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            [self addLog:@"add drama list"];

            NSString *beforeIdx = (tfValues[1].length > 0) ? tfValues[1] : nil;
            BDLEPPDramaBean *targetBean = nil;
            NSArray *idsToAdd = [tfValues[0] componentsSeparatedByString:@","];
            NSMutableArray<BDLEPPDramaBean *> *ppDramaBeans = [NSMutableArray array];
            for (NSString *dramaId in idsToAdd) {
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"mockDataDramaBean_%d", [dramaId intValue]]);
                if ([[BDLEMockData class] respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
                    BDLEPPDramaBean *ppDrama = [[BDLEMockData class] performSelector:selector];
#pragma clang diagnostic pop
                    if (ppDrama) {
                        if (beforeIdx && [beforeIdx isEqualToString:dramaId]) {
                            targetBean = ppDrama;
                        }
                        [ppDramaBeans addObject:ppDrama];
                    }
                }
            }

            if (beforeIdx.length > 0) {
                NSInteger index = targetBean ? [ppDramaBeans indexOfObject:targetBean] : NSNotFound;
                if (index >= 0) {
                    [self.currentDramaBeanArray insertObjects:ppDramaBeans atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, ppDramaBeans.count)]];
                } else {
                    [self.currentDramaBeanArray addObjectsFromArray:ppDramaBeans];
                }
            } else {
                [self.currentDramaBeanArray addObjectsFromArray:ppDramaBeans];
            }

            [self.player addDramaList:ppDramaBeans beforeDramaId:targetBean.dramaId completionBlock:nil];
        }];
    } else if (item.type == BDLEDebugItemTypeDeleteDramaList) {
        [self showAlertWithTitle:@"DeleteDramaList"
                         message:@"输入要删除的ID，以,分割"
                  tfPlaceholders:@[@"ID数组，例: 1,2"]
                 tfDefaultValues:@[@""]
                 tfKeyboardTypes:@[@(UIKeyboardTypeDefault)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            NSString *idsStr = tfValues[0];
            [self addLog:[NSString stringWithFormat:@"delete drama list: %@", idsStr]];
            NSArray<NSString *> *idsArr = [idsStr componentsSeparatedByString:@","];
            NSMutableArray<NSString *> *list = [NSMutableArray array];
            NSMutableArray<BDLEPPDramaBean *> *toDeleteArr = [[NSMutableArray alloc] init];
            for (NSString *dramaId in idsArr) {
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"mockDataDramaBean_%d", [dramaId intValue]]);
                if ([[BDLEMockData class] respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
                    BDLEPPDramaBean *ppDrama = [[BDLEMockData class] performSelector:selector];
#pragma clang diagnostic pop
                    if (ppDrama.dramaId) {
                        [toDeleteArr addObject:ppDrama];
                        [list addObject:ppDrama.dramaId];
                    }
                }
            }
            [self.currentDramaBeanArray removeObjectsInArray:toDeleteArr];
            [self.player deleteDramaList:list];
        }];
    } else if (item.type == BDLEDebugItemTypeSetSkipInfo) {
        [self showAlertWithTitle:@"SetSkipInfo"
                         message:nil
                  tfPlaceholders:@[@"enable"]
                 tfDefaultValues:nil
                 tfKeyboardTypes:@[@(UIKeyboardTypeNumberPad)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            BOOL enable = [tfValues[0] boolValue];
            [self.player setSkipHeadTail:enable];
            [self addLog:[NSString stringWithFormat:@"set skip info, enable=%d", (int)enable]];
        }];
    } else if (item.type == BDLEDebugItemTypeGetVolume) {
        [self addLog:@"get volume"];
        [self.player getVolume:^(NSInteger volume, BOOL success) {
            [self addLog:[NSString stringWithFormat:@"get volume result: %ld", volume]];
        }];
    } else if (item.type == BDLEDebugItemTypeSetVolume) {
        [self showAlertWithTitle:@"SetVolume"
                         message:nil
                  tfPlaceholders:@[@"volume(0-100)"]
                 tfDefaultValues:nil
                 tfKeyboardTypes:@[@(UIKeyboardTypeNumberPad)]
                    confirmBlock:^(NSArray<NSString *> *tfValues) {
            NSInteger volume = [tfValues[0] integerValue];
            [self addLog:[NSString stringWithFormat:@"set volume: %d", (int)volume]];
            [self.player setVolume:volume];
        }];
    } else if (item.type == BDLEDebugItemTypeAddVolume) {
        [self addLog:@"add volume"];
        [self.player addVolume];
    } else if (item.type == BDLEDebugItemTypeSubVolume) {
        [self addLog:@"reduce volume"];
        [self.player reduceVolume];
    } else if (item.type == BDLEDebugItemTypeGetStatusInfo) {
        [self addLog:@"get status info"];
        [self.player getStatusInfo];
    } else if (item.type == BDLEDebugItemTypeGetMediaInfo) {
        [self addLog:@"get media info"];
        [self.player getMediaInfo];
    }
}

- (void)onSliderTouchDown:(UISlider *)slider {
    self.isSliderSliding = YES;
}

- (void)onSliderTouchUp:(UISlider *)slider {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isSliderSliding = NO;
    });
    if (self.player.connection.isConnected) {
        [self.player seekTo:floor(slider.value)];
    }
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
            tfPlaceholders:(NSArray<NSString *> *)tfPlaceholders
           tfDefaultValues:(NSArray<NSString *> *)tfDefaultValues
           tfKeyboardTypes:(NSArray<NSNumber *> *)tfKeyboardTypes
              confirmBlock:(void(^)(NSArray<NSString *> *tfValues))confirmBlock {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    for (int i = 0; i < tfPlaceholders.count; i++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = tfPlaceholders[i];
            if (tfDefaultValues.count > i) {
                textField.text = tfDefaultValues[i];
            }
            if (tfKeyboardTypes.count > i) {
                textField.keyboardType = [tfKeyboardTypes[i] integerValue];
            }
        }];
    }
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = alertController.textFields;
        NSMutableArray *values = [[NSMutableArray alloc] init];
        for (UITextField *tf in textFields) {
            [values addObject:tf.text ?: @""];
        }
        if (confirmBlock) {
            confirmBlock([values copy]);
        }
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showActionSheetWithTitle:(NSString *)title actionTitles:(NSArray<NSString *> *)actionTitles confirmBlock:(void(^)(NSString *titleString))confirmBlock {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    for (NSString *acitonT in actionTitles) {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:acitonT style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (confirmBlock) {
                confirmBlock(acitonT);
            }
        }];
        [alertController addAction:okAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - BDLEToolboxViewDelegate
- (void)toolboxDidSelectSpeed {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count || !self.currentMediaInfo) {
        return;
    }

    NSArray<NSNumber *> *allSpeed = self.currentMediaInfo.speeds;
    NSMutableArray<NSString *> *allSpeedTitles = [NSMutableArray new];
    for (NSNumber *spd in allSpeed) {
        [allSpeedTitles addObject:spd.stringValue];
    }
    [self showActionSheetWithTitle:@"SetSpeed" actionTitles:allSpeedTitles confirmBlock:^(NSString *titleString) {
        CGFloat speed = [titleString floatValue];
        [self addLog:[NSString stringWithFormat:@"set speed: %.2f", speed]];
        [self.player setPlaySpeed:speed];
    }];
}

- (void)toolboxDidSelectResolution {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count) {
        return;
    }
    BDLEPPDramaBean *drama = self.currentDramaBeanArray[self.currentPlayIndex];

    NSMutableArray *allResolution = [NSMutableArray array];
    NSMutableArray *allUrl = [NSMutableArray array];

    if (!drama.urlBeans || drama.urlBeans.count == 0) {
        return;
    }
    for (BDLEPPUrlBean *item in drama.urlBeans) {
        [allResolution addObject:(item.resolution ?: @"")];
        [allUrl addObject:(item.url ?: @"")];
    }

    [self showActionSheetWithTitle:@"SetResolution" actionTitles:allResolution confirmBlock:^(NSString *titleString) {
        NSInteger index = [allResolution indexOfObject:titleString];
        if (index != NSNotFound && index < allUrl.count) {
            NSString *urlString = allUrl[index];
            [self.player setResolution:titleString urlType:nil url:urlString mode:0];
            [self addLog:[NSString stringWithFormat:@"set resolution:%@, url:%@", titleString, urlString]];
        }
    }];
}

- (void)toolboxDidSelectSubtitle {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count) {
        return;
    }
    NSArray *allAction = @[@"开启", @"关闭"];
    [self showActionSheetWithTitle:@"SetSubtitle" actionTitles:allAction confirmBlock:^(NSString *titleString) {
        [self addLog:[NSString stringWithFormat:@"set subtitle: %@", titleString]];
        BDLEPPSubtitleBean *subtitle = [[BDLEPPSubtitleBean alloc] init];
        if ([titleString isEqualToString:@"开启"]) {
            subtitle.switchStatus = 1;
            subtitle.url = @"http://172.20.10.13:8000/test.srt";
            subtitle.language = @"cmn-Hans-CN";
            subtitle.startTime = @"00:00:00.000";
        } else if ([titleString isEqualToString:@"关闭"]) {
            subtitle.switchStatus = 0;
        }
        [self.player setSubtitle:subtitle];
    }];
}

- (void)toolboxDidSelectLoopMode {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count) {
        return;
    }
    NSArray *allAction = @[@"不循环", @"单个循环", @"列表循环"];
    [self showActionSheetWithTitle:@"SetLoopMode" actionTitles:allAction confirmBlock:^(NSString *titleString) {
        [self addLog:[NSString stringWithFormat:@"set loop mode: %@", titleString]];
        if ([titleString isEqualToString:@"不循环"]) {
            self.currentLoopMode = BDLEPlayerLoopModeNone;
        } else if ([titleString isEqualToString:@"单个循环"]) {
            self.currentLoopMode = BDLEPlayerLoopModeSingle;
        } else if ([titleString isEqualToString:@"列表循环"]) {
            self.currentLoopMode = BDLEPlayerLoopModeList;
        }
        [self.player setLoopMode:self.currentLoopMode shuffle:self.currentShuffleMode];
    }];
}

- (void)toolboxDidSelectShuffle {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count) {
        return;
    }
    NSArray *allAction = @[@"开启", @"关闭"];
    [self showActionSheetWithTitle:@"SetShuffleMode" actionTitles:allAction confirmBlock:^(NSString *titleString) {
        [self addLog:[NSString stringWithFormat:@"set shuffle mode: %@", titleString]];
        if ([titleString isEqualToString:@"开启"]) {
            self.currentShuffleMode = YES;
        } else if ([titleString isEqualToString:@"关闭"]) {
            self.currentShuffleMode = NO;
        }
        [self.player setLoopMode:self.currentLoopMode shuffle:self.currentShuffleMode];
    }];
}

- (void)toolboxDidSelectStretch {
    if (self.currentDramaBeanArray.count == 0 || self.currentPlayIndex >= self.currentDramaBeanArray.count) {
        return;
    }
    NSArray *allAction = @[@"等比充满，留黑边(0)", @"强制充满(1)", @"等比充满，裁超出(2)"];
    [self showActionSheetWithTitle:@"SetStretchMode" actionTitles:allAction confirmBlock:^(NSString *titleString) {
        [self addLog:[NSString stringWithFormat:@"set stretch mode: %@", titleString]];
        BDLEPlayerStretchMode mode = BDLEPlayerStretchModeScaleAspectFit;
        if ([titleString isEqualToString:@"强制充满(1)"]) {
            mode = BDLEPlayerStretchModeScaleToFill;
        } else if ([titleString isEqualToString:@"等比充满，留黑边(0)"]) {
            mode = BDLEPlayerStretchModeScaleAspectFit;
        } else if ([titleString isEqualToString:@"等比充满，裁超出(2)"]) {
            mode = BDLEPlayerStretchModeScaleAspectFill;
        }
        [self.player setStretchMode:mode];
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.cmdTableView == tableView) {
        return self.cmdArray.count;
    } else if (self.logTableView == tableView) {
        return self.logArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.cmdTableView == tableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cmd_cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cmd_cell"];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 0;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        BDLEDebugItem *item = self.cmdArray[indexPath.row];
        cell.textLabel.text = item.title;
        cell.textLabel.textColor = self.cmdTableViewEnabled ? [UIColor blackColor] : [UIColor systemGrayColor];
        return cell;
    } else if (self.logTableView == tableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"log_cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"log_cell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.font = [UIFont systemFontOfSize:10];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        NSString *item = self.logArray[indexPath.row];
        cell.textLabel.text = item;
        BOOL isDarkMode = NO;
        if (@available(iOS 12.0, *)) {
            isDarkMode = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
        }
        if (indexPath.row % 2 == 0) {
            cell.backgroundColor = isDarkMode ? BDLE_colorWithRGB(0x000000) : BDLE_colorWithRGB(0xFFFFFF);
        } else {
            cell.backgroundColor = isDarkMode ? BDLE_colorWithRGB(0x222222) : BDLE_colorWithRGB(0xEDEDED);
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logTableView == tableView) {
        NSString *log = self.logArray[indexPath.row];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.alignment = NSTextAlignmentLeft;
        CGSize textSize = [log boundingRectWithSize:CGSizeMake(floor(self.view.bounds.size.width*0.7 - 32), MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10], NSParagraphStyleAttributeName: style} context:nil].size;
        return ceilf(textSize.height) + 4;
    }
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.cmdTableView == tableView) {
        BDLEDebugItem *item = self.cmdArray[indexPath.row];
        [self handleDebugItemDidSelected:item];
    }
}


#pragma mark - BDLEConnectionDelegate
- (void)bdleConnection:(BDLEConnection *)connection onError:(NSError *)error {

}

- (void)bdleConnection:(BDLEConnection *)connection didConnectToService:(BDLEService *)service {
    NSLog(@"[Demo] service connected %@", service.ipAddress);
    [self addLog:[NSString stringWithFormat:@"connect sucess to %@:%d", self.service.ipAddress, self.service.bdleSocketPort]];
    self.connectionStatus = BDLEConnectionStatusConnected;
    [self updateUIStatus];
    self.player = [[BDLEPlayer alloc] initWithConnection:self.connection];
    self.player.delegate = self;
}

- (void)bdleConnection:(BDLEConnection *)connection didDisonnectToService:(BDLEService *)service {

}

#pragma mark - BDLEPlayerDelegate
- (void)bdlePlayer:(BDLEPlayer *)player onStatusUpdate:(BDLEPlayStatus)status {
    self.currentPlayStatus = status;
    if (status == BDLEPlayStatusCompleted || status == BDLEPlayStatusStopped) {
        self.slider.value = 0;
        self.slider.enabled = NO;
    }
    [self updateStatusViewText];
}

- (void)bdlePlayer:(BDLEPlayer *)player onProgressUpdate:(NSInteger)progress duration:(NSInteger)duration {
    if (self.isSliderSliding == NO && self.player.connection.isConnected) {
        if (duration <= 0) {
            self.slider.maximumValue = 100;
            self.slider.value = 0;
        } else {
            self.slider.maximumValue = duration;
            self.slider.value = progress;
        }
    }
}

- (void)bdlePlayer:(BDLEPlayer *)player onDramaIdUpdate:(NSString *)dramaId {
    self.currentDramaId = dramaId;
    [self updateStatusViewText];
}

- (void)bdlePlayer:(BDLEPlayer *)player onMediaInfoUpdate:(BDLEPPMediaInfo *)mediaInfo {
    if (![mediaInfo isKindOfClass:[BDLEPPMediaInfo class]]) {
        return;
    }
    self.currentMediaInfo = mediaInfo;
    [self.toolboxView reloadUIWithData:self.currentMediaInfo];
    [self updateUIStatus];
}

- (void)bdlePlayer:(BDLEPlayer *)player onReceiveRuntimeInfo:(NSString *)type code:(NSInteger)code message:(NSString *)message {

}


#pragma mark - Setter
- (void)setCmdTableViewEnabled:(BOOL)cmdTableViewEnabled {
    _cmdTableViewEnabled = cmdTableViewEnabled;
    self.cmdTableView.userInteractionEnabled = cmdTableViewEnabled;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cmdTableView reloadData];
    });
}

#pragma mark - Getter
- (NSMutableArray<BDLEPPDramaBean *> *)currentDramaBeanArray {
    if (!_currentDramaBeanArray) {
        _currentDramaBeanArray = [NSMutableArray array];
    }
    return _currentDramaBeanArray;
}

- (NSMutableArray<NSString *> *)logArray {
    if (!_logArray) {
        _logArray = [[NSMutableArray alloc] init];
    }
    return _logArray;
}

- (NSArray<BDLEDebugItem *> *)cmdArray {
    if (!_cmdArray) {
        _cmdArray = @[
            [BDLEDebugItem itemWithType:BDLEDebugItemTypePlay title:@"开始播放"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypePause title:@"暂停播放"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeResume title:@"继续播放"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeStop title:@"停止播放"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypePlayPreDrama title:@"切上一集"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypePlayNextDrama title:@"切下一集"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypePlayDramaId title:@"切指定集"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeAddDramaList title:@"追加播放列表"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeDeleteDramaList title:@"删除播放列表"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeGetVolume title:@"获取音量"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeSetVolume title:@"设置音量"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeAddVolume title:@"增加音量"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeSubVolume title:@"降低音量"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeSetDanmaku title:@"设置弹幕(暂不支持)"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeSetSkipInfo title:@"设置跳过片头片尾"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeGetStatusInfo title:@"获取状态信息"],
            [BDLEDebugItem itemWithType:BDLEDebugItemTypeGetMediaInfo title:@"获取媒体信息"],
        ];
    }
    return _cmdArray;
}

- (UITableView *)logTableView {
    if (!_logTableView) {
        _logTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _logTableView.delegate = self;
        _logTableView.dataSource = self;
        _logTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _logTableView;
}

- (UITableView *)cmdTableView {
    if (!_cmdTableView) {
        _cmdTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _cmdTableView.delegate = self;
        _cmdTableView.dataSource = self;
    }
    return _cmdTableView;
}

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        _slider.minimumValue = 0;
        _slider.maximumValue = 100;
        [_slider addTarget:self action:@selector(onSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(onSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_slider addTarget:self action:@selector(onSliderTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _slider;
}

- (BDLEToolboxView *)toolboxView {
    if (!_toolboxView) {
        _toolboxView = [[BDLEToolboxView alloc] init];
        _toolboxView.delegate = self;
    }
    return _toolboxView;
}

- (UITextView *)statusTextView {
    if (!_statusTextView) {
        _statusTextView = [[UITextView alloc] init];
        _statusTextView.font = [UIFont systemFontOfSize:12];
    }
    return _statusTextView;
}

@end
