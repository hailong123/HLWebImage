//
//  HLImageLoader.h
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "EventDispatcher.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//extern NSString * const kIMAGE_EVENT_FAIL;
//extern NSString * const kIMAGE_EVENT_ERROR;
//extern NSString * const kIMAGE_EVENT_COMPLETE;
//extern NSString * const kIMAGE_EVENT_LOAD_PER;

#define kIMAGE_EVENT_FAIL @"fail"
#define kIMAGE_EVENT_ERROR @"error"
#define kIMAGE_EVENT_COMPLETE @"complete"
#define kIMAGE_EVENT_LOAD_PER @"load_per"

//NSString * const kIMAGE_EVENT_FAIL     = @"fail";
//NSString * const kIMAGE_EVENT_ERROR    = @"error";
//NSString * const kIMAGE_EVENT_COMPLETE = @"complete";
//NSString * const kIMAGE_EVENT_LOAD_PER = @"load_per";

//加载状态
typedef NS_ENUM(NSInteger, HLImageLoaderState) {
    
    HLImageLoaderStateUnset,    //未设置状态
    HLImageLoaderStateLoading, //加载图片中
    HLImageLoaderStateReady   //图片加载完毕,准备就绪
    
};

//图片的来源
typedef NS_ENUM(NSInteger, HLImageLoaderSourceType) {
    
    HLImageLoaderSourceTypeCache,  //缓存
    HLImageLoaderSourceTypeURL,   //网络
    HLImageLoaderSourceTypeFile  //文件
    
};

//裁剪类型
typedef NS_ENUM(NSInteger, HLImageClipType) {
    
    HLImageClipTypeNone,     //无裁剪
    HLImageClipTypeTop,     //从顶部开始裁剪
    HLImageClipTypeCenter, //从中心开始裁剪
    HLImageTypeBottom     //从底部开始裁剪
    
};


/*
    图片加载器,带有图片加载状态,由HLImagePool管理分发,取到次对象的imageView应该根据此对象的状态进行相关的操作
 */
@interface HLImageLoader : EventDispatcher {
    
    UIImage *_content;
    HLImageLoaderState _state;
    HLImageLoaderSourceType _sourceType;
    
    NSString *_tag;
    
    NSURLConnection *_connection;

    //请求回复
    NSURLResponse *_response;
    //预期大小
    long long _expectedContentLength;
    
    //处理类型 0.不处理  1.裁剪  2.圆角  3.圆形
    NSInteger _iDealType;
    
    CGSize _clipSize;
    
    HLImageClipType _imageClipType;
    
    //圆角半径用于指定图片的圆角值,仅在_iDealType为2时有效
    CGFloat _fCornerRadius;
}

@property (nonatomic, copy) NSString *tag;

@property (nonatomic, readonly) CGFloat loadPer;

@property (nonatomic, strong, readonly) UIImage *content;
//接收数据的对象
@property (nonatomic, strong, nullable) NSMutableData *receiveData;

@property (nonatomic, readonly) HLImageLoaderState state;
@property (nonatomic, readonly) HLImageLoaderSourceType sourceType;

/*
    初始化图片加载器
        clipRect 裁剪区域
 */

- (instancetype)initWithClipSize:(CGSize)clipSize clipType:(HLImageClipType)clipType;

/*
    初始化图片加载器
    cornerRadius
 */
- (instancetype)initWithCornerRadius:(CGFloat)cornerRadius;

/*
    初始化图片加载器
 */

- (instancetype)initForCenterRoundClip;

//加载网络图片对象
- (void)loadImageWithURL:(NSString *)url;
//加载本地图片对象
- (void)loadImageWithFilePath:(NSString *)filePath;
//加载缓存图片对象
- (void)loadImageWithCache:(UIImage *)imageCache;

@end

NS_ASSUME_NONNULL_END
