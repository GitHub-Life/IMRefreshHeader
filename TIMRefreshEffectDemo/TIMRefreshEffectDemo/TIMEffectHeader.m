//
//  TIMEffectHeader.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "TIMEffectHeader.h"
#import <Masonry.h>

typedef NS_ENUM(NSInteger, TIMContainerShowState) {
    TIMContainerShowStateInvisible = 0,     // 不可见
    TIMContainerShowStateTransitionVisible, // 过渡到可见
    TIMContainerShowStateVisible,           // 可见
    TIMContainerShowStateShowing,           // 显示中
    TIMContainerShowStateTransitionInisible,// 过渡到不可见
    TIMContainerShowStateInisible_Cycle,    // 不可见
    TIMContainerShowStateHiding,            // 隐藏中
};

@interface TIMEffectHeader ()

@property (nonatomic, strong) UIActivityIndicatorView *aiv;
@property (nonatomic, assign) CGFloat refreshThresholdPercent;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat showViewThresholdPercent;

@end

@implementation TIMEffectHeader

static CGFloat const RefreshControlHeight = 50.f;

- (void)prepare {
    [super prepare];
    self.backgroundColor = UIColor.yellowColor;
    self.clipsToBounds = YES;
    
    _containerView = [[UIView alloc] init];
    _containerView.backgroundColor = UIColor.blueColor;
    [self addSubview:_containerView];
    __weak typeof(self) weakSelf = self;
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.mj_h);
        make.leading.mas_equalTo(weakSelf.containerInsets.left);
        make.trailing.mas_equalTo(-weakSelf.containerInsets.right);
        make.height.mas_equalTo(weakSelf.mj_h - weakSelf.containerInsets.top - weakSelf.containerInsets.bottom);
    }];
    
    _aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _aiv.color = UIColor.redColor;
    [self addSubview:_aiv];
    [_aiv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(20, 20));
        make.bottom.mas_equalTo(weakSelf.containerView.mas_top).mas_offset(-(RefreshControlHeight - 20) / 2);
    }];
}

- (void)setMj_h:(CGFloat)mj_h {
    if (mj_h < RefreshControlHeight) {
        mj_h = RefreshControlHeight;
    }
    [super setMj_h:mj_h];
    [self updateContainerViewLayoutConstraints];
    self.refreshThresholdPercent = RefreshControlHeight / self.mj_h;
}

- (void)setContainerInsets:(UIEdgeInsets)containerInsets {
    _containerInsets = containerInsets;
    [self updateContainerViewLayoutConstraints];
}

- (void)updateContainerViewLayoutConstraints {
    CGFloat containerHeight = self.mj_h - self.containerInsets.top - self.containerInsets.bottom;
    if (_containerView) {
        __weak typeof(self) weakSelf = self;
        [_containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(weakSelf.mj_h);
            make.leading.mas_equalTo(weakSelf.containerInsets.left);
            make.trailing.mas_equalTo(-weakSelf.containerInsets.right);
            make.height.mas_equalTo(containerHeight);
        }];
    }
    self.showViewThresholdPercent = (RefreshControlHeight + containerHeight * 0.2) / self.mj_h;
}

#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;

    switch (state) {
        case MJRefreshStateIdle:
            [self.aiv stopAnimating];
            break;
        case MJRefreshStatePulling:
            [self.aiv stopAnimating];
            break;
        case MJRefreshStateRefreshing:
            [self.aiv startAnimating];
            break;
        default:
            break;
    }
    // 根据状态做事情
    if (state == MJRefreshStateRefreshing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                CGFloat top = self.scrollViewOriginalInset.top + (self.mj_h * self.refreshThresholdPercent);
                // 增加滚动区域top
                self.scrollView.mj_insetT = top;
                // 设置滚动位置
                CGPoint offset = self.scrollView.contentOffset;
                offset.y = -top;
                [self.scrollView setContentOffset:offset animated:NO];
            } completion:^(BOOL finished) {
                [self executeRefreshingCallback];
            }];
        });
    }
}

