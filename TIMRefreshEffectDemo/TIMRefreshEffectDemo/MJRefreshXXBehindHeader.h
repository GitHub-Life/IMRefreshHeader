//
//  XXBehindHeader.h
//  NiuYan
//
//  Created by jarze on 2018/9/26.
//  Copyright © 2018年 niuyan.com. All rights reserved.
//

#import <MJRefresh.h>

/** 刷新 弹出 控件的状态 */
typedef NS_ENUM(NSInteger, XXBehindState) {
    /** 普通不显示状态 */
    XXBehindStateUndo = 0,
    /** 普通闲置状态 */
    XXBehindStateIdle,
    /** 正在显示中的状态 */
    XXBehindStateShowing,
    
};

NS_ASSUME_NONNULL_BEGIN

@interface MJRefreshXXBehindHeader : MJRefreshNormalHeader

/**
 当前下拉显示状态
 YES: 显示InsertView
 NO: 不显示InsertView
 */
@property (nonatomic, assign) BOOL insertShowState;

/**
 重写父..类 MJRefreshHeader 变量
 */
@property (assign, nonatomic) CGFloat insetTDelta;

/**
 插入显示的View
 */
@property (nonatomic, strong) UIView *insertView;

/**
 插入显示View的显示状态
 */
@property (assign, nonatomic) XXBehindState insertState;


@end

NS_ASSUME_NONNULL_END
