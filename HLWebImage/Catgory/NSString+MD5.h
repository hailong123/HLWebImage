//
//  NSString+MD5.h
//  KuKuxiu
//
//  Created by 123456 on 16/1/18.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MD5)
//字符串的MD5加密
//+(NSString *)md5:(NSString *)inPutText;
- (NSString *)MD5;
- (NSString *)sha1;
@end
