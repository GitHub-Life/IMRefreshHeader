//
//  MJRefreshInteractiveHeader.h
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/28.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "MJRefreshNormalHeader.h"

typedef NS_ENUM(NSInteger, MJRefreshInteractiveViewShowState) {
    /** 不显示InteractiveView */
    MJRefreshInteractiveViewShowStateNone = 0,
    /** 不可见 */
    MJRefreshInteractiveViewShowStateInvisible,
    /** 动画中[此时松手 刷新] */
    MJRefreshInteractiveViewShowStateAnimationing,
    /** 动画中[InteractiveView悬停，此时松手 刷新] */
    MJRefreshInteractiveViewShowStateAnimationing1,
    /** 动画中[此时松手 动画完全显示InteractiveView] */
    MJRefreshInteractiveViewShowStateAnimationing2,
    /** 可见 */
    MJRefreshInteractiveViewShowStateFullVisible
};

@interface MJRefreshInteractiveHeader : MJRefreshNormalHeader

@property (nonatomic, strong) UIView *interactiveView;

@property (nonatomic, assign) MJRefreshInteractiveViewShowState interactiveShowState;

@end
