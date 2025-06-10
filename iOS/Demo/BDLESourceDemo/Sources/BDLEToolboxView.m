//
//  BDLEToolboxView.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "BDLEToolboxView.h"
#import <Masonry/Masonry.h>

#import <BDLESource/BDLEPrivateProtocol.h>

@implementation BDLEDebugItem

+ (instancetype)itemWithType:(BDLEDebugItemType)type title:(NSString *)title {
    BDLEDebugItem *item = [[BDLEDebugItem alloc] init];
    item.type = type;
    item.title = title;
    return item;
}

@end

// 工具栏，支持：设置倍速、清晰度、字幕、弹幕、循环随机模式、拉伸
@interface BDLEToolboxView ()

@property (nonatomic, strong) UIButton *speedBtn;
@property (nonatomic, strong) UIButton *resolutionBtn;
@property (nonatomic, strong) UIButton *subtitleBtn;
@property (nonatomic, strong) UIButton *loopModeBtn;
@property (nonatomic, strong) UIButton *shuffleBtn;
@property (nonatomic, strong) UIButton *stretchBtn;

@end

@implementation BDLEToolboxView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSArray *btnToAdd = @[
            self.speedBtn,
            self.resolutionBtn,
            self.subtitleBtn,
            self.loopModeBtn,
            self.shuffleBtn,
            self.stretchBtn
        ];

        for (UIButton *btn in btnToAdd) {
            [self addSubview:btn];
        }

        [btnToAdd mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:0 leadSpacing:32 tailSpacing:32];
        [btnToAdd mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(44);
        }];
    }
    return self;
}

- (void)reloadUIWithData:(BDLEPPMediaInfo *)mediaInfo {
    if (mediaInfo) {
        self.speedBtn.enabled = YES;
        self.resolutionBtn.enabled = YES;
        self.subtitleBtn.enabled = YES;
        self.loopModeBtn.enabled = YES;
        self.shuffleBtn.enabled = YES;
        self.stretchBtn.enabled = YES;

        [self.speedBtn setTitle:[NSString stringWithFormat:@"倍速\n(%.2f)", mediaInfo.speed] forState:UIControlStateNormal];
        [self.resolutionBtn setTitle:[NSString stringWithFormat:@"清晰度\n(%@)", mediaInfo.resolution] forState:UIControlStateNormal];
        [self.subtitleBtn setTitle:[NSString stringWithFormat:@"字幕\n(%@)", mediaInfo.subtitle.switchStatus == 0 ? @"关" : @"开"] forState:UIControlStateNormal];
        [self.loopModeBtn setTitle:[NSString stringWithFormat:@"循环\n(%ld)", mediaInfo.loopMode] forState:UIControlStateNormal];
        [self.shuffleBtn setTitle:[NSString stringWithFormat:@"随机\n(%ld)", mediaInfo.shuffle] forState:UIControlStateNormal];
        [self.stretchBtn setTitle:[NSString stringWithFormat:@"拉伸\n(%ld)", mediaInfo.stretch] forState:UIControlStateNormal];
    } else {
        self.speedBtn.enabled = NO;
        self.resolutionBtn.enabled = NO;
        self.subtitleBtn.enabled = NO;
        self.loopModeBtn.enabled = NO;
        self.shuffleBtn.enabled = NO;
        self.stretchBtn.enabled = NO;

        [self.speedBtn setTitle:@"倍速" forState:UIControlStateNormal];
        [self.resolutionBtn setTitle:@"清晰度" forState:UIControlStateNormal];
        [self.subtitleBtn setTitle:@"字幕" forState:UIControlStateNormal];
        [self.loopModeBtn setTitle:@"循环" forState:UIControlStateNormal];
        [self.shuffleBtn setTitle:@"随机" forState:UIControlStateNormal];
        [self.stretchBtn setTitle:@"拉伸" forState:UIControlStateNormal];
    }
}

- (void)onSpeed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectSpeed)]) {
        [self.delegate toolboxDidSelectSpeed];
    }
}

- (void)onResolution:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectResolution)]) {
        [self.delegate toolboxDidSelectResolution];
    }
}

- (void)onSubtitle:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectSubtitle)]) {
        [self.delegate toolboxDidSelectSubtitle];
    }
}

- (void)onLoopMode:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectLoopMode)]) {
        [self.delegate toolboxDidSelectLoopMode];
    }
}

- (void)onShuffle:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectShuffle)]) {
        [self.delegate toolboxDidSelectShuffle];
    }
}

- (void)onStretch:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toolboxDidSelectStretch)]) {
        [self.delegate toolboxDidSelectStretch];
    }
}

- (UIButton *)createBtn:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    btn.titleLabel.numberOfLines = 0;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [btn setTitle:title ?: @"" forState:UIControlStateNormal];
    return btn;
}

- (UIButton *)speedBtn {
    if (!_speedBtn) {
        _speedBtn = [self createBtn:@"倍速"];
        [_speedBtn addTarget:self action:@selector(onSpeed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _speedBtn;
}

- (UIButton *)resolutionBtn {
    if (!_resolutionBtn) {
        _resolutionBtn = [self createBtn:@"清晰度"];
        [_resolutionBtn addTarget:self action:@selector(onResolution:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resolutionBtn;
}

- (UIButton *)subtitleBtn {
    if (!_subtitleBtn) {
        _subtitleBtn = [self createBtn:@"字幕"];
        [_subtitleBtn addTarget:self action:@selector(onSubtitle:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _subtitleBtn;
}

- (UIButton *)loopModeBtn {
    if (!_loopModeBtn) {
        _loopModeBtn = [self createBtn:@"循环"];
        [_loopModeBtn addTarget:self action:@selector(onLoopMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loopModeBtn;
}

- (UIButton *)shuffleBtn {
    if (!_shuffleBtn) {
        _shuffleBtn = [self createBtn:@"随机"];
        [_shuffleBtn addTarget:self action:@selector(onShuffle:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shuffleBtn;
}

- (UIButton *)stretchBtn {
    if (!_stretchBtn) {
        _stretchBtn = [self createBtn:@"拉伸"];
        [_stretchBtn addTarget:self action:@selector(onStretch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stretchBtn;
}

@end
