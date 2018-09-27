//
//  IMInteractiveRefreshHeader.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "IMInteractiveRefreshHeader.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Masonry.h>

@interface IMInteractiveRefreshHeader ()

@property (nonatomic, strong) UIActivityIndicatorView *aiv;
@property (nonatomic, strong) UIView *refreshContainerView;
@property (nonatomic, strong) UIImageView *arrowImgView;
@property (nonatomic, assign) CGFloat refreshThresholdPercent;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat showViewThresholdPercent;

@property (nonatomic, assign) CGFloat showViewInsetTDelta;

@end

@implementation IMInteractiveRefreshHeader

static CGFloat const RefreshControlHeight = 54.f;

#pragma mark - 懒加载
- (UIActivityIndicatorView *)aiv {
    if (!_aiv) {
        _aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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
    }
    return _containerView;
}

#pragma mark - 准备工作(添加子视图等工作)
- (void)prepare {
    [super prepare];
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

#pragma mark - 属性设置
/** 设置状态标题 */
- (void)setStatetTitle:(NSString *)statetTitle {
    _statetTitle = statetTitle;
    self.stateLabel.text = statetTitle;
    [self.stateLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(statetTitle.length ? 0 : 10);
    }];
}

/** 设置刷新空间的颜色(箭头、状态标题、LoadingView的颜色) */
- (void)setRefreshColor:(UIColor *)refreshColor {
    _refreshColor = refreshColor ?: UIColor.grayColor;
    self.aiv.color = refreshColor;
    self.stateLabel.textColor = refreshColor;
    self.arrowImgView.tintColor = refreshColor;
}

