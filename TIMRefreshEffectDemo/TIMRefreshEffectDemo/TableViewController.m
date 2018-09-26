//
//  TableViewController.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "TableViewController.h"

#import "TIMEffectHeader.h"

static NSString *const HeaderIdentifier = @"HeaderIdentifier";
static NSString *const CellIdentifier = @"CellIdentifier";

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

- (void)initView {
    [self.tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:HeaderIdentifier];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:CellIdentifier];
    [self.tableView setRowHeight:150];
    [self.tableView setSectionHeaderHeight:40];
    TIMEffectHeader *header = [TIMEffectHeader headerWithRefreshingBlock:^{
        NSLog(@" -  - ");
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.tableView.mj_header endRefreshing];
        });
    }];
    header.containerInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    header.mj_h = 150;
    header.title = @"下拉刷新看看哈";
    header.refreshColor = UIColor.redColor;
    self.tableView.mj_header = header;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView.mj_header beginRefreshing];
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

#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderIdentifier];
    headerView.textLabel.text = @"Section Header";
    return headerView;
}

@end
