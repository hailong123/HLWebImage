//
//  EventDispatcher.h
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//观察者模式

#import <Foundation/Foundation.h>

@interface EventDispatcher : NSObject

//添加事件监听
- (void)addEventListener:(NSString *)type target:(id)target selector:(SEL)selector;

//移除事件监听
- (void)removeEventListener:(NSString *)type target:(id)target;

//派发事件
- (void)dispatchEvent:(NSString *)type data:(id)data;

//移除事件监听
- (void)removeEventListener:(id)target;

@end
