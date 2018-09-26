//
//  TableViewController.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "TableViewController.h"

#import "TIMEffectHeader.h"

static NSString *const CellIdentifier = @"CellIdentifier";

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

- (void)initView {
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:CellIdentifier];
    TIMEffectHeader *header = [TIMEffectHeader headerWithRefreshingBlock:^{
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.tableView.mj_header endRefreshing];
        });
    }];
    header.containerInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    header.mj_h = 150;
    self.tableView.mj_header = header;
}

#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@" - %d, %d - ", (int)indexPath.section, (int)indexPath.row];
    return cell;
}

@end
