//
//  SMQPlayer.h
//  呜呜呜呜
//
//  Created by 孙明卿 on 2017/3/4.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SMQPlayerItem;
@class SMQPlayer;
@protocol SMQPlayerDelegate <NSObject>
@optional
//强制转屏的代理方法
- (void)smqPlayer:(SMQPlayer *)player fullScreenBtn:(UIButton *)fullBtn;

//返回按钮的代理方法
- (void)smqPlayer:(SMQPlayer *)player backBtn:(UIButton *)backBtn;

//屏幕发生了变化的代理方法
- (void)smqOrentatiionChangePlayer:(SMQPlayer *)player;

//视频开始播放
- (void)smqPlayer:(SMQPlayer *)player didStartPlay:(SMQPlayerItem *)playItem;
@end
@interface SMQPlayer : UIView
/** 当前播放时长label */
@property (nonatomic, strong) UILabel                 *currentTimeLabel;
/** 视频总时长label */
@property (nonatomic, strong) UILabel                 *totalTimeLabel;

//代理
@property (nonatomic,assign)id<SMQPlayerDelegate>mqdelegate;

//视频的url
@property (nonatomic,strong)NSURL *videoUrl;

//播放源
@property (nonatomic,strong)SMQPlayerItem *item;

- (instancetype)initWithItem:(SMQPlayerItem *)playerItem;


/**
 重新设置视频源

 @param playerItem 视频源
 */
- (void)reSetPlayerWithItem:(SMQPlayerItem *)playerItem;

//为slider设置点
- (void)setPointForSliderWithPoint:(NSArray *)timeArray;


@end
