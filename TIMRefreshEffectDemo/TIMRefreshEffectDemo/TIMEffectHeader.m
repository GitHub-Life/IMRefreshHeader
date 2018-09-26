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
    TIMContainerShowStateTransitionHide,    // 过渡到隐藏
    TIMContainerShowStateHide,              // 隐藏
    TIMContainerShowStateHiding,            // 隐藏中
};

@interface TIMEffectHeader ()

@property (nonatomic, strong) UIView *refreshContainerView;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UIImageView *arrowImgView;
@property (nonatomic, assign) CGFloat refreshThresholdPercent;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat showViewThresholdPercent;

@property (nonatomic, assign) TIMContainerShowState containerShowState;

@end

@implementation TIMEffectHeader

static CGFloat const RefreshControlHeight = 50.f;

- (UIActivityIndicatorView *)aiv {
    if (!_aiv) {
        _aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _aiv.color = UIColor.blackColor;
        _aiv.hidesWhenStopped = YES;
    }
    return _aiv;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [UILabel mj_label];
    }
    return _stateLabel;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = UIColor.blueColor;
    }
    return _containerView;
}

#pragma mark - 准备工作(添加子视图等工作)
- (void)prepare {
    [super prepare];
    self.backgroundColor = UIColor.yellowColor;
    self.clipsToBounds = YES;
    
    __weak typeof(self) weakSelf = self;
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.mj_h);
        make.leading.mas_equalTo(weakSelf.containerInsets.left);
        make.trailing.mas_equalTo(-weakSelf.containerInsets.right);
        make.height.mas_equalTo(weakSelf.mj_h - weakSelf.containerInsets.top - weakSelf.containerInsets.bottom);
    }];
    
    _refreshContainerView = [[UIView alloc] init];
    [self addSubview:_refreshContainerView];
    [_refreshContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.height.mas_equalTo(20.f);
        make.bottom.mas_equalTo(weakSelf.containerView.mas_top).mas_offset(-(RefreshControlHeight - 20.f) / 2);
    }];
    
    [_refreshContainerView addSubview:self.aiv];
    [self.aiv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.leading.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.width.mas_equalTo(20.f);
    }];
    
    _arrowImgView = [[UIImageView alloc] initWithImage:[NSBundle mj_arrowImage]];
    [_arrowImgView setContentMode:UIViewContentModeScaleAspectFit];
    [_refreshContainerView addSubview:_arrowImgView];
    [_arrowImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(-10);
        make.leading.mas_equalTo(-10);
        make.bottom.mas_equalTo(10);
        make.width.mas_equalTo(40.f);
    }];
    
    [_refreshContainerView addSubview:self.stateLabel];
    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.trailing.mas_equalTo(10);
        make.bottom.mas_equalTo(0);
        make.leading.mas_equalTo(weakSelf.arrowImgView.mas_trailing);
    }];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.stateLabel.text = title;
    [self.stateLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(title.length ? 0 : 10);
    }];
}

- (void)setRefreshColor:(UIColor *)refreshColor {
    _refreshColor = refreshColor ?: UIColor.grayColor;
    self.aiv.color = refreshColor;
    self.stateLabel.textColor = refreshColor;
    self.arrowImgView.tintColor = refreshColor;
}

- (void)addContentView:(UIView *)contentView {
    [self.containerView addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
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
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(weakSelf.mj_h);
            make.leading.mas_equalTo(weakSelf.containerInsets.left);
            make.trailing.mas_equalTo(-weakSelf.containerInsets.right);
            make.height.mas_equalTo(containerHeight);
        }];
    }
    self.showViewThresholdPercent = (RefreshControlHeight + containerHeight * 0.2) / self.mj_h;
}

#pragma mark 监听scrollView的contentOffset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    if (self.containerShowState >= TIMContainerShowStateShowing) {
        // 跳转到下一个控制器时，contentInset可能会变
        _scrollViewOriginalInset = self.scrollView.mj_inset;
        // 当前的contentOffset
        CGFloat offsetY = self.scrollView.mj_offsetY;
        // 头部控件刚好出现的offsetY
        CGFloat happenOffsetY = - self.scrollViewOriginalInset.top;
        
        // 正常状态的offsetY
        CGFloat normalOffsetY = happenOffsetY + self.mj_h;
        if (self.scrollView.isDragging) { // 如果正在拖拽
            if (offsetY <= happenOffsetY) {
                self.containerShowState = TIMContainerShowStateShowing;
            } else if (offsetY <= normalOffsetY) {
                self.containerShowState = TIMContainerShowStateTransitionHide;
                [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo((offsetY - happenOffsetY) * 2 + 10);
                }];
            } else {
                self.containerShowState = TIMContainerShowStateHide;
            }
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
            if (self.containerShowState > TIMContainerShowStateShowing) {
                [self hideContainerView];
            }
        }
    }
}

