//
//  HLImagePool.h
//  HLWebImage
//
//  Created by 123456 on 2016/11/2.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HLImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

/*
    图片缓冲池,主要负责管理头像,照片内容的缓存类,
    任何跟图片相关的(除不需要进行缓存的)请求都需要由此类进行分发
 */

@interface HLImagePool : NSObject {
    
    //图片缓冲池,主要记录缓存到内存的图片对象
    NSMutableDictionary *_imagePool;
    //加载图片队列,尚未从网络获取本地加载完毕的图片将会进入此队列
    NSMutableArray *_loaderQueue;
    //缓存的路径
    NSString *_cachePath;
    
    //加载队列
    NSOperationQueue *_loadImageEngineQueue;
}

/*
    
    图片缓冲池共享实例,外部对象调用此对象获取HLImagePool对象
 
*/

+ (HLImagePool *)shareInstance;

/*
    转换图片路径,如果没有备用域名则不进行转换,否则替换原有域名
 *
 *     url 图片路径 可以为本地或者网路路径
 *     返回 转换后的图片路径
 */

- (NSString *)converImageURL:(NSString *)url;

/*
    判断是否存在本地缓存
 *
 *  url 图片的路径 可以为本地或者网路路径
 *  返回 是否存在
 */

- (BOOL)existsLocalCacheWithURL:(NSString *)URL;

/*
 *
 *  获取图片
 *  URL 图片的路径 可以为本地或者网路路径
 *  返回 图片加载器
 */

- (HLImageLoader *)image:(NSString *)URL;

/*
 * 获取图片
 *  url:图片的路径
 *  size:裁剪区域
 *  clipType:图片裁剪类型
 *  返回:图片裁剪器
*/

- (HLImageLoader *)image:(NSString *)URL size:(CGSize)size clipType:(HLImageClipType)clipType;

/*
 *
 *  获取图片
 *  URL: 图片的路径 可以为本地或者网路路径
 *  cornerRadius:圆角
 *  返回:图片加载器
 */

- (HLImageLoader *)image:(NSString *)URL cornerRadius:(CGFloat)cornerRadius;

/*
 *
 *  获取图片
 *   url: 图片路径 可以为本地或者网路路径
 *  返回:图片加载器
 */

- (HLImageLoader *)roundImage:(NSString *)URL;

/*说明:回收图片缓存资源,将加载到缓存中而又没有用到的图片对象进行释放*/
- (void)gc;
@end
NS_ASSUME_NONNULL_END
