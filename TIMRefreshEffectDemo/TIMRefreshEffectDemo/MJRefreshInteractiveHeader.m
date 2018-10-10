//
//  MJRefreshInteractiveHeader.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/28.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "MJRefreshInteractiveHeader.h"

#define InteractiveViewInitOffsetY self.mj_h
#define InteractiveViewRemainHeight MAX(20.f, self.interactiveView.mj_h * 0.1f)
#define InteractiveViewShowThreshold MAX(40.f, self.interactiveView.mj_h * 0.2f)

@interface MJRefreshInteractiveHeader ()

@property (nonatomic, assign) CGFloat befroeInteractiveOffsetY;

/** InteractiveView显示时上滑隐藏动效中ScrollView的顶部内边距偏移量(在执行隐藏动画时需要使用计算) */
@property (nonatomic, assign) CGFloat interactiveShowInsetTDelta;
/** InteractiveView全显示时，ScrollView的顶部内边距 */
@property (nonatomic, assign) CGFloat interactiveFullVisibleScrollInsetsTop;

/** 标记InteractiveView是否正处于 显示←→隐藏 之间 */
@property (nonatomic, assign) BOOL interactiveShowHideAnimationing;

@end

@implementation MJRefreshInteractiveHeader

- (void)placeSubviews {
    [super placeSubviews];
    if (_interactiveView) {
        _interactiveView.mj_w = self.scrollView.mj_w;
        _interactiveView.mj_y = InteractiveViewInitOffsetY;
        _interactiveView.mj_x = -self.mj_x;
    }
    CALayer *maskLayer = self.layer.mask;
    if (!maskLayer) {
        maskLayer = [CALayer layer];
        maskLayer.backgroundColor = UIColor.blackColor.CGColor;
        self.layer.mask = maskLayer;
    }
    maskLayer.frame = CGRectMake(_interactiveView.mj_x, -1000, self.mj_w, self.mj_h + 1000);
}

#pragma mark - 设置 InteractiveView
- (void)setInteractiveView:(UIView *)interactiveView {
    _interactiveView = interactiveView;
    if (!_interactiveView) {
        _interactiveShowState = MJRefreshInteractiveViewShowStateNone;
        return;
    }
    _interactiveShowState = MJRefreshInteractiveViewShowStateInvisible;
    if (_interactiveView.superview) {
        [_interactiveView removeFromSuperview];
    }
    [self addSubview:_interactiveView];
}

#pragma mark - 滑动Offset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    // 当InteractiveView处于 显示←→d隐藏动画中时 不做任何动作
    if (self.interactiveShowHideAnimationing) return;
    // 不显示InteractiveView, 仅刷新
    if (self.interactiveShowState == MJRefreshInteractiveViewShowStateNone) {
        [super scrollViewContentOffsetDidChange:change];
        return;
    }
    // 未显示InteractiveView，且未超过显示InteractiveView的临界点
    if (!self.interactiveVisible && self.interactiveShowState < MJRefreshInteractiveViewShowStateAnimationing2) {
        [super scrollViewContentOffsetDidChange:change];
    }
    
    CGFloat offsetY = -self.scrollView.mj_offsetY;
    if (offsetY < _scrollViewOriginalInset.top
        || self.state == MJRefreshStateRefreshing
        || !self.interactiveView) {
        return;
    }
    
    [self.scrollView sendSubviewToBack:self];
    if (!self.interactiveVisible) {
        CGFloat headerFullVisibleOffsetY = self.scrollView.mj_insetT + self.mj_h;
        CGFloat interactiveOffsetY = offsetY - headerFullVisibleOffsetY;
        if (interactiveOffsetY <= 0) {
            self.interactiveShowState = MJRefreshInteractiveViewShowStateInvisible;
            self.interactiveView.mj_y = self.mj_h;
            [self setRefreshControlAlpha:1.f];
        } else if (interactiveOffsetY <= InteractiveViewRemainHeight) {
            self.interactiveShowState = MJRefreshInteractiveViewShowStateAnimationing;
            self.interactiveView.mj_y = self.mj_h - interactiveOffsetY;
            [self setRefreshControlAlpha:1.f];
        } else if (interactiveOffsetY <= InteractiveViewShowThreshold) {
            self.interactiveShowState = MJRefreshInteractiveViewShowStateAnimationing1;
            CGFloat refreshAlpha = 1.f - (interactiveOffsetY - InteractiveViewRemainHeight) / (InteractiveViewShowThreshold - InteractiveViewRemainHeight);
            [self setRefreshControlAlpha:refreshAlpha];
        } else if (interactiveOffsetY > -self.interactiveView.mj_y) {
            [self setRefreshControlAlpha:0.f];
            self.interactiveShowState = MJRefreshInteractiveViewShowStateAnimationing2;
            if (interactiveOffsetY - _befroeInteractiveOffsetY >= interactiveOffsetY + self.interactiveView.mj_y) {
                self.interactiveView.mj_y -= (interactiveOffsetY - _befroeInteractiveOffsetY);
            } else {
                self.interactiveView.mj_y -= (interactiveOffsetY - _befroeInteractiveOffsetY) * 2;
            }
        } else {
            [self setRefreshControlAlpha:0.f];
            self.interactiveShowState = MJRefreshInteractiveViewShowStateFullVisible;
            self.interactiveView.mj_y = -interactiveOffsetY;
        }
        _befroeInteractiveOffsetY = interactiveOffsetY;
    } else {
        CGFloat headerFullVisibleOffsetY = self.interactiveFullVisibleScrollInsetsTop;
        CGFloat interactiveOffsetY = offsetY - headerFullVisibleOffsetY;
        if (offsetY >= headerFullVisibleOffsetY) {
            self.interactiveShowState = MJRefreshInteractiveViewShowStateFullVisible;
            self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h - interactiveOffsetY;
        } else {
            self.scrollView.mj_insetT = offsetY;
            self.interactiveShowInsetTDelta = headerFullVisibleOffsetY - offsetY;
            self.interactiveShowState = MJRefreshInteractiveViewShowStateAnimationing;
            self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h - interactiveOffsetY * 2;
        }
    }
}

