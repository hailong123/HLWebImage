//
//  NSString+MD5.m
//  KuKuxiu
//
//  Created by 123456 on 16/1/18.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "NSString+MD5.h"
#import<CommonCrypto/CommonDigest.h>  

@implementation NSString (MD5)

- (NSString *)MD5 {
    
    const char *cStr = [self UTF8String];
    
    unsigned char result[16];
    
    CC_MD5(cStr, strlen(cStr),result);
    
    NSMutableString *hash =[NSMutableString string];
    
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    
    return [hash lowercaseString];
}

- (NSString*) sha1
{
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end