#pragma mark 进入刷新状态
- (void)beginRefreshing
{
    [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
        self.alpha = 1.0;
    }];
    self.pullingPercent = self.refreshThresholdPercent;
    // 只要正在刷新，就完全显示
    if (self.window) {
        self.state = MJRefreshStateRefreshing;
    } else {
        // 预防正在刷新中时，调用本方法使得header inset回置失败
        if (self.state != MJRefreshStateRefreshing) {
            self.state = MJRefreshStateWillRefresh;
            // 刷新(预防从另一个控制器回到这个控制器的情况，回来要重新刷新一下)
            [self setNeedsDisplay];
        }
    }
}

#pragma mark 监听scrollView的contentOffset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    if (self.containerView.tag >= TIMContainerShowStateShowing) {
        // 跳转到下一个控制器时，contentInset可能会变
        _scrollViewOriginalInset = self.scrollView.mj_inset;
        // 当前的contentOffset
        CGFloat offsetY = self.scrollView.mj_offsetY;
        // 头部控件刚好出现的offsetY
        CGFloat happenOffsetY = - self.scrollViewOriginalInset.top;
        
        // 正常状态的offsetY
        CGFloat normalOffsetY = happenOffsetY + self.mj_h;
        __weak typeof(self) weakSelf = self;
        if (self.scrollView.isDragging) { // 如果正在拖拽
            if (offsetY <= happenOffsetY) {
                if (self.containerView.tag != TIMContainerShowStateShowing) {
                    self.containerView.tag = TIMContainerShowStateShowing;
                    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.top.mas_equalTo(weakSelf.containerInsets.top);
                    }];
                }
            } else if (offsetY <= normalOffsetY) {
                self.containerView.tag = TIMContainerShowStateTransitionInisible;
                [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo((offsetY - happenOffsetY) * 2 + 10);
                }];
            } else {
                if (self.containerView.tag != TIMContainerShowStateInisible_Cycle) {
                    self.containerView.tag = TIMContainerShowStateInisible_Cycle;
                    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.top.mas_equalTo(weakSelf.mj_h);
                    }];
                }
            }
        } else {
//            if (self.containerView.tag > TIMContainerShowStateShowing) {
//                [self hideContainerView];
//            }
        }
        return;
    }
    // 在刷新的refreshing状态
    if (self.state == MJRefreshStateRefreshing) {
        // 暂时保留
        if (self.window == nil) return;
        
        // sectionheader停留解决
        CGFloat insetT = - self.scrollView.mj_offsetY > _scrollViewOriginalInset.top ? - self.scrollView.mj_offsetY : _scrollViewOriginalInset.top;
        insetT = insetT > (self.mj_h * self.refreshThresholdPercent) + _scrollViewOriginalInset.top ? (self.mj_h * self.refreshThresholdPercent) + _scrollViewOriginalInset.top : insetT;
        self.scrollView.mj_insetT = insetT;
        
//        self.insetTDelta = _scrollViewOriginalInset.top - insetT; // 因为是MJRefreshHeader的私有属性，所以使用KVC方式赋值
        [self setValue:@(_scrollViewOriginalInset.top - insetT) forKey:@"insetTDelta"];
        return;
    }
    
    // 跳转到下一个控制器时，contentInset可能会变
    _scrollViewOriginalInset = self.scrollView.mj_inset;
    // 当前的contentOffset
    CGFloat offsetY = self.scrollView.mj_offsetY;
    // 头部控件刚好出现的offsetY
    CGFloat happenOffsetY = - self.scrollViewOriginalInset.top;
    
    // 如果是向上滚动到看不见头部控件，直接返回
    // >= -> >
    if (offsetY > happenOffsetY) return;
    
    
    // 正常状态 到 即将刷新 的临界点
    CGFloat normal2pullingOffsetY = happenOffsetY - self.mj_h * self.refreshThresholdPercent;
    // 即将刷新 到 显示ContainerView 的临界点
    CGFloat pulling2showViewOffsetY = happenOffsetY - (self.mj_h * self.showViewThresholdPercent);
    CGFloat pullingPercent = (happenOffsetY - offsetY) / self.mj_h;
    
    if (self.scrollView.isDragging) { // 如果正在拖拽
        self.pullingPercent = pullingPercent;
        if (self.state == MJRefreshStateIdle && offsetY <= normal2pullingOffsetY && offsetY > pulling2showViewOffsetY) {
            // 转为即将刷新状态
            self.state = MJRefreshStatePulling;
        } else if (self.state == MJRefreshStatePulling && (offsetY > normal2pullingOffsetY || offsetY <= pulling2showViewOffsetY)) {
            // 转为普通状态
            self.state = MJRefreshStateIdle;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        [self beginRefreshing];
    } else if (pullingPercent < self.refreshThresholdPercent) {
        self.pullingPercent = pullingPercent;
    } else if (pullingPercent < self.showViewThresholdPercent) {
        [self showContainerView];
    }
}

