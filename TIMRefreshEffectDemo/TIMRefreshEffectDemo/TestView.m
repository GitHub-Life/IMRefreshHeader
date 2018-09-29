//
//  TestView.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/28.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "TestView.h"

@implementation TestView

- (instancetype)init {
    self = [[[UINib nibWithNibName:@"TestView" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
    return self;
}

- (IBAction)btnClick:(UIButton *)sender {
    NSLog(@" - btn.tag = %d", (int)sender.tag);
}

@end
