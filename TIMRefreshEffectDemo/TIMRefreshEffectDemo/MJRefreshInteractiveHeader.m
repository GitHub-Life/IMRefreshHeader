//
//  MJRefreshInteractiveHeader.m
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/28.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "MJRefreshInteractiveHeader.h"

#define InteractiveViewInitOffsetY self.mj_h
#define InteractiveViewRemainHeight MIN(30.f, self.interactiveView.mj_h * 0.3f)
#define InteractiveViewShowThreshold MAX(50.f, self.interactiveView.mj_h * 0.2f)

@interface MJRefreshInteractiveHeader ()

@property (nonatomic, assign) BOOL interactiveVisible;

@property (nonatomic, assign) CGFloat befroeInteractiveOffsetY;

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

- (void)setInteractiveView:(UIView *)interactiveView {
    _interactiveView = interactiveView;
    if (!_interactiveView) {
        _interactiveShowState = MJRefreshInteractiveViewShowStateNone;
        return;
    }
    if (_interactiveView.superview) {
        [_interactiveView removeFromSuperview];
    }
    [self addSubview:_interactiveView];
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    if (self.interactiveShowState == MJRefreshInteractiveViewShowStateNone) {
        [super scrollViewContentOffsetDidChange:change];
        return;
    }
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
        CGFloat headerFullVisibleOffsetY = self.scrollView.mj_insetT;
        CGFloat interactiveOffsetY = offsetY - headerFullVisibleOffsetY;
        if (offsetY >= self.scrollView.mj_insetT) {
            self.interactiveShowState = MJRefreshInteractiveViewShowStateFullVisible;
            self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h - interactiveOffsetY;
        } else {
              self.interactiveShowState = MJRefreshInteractiveViewShowStateAnimationing;
              self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h - interactiveOffsetY * 2;
          }
    }
}

- (void)setRefreshControlAlpha:(CGFloat)alpha {
    if (self.arrowView.alpha == alpha) return;
    if (self.interactiveVisible) {
        alpha = 0.f;
    }
    self.arrowView.alpha = alpha;
    self.stateLabel.alpha = alpha;
}

- (void)setState:(MJRefreshState)state {
    if (self.interactiveShowState < MJRefreshInteractiveViewShowStateAnimationing2) {
        [super setState:state];
    }
}

- (void)setInteractiveShowState:(MJRefreshInteractiveViewShowState)interactiveShowState {
    if (_interactiveShowState == interactiveShowState) return;
    MJRefreshInteractiveViewShowState oldState = _interactiveShowState;
    _interactiveShowState = interactiveShowState;
    switch (_interactiveShowState) {
        case MJRefreshInteractiveViewShowStateNone: {
            _interactiveView.hidden = YES;
        } break;
        case MJRefreshInteractiveViewShowStateAnimationing1: {
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                self.interactiveView.mj_y = self.mj_h - InteractiveViewRemainHeight;
            }];
        } break;
        case MJRefreshInteractiveViewShowStateAnimationing2: {
            if (@available(iOS 10.0, *)) {
                if (oldState < MJRefreshInteractiveViewShowStateAnimationing2) {
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
                }
            }
        } break;
        default:
            break;
    }
}

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
                }];
            }
        }
    }
}

- (void)showInteractiveView {
    self.interactiveVisible = YES;
    self.state = MJRefreshStateIdle;
    self.interactiveShowState = MJRefreshInteractiveViewShowStateFullVisible;
    [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
        self.scrollView.mj_insetT += self.interactiveView.mj_h;
        self.interactiveView.mj_y = self.mj_h - self.interactiveView.mj_h;
        CGPoint offset = self.scrollView.contentOffset;
        offset.y = -self.scrollView.mj_insetT;
        [self.scrollView setContentOffset:offset animated:NO];
    }];
}

- (void)hideInteractiveView {
    self.interactiveVisible = NO;
    self.interactiveShowState = MJRefreshInteractiveViewShowStateInvisible;
    [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
        self.scrollView.mj_insetT -= self.interactiveView.mj_h;
        self.interactiveView.mj_y = self.mj_h;
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