#pragma mark - 滑动状态改变
- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];
    if (change && change[@"new"]) {
        if ([change[@"new"] integerValue] == UIGestureRecognizerStateEnded) {
            if (self.containerView.tag > TIMContainerShowStateShowing) {
                [self hideContainerView];
            }
        }
    }
}

- (void)setPullingPercent:(CGFloat)pullingPercent {
    [super setPullingPercent:pullingPercent];
    __weak typeof(self) weakSelf = self;
    if (pullingPercent <= self.refreshThresholdPercent) {
        if (self.containerView.tag != TIMContainerShowStateInvisible && self.containerView.tag < TIMContainerShowStateShowing) {
            self.containerView.tag = TIMContainerShowStateInvisible;
            [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(weakSelf.mj_h);
            }];
        }
    } else if (pullingPercent <= 1.f) {
        CGFloat percent = (pullingPercent - self.refreshThresholdPercent) / (1.f - self.refreshThresholdPercent);
        self.containerView.tag = TIMContainerShowStateTransitionVisible;
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo((weakSelf.mj_h - weakSelf.containerInsets.top) * (1 - percent) + weakSelf.containerInsets.top);
        }];
    } else {
        if (self.containerView.tag != TIMContainerShowStateVisible) {
            self.containerView.tag = TIMContainerShowStateVisible;
            [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(weakSelf.containerInsets.top);
            }];
        }
    }
}

- (void)showContainerView {
    self.containerView.tag = TIMContainerShowStateShowing;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            CGFloat top = weakSelf.scrollViewOriginalInset.top + weakSelf.mj_h;
            // 增加滚动区域top
            weakSelf.scrollView.mj_insetT = top;
            // 设置滚动位置
            CGPoint offset = weakSelf.scrollView.contentOffset;
            offset.y = -top;
            [weakSelf.scrollView setContentOffset:offset animated:NO];
            [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(weakSelf.containerInsets.top);
            }];
        }];
    });
}

- (void)hideContainerView {
    if (self.containerView.tag != TIMContainerShowStateHiding) {
        self.containerView.tag = TIMContainerShowStateHiding;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                CGFloat top = weakSelf.mj_h - weakSelf.scrollViewOriginalInset.top;
                // 增加滚动区域top
                weakSelf.scrollView.mj_insetT = -top;
                // 设置滚动位置
                CGPoint offset = weakSelf.scrollView.contentOffset;
                offset.y = top;
                [weakSelf.scrollView setContentOffset:offset animated:NO];
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.mj_h);
                }];
                [weakSelf layoutIfNeeded];
            } completion:^(BOOL finished) {
                weakSelf.containerView.tag = TIMContainerShowStateInvisible;
            }];
        });
    }
}

@end
