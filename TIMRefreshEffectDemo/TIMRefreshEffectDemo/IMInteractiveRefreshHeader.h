//
//  IMInteractiveRefreshHeader.h
//  TIMRefreshEffectDemo
//
//  Created by 万涛 on 2018/9/25.
//  Copyright © 2018年 iMoon. All rights reserved.
//

#import "MJRefreshHeader.h"

typedef NS_ENUM(NSInteger, IMInteractiveShowState) {
    /** 不可见 */
    IMInteractiveShowStateInvisible = 0,
    /** 过渡到可见 */
    IMInteractiveShowStateTransitionVisible,
    /** 此时松手会动画至 可见 状态*/
    IMInteractiveShowStateCanVisible,
    /** 可见 */
    IMInteractiveShowStateVisible,
    /** 显示中 */
    IMInteractiveShowStateShowing,
    /** 过渡到隐藏 */
    IMInteractiveShowStateTransitionHide,
    /** 隐藏 */
    IMInteractiveShowStateHide,
    /** 隐藏中 */
    IMInteractiveShowStateHiding,
};

@interface IMInteractiveRefreshHeader : MJRefreshHeader

@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, copy) NSString *statetTitle;
@property (nonatomic, strong) UIColor *refreshColor;

@property (nonatomic, assign) UIEdgeInsets containerInsets;
- (void)addContentView:(UIView *)contentView;
@property (nonatomic, assign) IMInteractiveShowState interactiveShowState;
- (void)hideContainerView;

@end
