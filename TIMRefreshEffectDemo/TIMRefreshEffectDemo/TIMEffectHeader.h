//
//  TIMEffectHeader.h
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "MJRefreshHeader.h"

@interface TIMEffectHeader : MJRefreshHeader

@property (nonatomic, strong) UIActivityIndicatorView *aiv;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *refreshColor;

@property (nonatomic, assign) UIEdgeInsets containerInsets;
- (void)addContentView:(UIView *)contentView;

@end