/** 添加可交互的ContentView */
- (void)addContentView:(UIView *)contentView {
    [self.containerView addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

/** 设置RefreshHeader的高度 */
- (void)setMj_h:(CGFloat)mj_h {
    if (mj_h < RefreshControlHeight) {
        mj_h = RefreshControlHeight;
    }
    [super setMj_h:mj_h];
    [self updateContainerViewLayoutConstraints];
    self.refreshThresholdPercent = RefreshControlHeight / self.mj_h;
}

/** 设置可交互View的边距 */
- (void)setContainerInsets:(UIEdgeInsets)containerInsets {
    _containerInsets = containerInsets;
    [self updateContainerViewLayoutConstraints];
}

/** 更新可交互View容器View的约束 */
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
    if (self.interactiveShowState >= IMInteractiveShowStateShowing) {
        // 当前的contentOffset
        CGFloat offsetY = self.scrollView.mj_offsetY;
        // 头部控件刚好出现的offsetY
        CGFloat happenOffsetY = - _scrollViewOriginalInset.top;
        
        // 正常状态的offsetY
        CGFloat normalOffsetY = happenOffsetY - self.mj_h;
        if (self.scrollView.isDragging) { // 如果正在拖拽
            if (offsetY <= normalOffsetY) {
                self.interactiveShowState = IMInteractiveShowStateShowing;
            } else if (offsetY <= happenOffsetY) {
                self.interactiveShowState = IMInteractiveShowStateTransitionHide;
                [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo((offsetY - normalOffsetY) * 2 + 10);
                }];
            } else {
                self.interactiveShowState = IMInteractiveShowStateHide;
            }
        }
        
        if (self.interactiveShowState > IMInteractiveShowStateShowing) {
            // 暂时保留
            if (self.window == nil) return;
            // sectionheader停留解决
            CGFloat insetT = - self.scrollView.mj_offsetY > _scrollViewOriginalInset.top ? - self.scrollView.mj_offsetY : _scrollViewOriginalInset.top;
            insetT = insetT > self.mj_h + _scrollViewOriginalInset.top ? self.mj_h + _scrollViewOriginalInset.top : insetT;
            self.scrollView.mj_insetT = insetT;
            self.showViewInsetTDelta = _scrollViewOriginalInset.top - insetT;
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
    CGFloat happenOffsetY = - _scrollViewOriginalInset.top;
    // 如果是向上滚动到看不见头部控件，直接返回
    // >= -> >
    if (offsetY > happenOffsetY) return;
    
    CGFloat pullingPercent = (happenOffsetY - offsetY) / self.mj_h;
    if (self.scrollView.isDragging) { // 如果正在拖拽
        self.pullingPercent = pullingPercent;
        if (self.state == MJRefreshStateIdle
            && pullingPercent >= self.refreshThresholdPercent
            && pullingPercent < self.showViewThresholdPercent) {
            // 转为即将刷新状态
            self.state = MJRefreshStatePulling;
        } else if (self.state == MJRefreshStatePulling && (pullingPercent < self.refreshThresholdPercent || pullingPercent >= self.showViewThresholdPercent)) {
            // 转为普通状态
            self.state = MJRefreshStateIdle;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        [self beginRefreshing];
    } else {
        self.pullingPercent = pullingPercent;
    }
}

#pragma mark - 设置ContainerView 显示的百分比
- (void)setPullingPercent:(CGFloat)pullingPercent {
    [super setPullingPercent:pullingPercent];
    __weak typeof(self) weakSelf = self;
    if (pullingPercent <= self.refreshThresholdPercent) {
        self.refreshContainerView.alpha = 1.f;
        if (self.interactiveShowState < IMInteractiveShowStateShowing) {
            self.interactiveShowState = IMInteractiveShowStateInvisible;
        }
    } else if (pullingPercent < 1.f) {
        self.interactiveShowState = pullingPercent < self.showViewThresholdPercent ? IMInteractiveShowStateTransitionVisible : IMInteractiveShowStateCanVisible;
        CGFloat percent = (pullingPercent - self.refreshThresholdPercent) / (1.f - self.refreshThresholdPercent);
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo((weakSelf.mj_h - weakSelf.containerInsets.top) * (1 - percent) + weakSelf.containerInsets.top);
        }];
        self.refreshContainerView.alpha = 1 - (pullingPercent - self.refreshThresholdPercent) / (self.showViewThresholdPercent - self.refreshThresholdPercent);
    } else {
        self.interactiveShowState = IMInteractiveShowStateVisible;
    }
}

#pragma mark - 滑动状态改变
- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];
    if (change && change[@"new"]) {
        if ([change[@"new"] integerValue] == UIGestureRecognizerStateEnded) {
            if (self.interactiveShowState > IMInteractiveShowStateShowing) {
                [self hideContainerView];
            } else if (self.interactiveShowState > IMInteractiveShowStateTransitionVisible && self.interactiveShowState < IMInteractiveShowStateShowing) {
                [self showContainerView];
            }
        }
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
                    if (weakSelf.state != MJRefreshStateIdle) return;
                    
                    weakSelf.aiv.alpha = 1.f;
                    [weakSelf.aiv stopAnimating];
                    weakSelf.arrowImgView.hidden = NO;
                    weakSelf.arrowImgView.transform = CGAffineTransformIdentity;
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
- (void)setInteractiveShowState:(IMInteractiveShowState)interactiveShowState {
    if (_interactiveShowState == interactiveShowState) return;
    _interactiveShowState = interactiveShowState;
    
    __weak typeof(self) weakSelf = self;
    switch (_interactiveShowState) {
        case IMInteractiveShowStateInvisible:
        case IMInteractiveShowStateHide: {
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.mj_h);
                }];
            }];
        } break;
        case IMInteractiveShowStateVisible:
        case IMInteractiveShowStateShowing: {
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.containerInsets.top);
                }];
            }];
        } break;
        case IMInteractiveShowStateCanVisible: {
            if (@available(iOS 10.0, *)) {
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
            } else {
                AudioServicesPlaySystemSound(1519);
            }
        } break;
        default:
            break;
    }
}

#pragma mark - 显示ContainerView
- (void)showContainerView {
    self.interactiveShowState = IMInteractiveShowStateShowing;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            CGFloat top = weakSelf.scrollViewOriginalInset.top + weakSelf.mj_h;
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
        } completion:^(BOOL finished) {
            if (weakSelf.containerView.mj_y != weakSelf.containerInsets.top) {
                [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                    [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.top.mas_equalTo(weakSelf.containerInsets.top);
                    }];
                    [weakSelf layoutIfNeeded];
                }];
            }
        }];
    });
}

#pragma mark - 隐藏ContainerView
- (void)hideContainerView {
    if (self.interactiveShowState != IMInteractiveShowStateHiding) {
        self.interactiveShowState = IMInteractiveShowStateHiding;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                weakSelf.scrollView.mj_insetT += self.showViewInsetTDelta;
                // 设置滚动位置
                CGPoint offset = weakSelf.scrollView.contentOffset;
                offset.y = - weakSelf.scrollViewOriginalInset.top;
                [weakSelf.scrollView setContentOffset:offset animated:NO];
                [weakSelf.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.mas_equalTo(weakSelf.mj_h);
                }];
                [weakSelf layoutIfNeeded];
            } completion:^(BOOL finished) {
                weakSelf.interactiveShowState = IMInteractiveShowStateInvisible;
            }];
        });
    }
}

@end
