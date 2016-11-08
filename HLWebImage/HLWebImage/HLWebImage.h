//
//  HLWebImage.h
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//一个类似于SDWebImage的图片加载工具类

#import <UIKit/UIKit.h>

#import "HLImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

//拉伸模式
typedef NS_ENUM(NSInteger, ImageMode) {
    
    ImageModeFit,           //适合显示尺寸
    ImageModeClipTop,      //从顶部裁剪图片
    ImageModeClipCenter,  //从中间裁剪图片
    ImageModeClipBottom  //从底部裁剪图片
    
};

typedef NS_ENUM(NSInteger, ImageShowType) {
    
    ImageShowTypeNoAnimaAnyway,        //没有动画效果
    ImageShowTypeAnimaAnyway,         //有动画效果
    ImageShowTypeOnlyAnimaWhileEmpty //只有当没有图片时候才有动画效果
    
};

@class HLWebImage;

@protocol HLWebImageDelegate <NSObject>

@optional

//点击图片
- (void)onClick:(HLWebImage *)sender;

//图片长按
- (void)onLongPress:(HLWebImage *)sender senderState:(UIGestureRecognizerState)state;

//图片加载完成
- (void)onLoadImageComplete:(HLWebImage *)sender;

//加载图片
- (void)onLoadImageFail:(HLWebImage *)sender;

@end

//图片视图
@interface HLWebImage : UIView

{
@private
    UIImage *_image;
    UIImage *_defaultImage;
    
    UIActivityIndicatorView *_activityIndicatorView;
    
    HLImageLoader *_loader; //图片加载器
    ImageMode      _imageMode;  //图片模式
    
    CGFloat _fBorderWidth;
    CGFloat _fFixedValue; //图片的尺寸修正值,只有当设置了边框时才需要减去此值来显示边框
    
    UIColor *_borderColor;
    UIColor *_bgColor;
    
    BOOL _bDrawBackground;
    
    NSString *_imageUrlString;
    CGFloat   _cornerRadius;
    
    BOOL _bHasLoadImage;
    
    SEL _loadImageSelector;
@protected
    UIButton *_touchBtn;//处理点击事件
   
    CGFloat _fPaddingLeft;
    CGFloat _fPaddingRight;
    CGFloat _fPaddingTop;
    CGFloat _fPaddingBottom;
    
    UIImageView *_converView;    //遮罩层 实现圆角边框等效果
    UIImage     *_converImage;  //遮罩层图片
    CGFloat      _iConverOffset;//遮罩层边偏移量
    
    BOOL _bHideLoadingView;
}

@property (nonatomic, strong) UIImageView *imageView;


//图片填充方式
@property (nonatomic, assign) UIViewContentMode imageContentMode;

//默认的图片对象
@property (nonatomic, strong) UIImage *defaultImage;

//图片对象
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign,getter=isLoadImageSuccess) BOOL loadImageSuccess;

//委托对象
@property (nonatomic, assign) id <HLWebImageDelegate> delegate;

//图片拉伸
@property (nonatomic, assign) ImageMode imageMode;

//图片平铺模式
@property (nonatomic, assign,getter=isPattenImageMode) BOOL pattenImageMode;

//遮罩层,实现圆角,边框效果
@property (nonatomic, strong) UIImage *converImage;

@property (nonatomic, assign) CGFloat iConverOffSet;//遮罩层边的偏移量

//网络加载时是否显示菊花
@property (nonatomic, assign, getter=isHideLoadingView) BOOL bHideLoadingView;

//网络加载成功之后,图片显示是否有动画效果,默认ImageShowTypeAnimaAnyway
@property (nonatomic, assign) ImageShowType showType;

//加载新图时候是否清除原图 默认为YES
@property (nonatomic, assign, getter=isResetImageWhileLoad) BOOL resetImageWhileLoad;

//通过url来加载图片
- (void)loadImageWithUrlString:(NSString *)urlString;

//通过url来加载图片,此方法会直接导致图片保存为png格式
- (void)loadImageWithUrlString:(NSString *)urlString cornerRadius:(CGFloat)cornerRadius;

//通过url来加载圆形图片,此方法会直接导致图片保存成为png格式
- (void)loadRoundImageWithUrlString:(NSString *)urlString;

//设置背景
- (void)setBackground:(UIColor *)backgroundColor
          borderColor:(UIColor *)borderColor
          borderWidth:(CGFloat)borderWidth;

//设置间距
- (void)setPaddingTop:(CGFloat)paddingTop
          paddingLeft:(CGFloat)paddingLeft
        paddingBottom:(CGFloat)paddingBottom
         paddingRight:(CGFloat)paddingRight;

//图片的加载状态
- (HLImageLoaderState)imageLoadState;

@end

NS_ASSUME_NONNULL_END
