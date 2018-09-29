//
//  XXBehindHeader.m
//  NiuYan
//
//  Created by jarze on 2018/9/26.
//  Copyright © 2018年 niuyan.com. All rights reserved.
//

#import "MJRefreshXXBehindHeader.h"

@interface MJRefreshXXBehindHeader()

/**
 下拉显示InsertView的距离
 */
@property (nonatomic, assign) CGFloat insertOffSetY;

/**
 标记当前插入View正在动画
 */
@property (nonatomic, assign) BOOL handleInsertView;
@end

@implementation MJRefreshXXBehindHeader
- (void)prepare {
    [super prepare];
}

- (void)placeSubviews {
    [super placeSubviews];
    self.insertOffSetY = self.mj_h + 30;
    if (!self.scrollView.isDragging) {
        _insertView.mj_y = self.insertOffSetY;
        _insertView.mj_w = self.scrollView.mj_w;
        _insertView.mj_x = -self.mj_x;
    }
    // 遮罩不显示部分
    if (!self.layer.mask) {
        CALayer *lay = [CALayer layer];
        lay.contentsScale = [UIScreen mainScreen].scale;
        [lay setFrame:CGRectMake(_insertView.mj_x, -1000, self.mj_w, self.mj_h + 1000)];
        [lay setBackgroundColor:UIColor.blackColor.CGColor];
        [self.layer setMask:lay];
    } else {
        CALayer *lay = self.layer.mask;
        [lay setFrame:CGRectMake(_insertView.mj_x, -1000, self.mj_w, self.mj_h + 1000)];
    }
}

- (void)setInsertView:(UIView *)insertView {
    if (_insertView.superview) {
        [_insertView removeFromSuperview];
    }
    _insertView = insertView;
    [self addSubview:insertView];
    _insertView.mj_y = self.mj_h + 30;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    if (self.insertState == XXBehindStateShowing) {
        _scrollViewOriginalInset.top = self.scrollView.mj_insetT - self.insertView.mj_h;
    } else {
        [super scrollViewContentOffsetDidChange:change];
    }
    if (self.insertState == XXBehindStateUndo) {
        return;
    }
    [self.scrollView sendSubviewToBack:self];
    if (self.insertView == nil) {
        return;
    }
    CGPoint offSet = [[change objectForKey:@"new"] CGPointValue];
    CGFloat offsetY = offSet.y;
    if (self.insertState == XXBehindStateShowing) {
        _scrollViewOriginalInset.top = self.scrollView.mj_insetT - self.insertView.mj_h;
    }
    // 头部控件刚好出现的offsetY
    if (self.state == MJRefreshStateRefreshing || offsetY > 0 || (self.insertState == XXBehindStateIdle && fabs(offsetY)  < self.insertOffSetY)) {
        [self.insertView setTransform:CGAffineTransformIdentity];
        return;
    }
    
    // 计算偏移量
    CGFloat troffy = self.insertOffSetY - self.mj_h; // 初始偏移y值
    CGFloat maxOff = offsetY - troffy;
    CGFloat oy = 0.0;
    if (self.insertState == XXBehindStateShowing) {
        if (fabs(offsetY) >= self.insertView.mj_h) {
            oy = maxOff;
        } else {
            oy = offsetY * 2 + self.insertView.mj_h  - troffy;
        }
    } else {
        if (fabs(offsetY) >= self.insertOffSetY) {
            oy = (offsetY + self.insertOffSetY) * 2 - troffy;
        } else {
            oy = 0;
        }
    }
    if (oy < maxOff) {
        oy = maxOff;
    }
    [self.insertView setTransform:CGAffineTransformMakeTranslation(0, oy)];
    
//    NSLog(@"\n ------ \n scrollOffset : %f \n insetViewFrame: %@ \n transform: %f  \n self.frame: %@ \n insertOffSetY: %f \n ----- \n", offsetY, NSStringFromCGRect(self.insertView.frame), oy, NSStringFromCGRect(self.frame), self.insertOffSetY);
}

- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];
    CGFloat offsetY = self.insertView.transform.ty;

    if (self.insertView == nil || self.handleInsertView || self.state == MJRefreshStateRefreshing || fabs(offsetY) == 0) {
        return;
    }
    
    // 拖拽松手
    UIGestureRecognizerState state = [[change objectForKey:@"new"] integerValue];
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        //拖拽显示1/4弹出
        BOOL show = (self.mj_h - self.insertView.mj_y) > self.insertView.mj_h / 4.0;
        if (self.insertState == XXBehindStateIdle) {
            self.insertState = show ? XXBehindStateShowing : XXBehindStateIdle;
        } else if (self.insertState == XXBehindStateShowing) {
            if ((self.mj_h - self.insertView.mj_y) < self.insertView.mj_h) {
                self.insertState = XXBehindStateIdle;
            }
        } else {
            if (show) {
                self.insertState = XXBehindStateShowing;
            } else {
                self.insertState =  _insertState;
            }
        }
    }
}

- (void)setState:(MJRefreshState)state {
    if (self.insertView == nil || self.state == MJRefreshStateRefreshing || (self.insertState == XXBehindStateUndo && !self.handleInsertView)) {
        
    } else if (self.handleInsertView || self.insertState == XXBehindStateShowing) {
        return;
    }
   
    [super setState:state];
}

- (void)setInsertState:(XXBehindState)insertState {
    if (_insertState == insertState) {
        return;
    }
    if ((_insertState == XXBehindStateUndo && insertState == XXBehindStateIdle) || (_insertState == XXBehindStateIdle && insertState == XXBehindStateUndo) ) {
        _insertState = insertState;
        return;
    }
    self.handleInsertView = YES;
    _insertState = insertState;
    if (self.insertState == XXBehindStateShowing) {
        self.stateLabel.hidden = YES;
        self.arrowView.hidden = YES;
        // 恢复inset和offset
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            self.scrollView.mj_insetT = self.insertView.mj_h;
            CGPoint offset = self.scrollView.contentOffset;
            offset.y = -self.insertView.mj_h;
            [self.scrollView setContentOffset:offset];
        } completion:^(BOOL finished) {
            self.handleInsertView = NO;
        }];
    } else {
        self.insetTDelta = self.scrollViewOriginalInset.top;
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            self.scrollView.mj_insetT = 0;
            self.insertView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.stateLabel.hidden = NO;
                self.arrowView.hidden = NO;
                self.handleInsertView = NO;
            });
        }];
    }
}

- (void)setInsertShowState:(BOOL)insertShowState {
    if (_insertShowState == insertShowState) {
        return;
    }
    _insertShowState = insertShowState;
    if (insertShowState) {
        if (self.insertState == XXBehindStateUndo) {
            self.insertState = XXBehindStateIdle;
        }
    } else {
        self.insertState = XXBehindStateUndo;
    }
    self.insertView.hidden = !insertShowState;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (self.insertView && view == nil && self.insertState == XXBehindStateShowing) {
//        CGPoint newPoint = [self convertPoint:point fromView:self.insertView];
        if (CGRectContainsPoint(self.insertView.frame, point)) {
            view = self.insertView;
        }
    }
    return view;
}

@end