#pragma mark - 设置ContainerView 显示的百分比
- (void)setPullingPercent:(CGFloat)pullingPercent {
    [super setPullingPercent:pullingPercent];
    __weak typeof(self) weakSelf = self;
    if (pullingPercent <= self.refreshThresholdPercent) {
        self.refreshContainerView.alpha = 1.f;
        if (self.containerShowState < TIMContainerShowStateShowing) {
            self.containerShowState = TIMContainerShowStateInvisible;
        }
    } else if (pullingPercent <= 1.f) {
        CGFloat percent = (pullingPercent - self.refreshThresholdPercent) / (1.f - self.refreshThresholdPercent);
        self.refreshContainerView.alpha = 1 - percent * 2;
        self.containerShowState = TIMContainerShowStateTransitionVisible;
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo((weakSelf.mj_h - weakSelf.containerInsets.top) * (1 - percent) + weakSelf.containerInsets.top);
        }];
    } else {
        self.containerShowState = TIMContainerShowStateVisible;
    }
}

#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state {
    MJRefreshCheckState;
    // 根据状态做事情
    __weak typeof(self) weakSelf = self;
    switch (state) {
        case MJRefreshStateIdle: {
            if (oldState == MJRefreshStateRefreshing) {
                [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                    weakSelf.aiv.alpha = 0.f;
                } completion:^(BOOL finished) {
                    // 如果执行完动画发现不是idle状态，就直接返回，进入其他状态
                    if (self.state != MJRefreshStateIdle) return;
                    
                    weakSelf.aiv.alpha = 1.f;
                    [weakSelf.aiv stopAnimating];
                    weakSelf.arrowImgView.hidden = NO;
                }];
            } else {
                [self.aiv stopAnimating];
                self.arrowImgView.hidden = NO;
                [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                    weakSelf.arrowImgView.transform = CGAffineTransformIdentity;
                }];
            }
        } break;
        case MJRefreshStatePulling: {
            [self.aiv stopAnimating];
            self.arrowImgView.hidden = NO;
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                weakSelf.arrowImgView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
            }];
        } break;
        case MJRefreshStateRefreshing: {
            self.aiv.alpha = 1.0; // 防止refreshing -> idle的动画完毕动作没有被执行
            [self.aiv startAnimating];
            self.arrowImgView.hidden = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                    CGFloat top = weakSelf.scrollViewOriginalInset.top + (weakSelf.mj_h * weakSelf.refreshThresholdPercent);
                    // 增加滚动区域top
                    weakSelf.scrollView.mj_insetT = top;
                    // 设置滚动位置
                    CGPoint offset = weakSelf.scrollView.contentOffset;
                    offset.y = -top;
                    [weakSelf.scrollView setContentOffset:offset animated:NO];
                }];
            });
        } break;
        default:
            break;
    }
}

#pragma mark 进入刷新状态
- (void)beginRefreshing {
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

#pragma mark 监听ContainerView的显示状态
- (void)setContainerShowState:(TIMContainerShowState)containerShowState {
    if (_containerShowState == containerShowState) return;
    _containerShowState = containerShowState;
    
    __weak typeof(self) weakSelf = self;
    switch (_containerShowState) {
        case TIMContainerShowStateInvisible:
        case TIMContainerShowStateHide: {
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.mj_h);
                }];
            }];
        } break;
        case TIMContainerShowStateVisible:
        case TIMContainerShowStateShowing: {
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.containerInsets.top);
                }];
            }];
        } break;
        default:
            break;
    }
}

#pragma mark - 显示ContainerView
- (void)showContainerView {
    self.containerShowState = TIMContainerShowStateShowing;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat top = weakSelf.scrollViewOriginalInset.top + weakSelf.mj_h;
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            // 增加滚动区域top
            weakSelf.scrollView.mj_insetT = top;
            CGPoint offset = weakSelf.scrollView.contentOffset;
            offset.y = -top;
            // 设置滚动位置
            [weakSelf.scrollView setContentOffset:offset];
            [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(weakSelf.containerInsets.top);
            }];
            [weakSelf layoutIfNeeded];
        }];
    });
}

#pragma mark - 隐藏ContainerView
- (void)hideContainerView {
    if (self.containerShowState != TIMContainerShowStateHiding) {
        self.containerShowState = TIMContainerShowStateHiding;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
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
                weakSelf.containerShowState = TIMContainerShowStateInvisible;
            }];
        });
    }
}

@end
