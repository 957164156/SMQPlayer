//
//  SMQPlayerItem.h
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/22.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import <Foundation/Foundation.h>

//播放源
@interface SMQPlayerItem : NSObject

+ (instancetype)defaultPlayerItem;
//
@property (nonatomic,strong)NSURL *url;

@property (nonatomic,copy)NSString *title;

@property (nonatomic,copy)NSString *currentTime;

@property (nonatomic,copy)NSString *totalTime;

+ (instancetype)setItemWithUrl:(NSString *)url title:(NSString *)title;
@end
