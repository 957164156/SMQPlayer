//
//  SMQPlayerItem.m
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/22.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import "SMQPlayerItem.h"

static SMQPlayerItem *item = nil;

@implementation SMQPlayerItem


+ (instancetype)defaultPlayerItem {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        item = [[self alloc] init];
    });
    
    return item;
}

+ (instancetype)setItemWithUrl:(NSString *)url title:(NSString *)title {
    
    SMQPlayerItem *currentItem = [self defaultPlayerItem];
    NSURL *currentUrl = [NSURL URLWithString:url];
    currentItem.url = currentUrl;
    currentItem.title = title;
    
    return currentItem;
}
@end
