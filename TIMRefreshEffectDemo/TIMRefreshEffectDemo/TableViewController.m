//
//  TableViewController.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "TableViewController.h"

#import "IMInteractiveRefreshHeader.h"

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
    IMInteractiveRefreshHeader *header = [IMInteractiveRefreshHeader headerWithRefreshingBlock:^{
        NSLog(@" -  - ");
    }];
    header.containerInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    header.mj_h = 100;
    header.statetTitle = @"下拉刷新看看哈";
    header.refreshColor = UIColor.redColor;
    header.backgroundColor = UIColor.yellowColor;
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = UIColor.blueColor;
    [header addContentView:contentView];
    self.tableView.mj_header = header;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@" - tableView.mj_inset = %@", NSStringFromUIEdgeInsets(self.tableView.mj_inset));
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
    if (self.tableView.mj_header.isRefreshing) {
        [self.tableView.mj_header endRefreshing];
    } else {
        [self.tableView.mj_header beginRefreshing];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderIdentifier];
    headerView.textLabel.text = @"Section Header";
    return headerView;
}

@end