- (void)setRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock {
    [super setRefreshingBlock:refreshingBlock];
    [self setRefreshControlAlpha:refreshingBlock ? 1.f : 0.f];
}

- (void)setRefreshControlAlpha:(CGFloat)alpha {
    if (self.arrowView.alpha == alpha) return;
    if (self.interactiveVisible || !self.refreshingBlock) {
        alpha = 0.f;
    }
    self.arrowView.alpha = alpha;
    self.stateLabel.alpha = alpha;
}

#pragma mark - 刷新状态变化
- (void)setState:(MJRefreshState)state {
    if (self.interactiveShowState < MJRefreshInteractiveViewShowStateAnimationing2) {
        if (!self.refreshingBlock) {
            [super setState:MJRefreshStateIdle];
        } else {
            [super setState:state];
        }
    }
}

#pragma mark - InteractiveView显示状态变化
- (void)setInteractiveShowState:(MJRefreshInteractiveViewShowState)interactiveShowState {
    if (_interactiveShowState == interactiveShowState) return;
    MJRefreshInteractiveViewShowState oldState = _interactiveShowState;
    _interactiveShowState = interactiveShowState;
    switch (_interactiveShowState) {
        case MJRefreshInteractiveViewShowStateNone: {
            _interactiveView.hidden = YES;
        } break;
        case MJRefreshInteractiveViewShowStateAnimationing1: {
            _interactiveView.hidden = NO;
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                self.interactiveView.mj_y = self.mj_h - InteractiveViewRemainHeight;
            }];
        } break;
        case MJRefreshInteractiveViewShowStateAnimationing2: {
            _interactiveView.hidden = NO;
            if (@available(iOS 10.0, *)) {
                if (oldState < MJRefreshInteractiveViewShowStateAnimationing2) {
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
                }
            }
        } break;
        default:
            _interactiveView.hidden = NO;
            break;
    }
}

#pragma mark - 滑动手势状态变化
- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];
    if (self.state == MJRefreshStateRefreshing
        || self.interactiveShowState == MJRefreshInteractiveViewShowStateNone
        || !self.interactiveView) {
        return;
    }
    // 拖拽松手
    UIGestureRecognizerState state = [[change objectForKey:@"new"] integerValue];
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        if (self.interactiveVisible) {
            if (self.interactiveShowState < MJRefreshInteractiveViewShowStateFullVisible) {
                [self hideInteractiveView];
            }
        } else {
            if (self.interactiveShowState > MJRefreshInteractiveViewShowStateAnimationing1) {
                [self showInteractiveView];
            } else {
                [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                    self.interactiveView.mj_y = self.mj_h;
                    [self setRefreshControlAlpha:1.f];
                }];
            }
        }
    }
}

- (void)showInteractiveView {
    self.interactiveVisible = YES;
    self.state = MJRefreshStateIdle;
    self.interactiveShowState = MJRefreshInteractiveViewShowStateFullVisible;
    self.interactiveFullVisibleScrollInsetsTop = self.scrollView.mj_insetT + self.interactiveView.mj_h;
    self.interactiveShowHideAnimationing = YES;
    [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
        self.scrollView.mj_insetT += self.interactiveView.mj_h;
        self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h;
        CGPoint offset = self.scrollView.contentOffset;
        offset.y = -self.scrollView.mj_insetT;
        [self.scrollView setContentOffset:offset animated:NO];
    } completion:^(BOOL finished) {
        self.interactiveShowHideAnimationing = NO;
    }];
}

- (void)hideInteractiveView {
    self.interactiveVisible = NO;
    self.interactiveShowState = MJRefreshInteractiveViewShowStateInvisible;
    self.interactiveShowHideAnimationing = YES;
    [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
        self.scrollView.mj_insetT -= self.interactiveView.mj_h - self.interactiveShowInsetTDelta;
        self.interactiveView.mj_y = self.mj_h;
    } completion:^(BOOL finished) {
        self.state = MJRefreshStateIdle;
        self.interactiveShowHideAnimationing = NO;
        self.interactiveShowInsetTDelta = 0;
    }];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil && self.interactiveView && self.interactiveVisible) {
        CGPoint subPoint = [self convertPoint:point toView:self.interactiveView];
        if (CGRectContainsPoint(self.interactiveView.bounds, subPoint)) {
            return [self.interactiveView hitTest:subPoint withEvent:event];
        }
    }
    return view;
}

@end
