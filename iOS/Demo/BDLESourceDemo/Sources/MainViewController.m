//
//  MainViewController.m
//  BDLESource
//
//  Created by ByteDance on 2025/5/24.
//  Copyright (c) 2025 Bytedance Ltd. and/or its affiliates All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import "MainViewController.h"
#import "BDLEViewController.h"
#import <Masonry/Masonry.h>

#import <BDLESource/BDLEBrowser.h>
#import <BDLESource/BDLEService.h>

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource, BDLEBrowserDelegate>

@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UITableView *mainTableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, strong) NSMutableArray<BDLEService *> *serviceArray;
@property (nonatomic, strong) BDLEBrowser *browser;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
}

- (void)buildUI {
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.searchBtn];
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(64);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(44);
    }];

    [self.view addSubview:self.mainTableView];
    [self.mainTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchBtn.mas_bottom).offset(12);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.view addSubview:self.emptyLabel];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mainTableView);
        make.centerY.equalTo(self.mainTableView).offset(-64);
    }];
}

- (void)onSearch:(id)sender {
    [self.searchBtn setTitle:(self.isSearching ? @"开始搜索" : @"停止搜索") forState:UIControlStateNormal];
    if (self.isSearching) {
        NSLog(@"[Demo] stop search");
        self.isSearching = NO;
        [self.browser stopSearch];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.serviceArray removeAllObjects];
            [self.mainTableView reloadData];
        });
    } else {
        NSLog(@"[Demo] start search");
        self.isSearching = YES;
        [self.browser searchServices];
    }
    [self updateEmptyLabelVisible];
}

- (void)updateEmptyLabelVisible {
    BOOL showEmptyLabel = (self.isSearching && self.serviceArray.count == 0);
    self.emptyLabel.hidden = !showEmptyLabel;
}

#pragma mark - BDLEBrowserDelegate
- (void)bdleBrowser:(BDLEBrowser *)browser didFindBDLEServices:(NSArray<BDLEService *> *)services {
    for (BDLEService *service in services) {
        NSLog(@"[Demo] didFindService addr:%@, name:%@, uuid:%@, bdlePort: %d", service.ipAddress, service.serviceName, service.serviceRef, service.bdleSocketPort);
        BOOL contain = NO;
        for (BDLEService *aService in self.serviceArray) {
            if ([aService isEqual:service]) {
                contain = YES;
                break;
            }
        }
        if (!contain) {
            [self.serviceArray addObject:service];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mainTableView reloadData];
        [self updateEmptyLabelVisible];
    });
}

- (void)bdleBrowser:(BDLEBrowser *)browser unavailableBDLEService:(BDLEService *)service {
    NSLog(@"[Demo] unavailableBDLEService addr:%@, name:%@, uuid:%@, bdlePort: %d", service.ipAddress, service.serviceName, service.serviceRef, service.bdleSocketPort);
    BDLEService *serviceToRemove = nil;
    for (BDLEService *aService in self.serviceArray) {
        if ([aService isEqual:service]) {
            serviceToRemove = aService;
            break;
        }
    }
    if (serviceToRemove) {
        [self.serviceArray removeObject:serviceToRemove];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mainTableView reloadData];
        [self updateEmptyLabelVisible];
    });
}


#pragma mark - UITableViewDelegate & UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self updateEmptyLabelVisible];
    return self.serviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
    }
    BDLEService *service = [self.serviceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", service.serviceName, service.ipAddress];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BDLEService *service = [self.serviceArray objectAtIndex:indexPath.row];
    BDLEViewController *vc = [[BDLEViewController alloc] initWithService:service];
    [self.navigationController pushViewController:vc animated:YES];
}

- (BDLEBrowser *)browser {
    if (!_browser) {
        _browser = [[BDLEBrowser alloc] init];
        _browser.delegate = self;
    }
    return _browser;
}

- (UIButton *)searchBtn {
    if (!_searchBtn) {
        _searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _searchBtn.layer.cornerRadius = 8.0f;
        _searchBtn.layer.borderColor = [UIColor blackColor].CGColor;
        _searchBtn.layer.borderWidth = 1.0f;
        _searchBtn.layer.masksToBounds = YES;
        _searchBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_searchBtn setTitle:@"开始搜索" forState:UIControlStateNormal];
        [_searchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_searchBtn addTarget:self action:@selector(onSearch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _searchBtn;
}

- (UITableView *)mainTableView {
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _mainTableView.delegate = self;
        _mainTableView.dataSource = self;
    }
    return _mainTableView;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.font = [UIFont systemFontOfSize:14];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.text = @"暂未发现可用设备";
    }
    return _emptyLabel;
}

- (NSMutableArray *)serviceArray {
    if (!_serviceArray) {
        _serviceArray = [[NSMutableArray alloc] init];
    }
    return _serviceArray;
}

@end
