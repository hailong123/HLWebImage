//
//  EventDispatcher.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "EventDispatcher.h"

@interface EventDispatcher () {
    
    NSNotificationCenter *_notificationCenter;//通知中心
    
}

@end

@implementation EventDispatcher

- (instancetype)init {
    
    if (self = [super init]) {
        
        _notificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return self;
}

#pragma mark 添加事件监听
- (void)addEventListener:(NSString *)type target:(id)target selector:(SEL)selector {
    
    [_notificationCenter addObserver:target selector:selector name:type object:self];
    
}

#pragma 移除事件监听
- (void)removeEventListener:(NSString *)type target:(id)target {
    
    [_notificationCenter removeObserver:target name:type object:self];
    
}

#pragma mark - 派发事件
- (void)dispatchEvent:(NSString *)type data:(id)data {
    
    [_notificationCenter postNotificationName:type object:self userInfo:data];
    
}

#pragma mark - 移除事件
- (void)removeEventListener:(id)target {
    
    [_notificationCenter removeObserver:target];
    
}

@end
