//
//  HLWebImage.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "HLWebImage.h"

#import "HLImagePool.h"

@interface HLWebImage (Private)

//加载图片
- (void)doLoadImage;

//加载圆角
- (void)doLoadCornerRadiusImage;

//更新排版,重新调整ImageView的尺寸
- (void)upDateLayout;

//释放图片加载器
- (void)releaseImageLoader;

//图片加载完成
- (void)imageLoadCompleteHandler:(NSNotification *)notification;

//图片加载异常
- (void)imageLoadErrorHandler:(NSNotification *)notification;

//图片加载失败
- (void)imageLoadFailHandler:(NSNotification *)notification;

@end

@implementation HLWebImage

@synthesize image            = _image;
@synthesize delegate         = _delegate;
@synthesize imageMode        = _imageMdoe;
@synthesize imageView        = _imageView;
@synthesize defaultImage     = _defaultImage;
@synthesize bHideLoadingView = _bHideLoadingView;

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        _bDrawBackground = NO;
        _fPaddingTop     = 0.0;
        _fPaddingLeft    = 0.0;
        _fPaddingBottom  = 0.0;
        _fPaddingRight   = 0.0;
        
        _fBorderWidth = 0.0;
        
        _imageMdoe = ImageModeFit;
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        _imageView.clipsToBounds    = YES;
        _imageView.contentMode      = UIViewContentModeScaleToFill;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|
                                      UIViewAutoresizingFlexibleWidth;
        
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        CGFloat left = (CGRectGetWidth(self.frame)  - CGRectGetWidth(_activityIndicatorView.frame) /2);
        CGFloat top  = (CGRectGetHeight(self.frame) - CGRectGetHeight(_activityIndicatorView.frame) / 2);
        
        _activityIndicatorView.frame = CGRectMake(left, top,
                                                  CGRectGetWidth(_activityIndicatorView.frame),
                                                  CGRectGetHeight(_activityIndicatorView.frame));
        
        [self addSubview:_imageView];
        
        _iConverOffSet = 0.0;
        
        _touchBtn       = [UIButton buttonWithType:UIButtonTypeCustom];
        _touchBtn.frame = self.bounds;
        
        [_touchBtn addTarget:self action:@selector(handleSingleFingerEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_touchBtn];
        
        [_touchBtn setExclusiveTouch:YES];//避免被两个view同时被点击
        
        //长按事件
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(touchBtnLongPress:)];
        longPress.minimumPressDuration = 0.5;
        [_touchBtn addGestureRecognizer:longPress];
        
        _showType              = ImageShowTypeAnimaAnyway;
        _bHideLoadingView      = YES;
        _resetImageWhileLoad   = YES;
        self.loadImageSuccess  = NO;
    }
    
    return self;
}


//长按手势事件
- (void)touchBtnLongPress:(UILongPressGestureRecognizer *)sender {
    
    if (_delegate && [self.delegate respondsToSelector:@selector(onLongPress:senderState:)]) {
        
        [_delegate onLongPress:self senderState:sender.state];
    }
}


- (void)dealloc {
    
    _image                 = nil;
    _bgColor               = nil;
    _borderColor           = nil;
    _defaultImage          = nil;
    _imageUrlString        = nil;
    _loadImageSelector     = nil;
    _activityIndicatorView = nil;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (_bHasLoadImage) {
        
        _bHasLoadImage = NO;
        
        //停止之前执行的加载图片操作
        [self releaseImageLoader];
        
        if ([_imageUrlString isKindOfClass:[NSString class]] && ![_imageUrlString isEqualToString:@""]) {
            
            //执行加载图片
            [self performSelector:_loadImageSelector];
            
            //判断loader状态,如果已经加载成功则进行显示
            if (_loader.state == HLImageLoaderStateReady) {
                
                self.loadImageSuccess = YES;
                
                [self setImage:_loader.content];
                
                [self dismissLoadingView];
                
                //报告图片已经加载完毕
                if (_delegate && [_delegate respondsToSelector:@selector(onLoadImageComplete:)]) {
                    
                    [_delegate onLoadImageComplete:self];
                    
                }
                
            } else if (_loader.state == HLImageLoaderStateLoading) {
                
                [self showLoadingView];
                
                [_loader addEventListener:kIMAGE_EVENT_FAIL     target:self selector:@selector(imageLoadFailHandler:)];
                [_loader addEventListener:kIMAGE_EVENT_ERROR    target:self selector:@selector(imageLoadErrorHandler:)];
                [_loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(imageLoadCompleteHandler:)];
            }
            
        } else {
         
            [self dismissLoadingView];
            
        }
    }
    
    [self upDateLayout];
}

- (void)drawRect:(CGRect)rect {
    
    [super drawRect:rect];
    
    if (_bDrawBackground) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextClearRect(context, rect);
        CGContextSetLineWidth(context, _fBorderWidth+1);
        
        if (_bgColor) {
            
            CGContextSetFillColorWithColor(context, _bgColor.CGColor);
            
        }
        
        if (_borderColor) {
            
            CGContextSetFillColorWithColor(context, _borderColor.CGColor);
        }
        
        CGContextAddRect(context, rect);
        CGContextDrawPath(context, kCGPathFillStroke);
        
    }
}

- (void)setFrame:(CGRect)frame {
    
    BOOL bHasUpDaetLayout = NO;
    
    if (CGRectGetWidth(self.frame) != CGRectGetWidth(frame) || CGRectGetHeight(self.frame) != CGRectGetHeight(frame)) {
        
        bHasUpDaetLayout = YES;
        
    }
    
    [super setFrame:frame];
    
    if (bHasUpDaetLayout) {
        
        //跟新排版
        if (_activityIndicatorView) {
            //调整加载动画位置
            CGFloat left = CGRectGetWidth(self.frame) - CGRectGetWidth(_activityIndicatorView.frame) / 2;
            CGFloat top  = CGRectGetHeight(self.frame) - CGRectGetHeight(_activityIndicatorView.frame) / 2;
            
            _activityIndicatorView.frame = CGRectMake(left, top, CGRectGetWidth(_activityIndicatorView.frame),
                                                      CGRectGetHeight(_activityIndicatorView.frame));
        }
        
        [self setNeedsLayout];
    }
}

- (void)setDefaultImage:(UIImage *)defaultImage {
    
    _defaultImage = defaultImage;
    
    if (!_image) {
    
        [self setNeedsLayout];
        
    }
}

- (void)setImage:(UIImage *)image {
    
    _image = image;
    
    _bHasLoadImage  = NO;
    _imageUrlString = nil;
    
    [self setNeedsLayout];
    
}

- (void)setConverImage:(UIImage *)converImage {
    
    if (converImage == _converImage) {
        return;
    }
    
    
    _converImage = converImage;
    
    [self setNeedsLayout];
}

- (void)setIndicatorShowWhenLoad:(BOOL)show {
    
    _activityIndicatorView.hidden = !show;
    
}

- (void)loadImageWithUrlString:(NSString *)urlString {
    
    if ([_imageUrlString isEqualToString:urlString] && (self.loadImageSuccess ||
                                                        (_loader && (_loader.state == HLImageLoaderStateLoading ||
                                                                     _loader.state == HLImageLoaderStateReady)))) {
        return;
    }
    
    _imageUrlString = urlString;
    
    //清除原有图片对象 并更新视图
    if (_resetImageWhileLoad && _image) {
        
        _image = nil;
        
    }
    
    _loadImageSelector = @selector(doLoadImage);
    
    _bHasLoadImage        = YES;
    self.loadImageSuccess = NO;
    
    [self setNeedsLayout];
    
}

- (void)loadImageWithUrlString:(NSString *)urlString cornerRadius:(CGFloat)cornerRadius {

    if ([_imageUrlString isEqualToString:urlString] && (self.loadImageSuccess ||
                                                        (_loader && (_loader.state == HLImageLoaderStateLoading ||
                                                                     _loader.state == HLImageLoaderStateReady)))) {
        
        return;
        
    }
    
    _imageUrlString = urlString;
    _cornerRadius   = cornerRadius;
    
    //清除原有的图片对象,并更新
    if (_resetImageWhileLoad && _image) {
        
        _image = nil;
        
    }
    
    _bHasLoadImage        = YES;
    _loadImageSelector    = @selector(doLoadCornerRadiusImage);
    self.loadImageSuccess = NO;
    
    [self setNeedsLayout];
}

- (void)loadRoundImageWithUrlString:(NSString *)urlString {
    
    if ([_imageUrlString isEqualToString:urlString] && (self.loadImageSuccess ||
                                                        (_loader && (_loader.state == HLImageLoaderStateLoading ||
                                                         _loader.state == HLImageLoaderStateReady)))) {
        
        return;
        
    }
    
    _imageUrlString = urlString;
    
    //清除原有的图片对象,并跟新视图
    if (_resetImageWhileLoad && _image) {
        _image = nil;
    }
    
    _loadImageSelector = @selector(doLoadRoundImage);
    
    _bHasLoadImage        = YES;
    self.loadImageSuccess = NO;
    
    [self setNeedsLayout];
    
}

- (void)setBackground:(UIColor *)backgroundColor
          borderColor:(UIColor *)borderColor
          borderWidth:(CGFloat)borderWidth {
    
    if (!backgroundColor && !borderColor && borderWidth == 0) {
        
        _bgColor         = nil;
        _borderColor     = nil;
        _bDrawBackground = NO;
        
        _fBorderWidth = 0;
        _fFixedValue  = 0;
        
    } else {
        
        _bgColor         = backgroundColor;
        _borderColor     = borderColor;
        _fBorderWidth    = borderWidth;
        _bDrawBackground = YES;
        
        [self setPaddingTop:_fPaddingTop
                paddingLeft:_fPaddingLeft
              paddingBottom:_fPaddingBottom
               paddingRight:_fPaddingRight];
        
        [self setNeedsDisplay];
    }
}

- (void)setPaddingTop:(CGFloat)paddingTop
          paddingLeft:(CGFloat)paddingLeft
        paddingBottom:(CGFloat)paddingBottom
         paddingRight:(CGFloat)paddingRight {
    
    _fPaddingTop    = paddingTop;
    _fPaddingLeft   = paddingLeft;
    _fPaddingBottom = paddingBottom;
    _fPaddingRight  = paddingRight;
    
    [self setNeedsLayout];
}

- (HLImageLoaderState)imageLoadState {
    
    if (_loader) {
        
        return _loader.state;
        
    }
    
    return HLImageLoaderStateUnset;
    
}

- (void)setImageContentMode:(UIViewContentMode)imageContentMode {
    
    _imageView.contentMode = imageContentMode;
}

- (UIViewContentMode)imageContentMode {
    
    return _imageView.contentMode;
}

- (void)showLoadingView {

    if (!_bHideLoadingView) {
        
        [self addSubview:_activityIndicatorView];
        [_activityIndicatorView startAnimating];
    }
    
}

- (void)dismissLoadingView {
    
    if (!_bHideLoadingView) {
        
        [_activityIndicatorView removeFromSuperview];
        [_activityIndicatorView stopAnimating];
    }
}

- (void)doLoadImage {
    
    if (_imageMode == ImageModeFit)
    {
        _loader = [[HLImagePool shareInstance] image:_imageUrlString];
        
    } else {
        
        HLImageClipType imageClipType;
        
        switch (self.imageMode)
        {
            case ImageModeClipTop:
                imageClipType = HLImageClipTypeTop;
                break;
            case ImageModeClipCenter:
                imageClipType = HLImageClipTypeCenter;
                break;
            case ImageModeClipBottom:
                imageClipType = HLImageTypeBottom;
                break;
            default:
                imageClipType = HLImageClipTypeNone;
                break;
        }
        
        _loader = [[HLImagePool shareInstance] image:_imageUrlString
                                                    size:self.frame.size
                                                clipType:imageClipType];
    }
}


- (void)doLoadCornerRadiusImage
{
    _loader = [[HLImagePool shareInstance] image:_imageUrlString
                                        cornerRadius:_cornerRadius];
}

- (void)doLoadRoundImage {
    
    _loader = [[HLImagePool shareInstance] roundImage:_imageUrlString];
    
}

- (void)upDateLayout
{
    if (_imageView)
    {
        if (self.pattenImageMode)//图片平铺
        {
            _imageView.image = nil;
            
            if (_image)
            {
                _imageView.backgroundColor = [UIColor colorWithPatternImage:_image];
            }
            else if (_defaultImage)
            {
                _imageView.backgroundColor = [UIColor colorWithPatternImage:_defaultImage];
            }
        }
        else
        {
            if (_image)
            {
                _imageView.image = _image;
            }
            else if (_defaultImage)
            {
                _imageView.image = _defaultImage;
            }
            else
            {
                _imageView.image = nil;
            }
        }
    }
    
    if (_converImage != nil)
    {
        if (_converView == nil)
        {
            _converView = [[UIImageView alloc]initWithImage:_converImage];
        }
        
        if (_converView.image != _converImage)
        {
            _converView.image = _converImage;
        }
        _converView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self addSubview:_converView];
        [self bringSubviewToFront:_converView];
        
        _converView.frame = CGRectMake(_iConverOffset, _iConverOffset,
                                       CGRectGetWidth(_imageView.frame)-_iConverOffset*2,
                                       CGRectGetHeight(_imageView.frame)-_iConverOffset*2);
        
    }
    else
    {
        [_converView removeFromSuperview];
    }
    
    _touchBtn.frame = self.bounds;
}

- (void)imageLoadCompleteHandler:(NSNotification *)notif {
    
    HLImageLoader *loader = [notif object];
    
    BOOL existImg = _image != nil;
    
    [self setImage:loader.content];
    
    self.loadImageSuccess = YES;
    
    [self releaseImageLoader];
    
    [self dismissLoadingView];
    
    switch (_showType)
    {
        case ImageShowTypeNoAnimaAnyway:
        {
            _imageView.alpha = 1.0f;
            break;
        }
        case ImageShowTypeAnimaAnyway:
        {
            _imageView.alpha = 0.0f;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            _imageView.alpha = 1.0f;
            [UIView commitAnimations];
            
            break;
        }
        case ImageShowTypeOnlyAnimaWhileEmpty:
        {
            if (existImg)
            {
                _imageView.alpha = 1.0f;
            }
            else
            {
                _imageView.alpha = 0.0f;
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3f];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                _imageView.alpha = 1.0f;
                [UIView commitAnimations];
            }
            
            break;
        }
        default:
            _imageView.alpha = 1.0f;
            break;
    }
    
    if ([_delegate conformsToProtocol:@protocol(HLWebImageDelegate)] &&
        [_delegate respondsToSelector:@selector(onLoadImageComplete:)])
    {
        [_delegate onLoadImageComplete:self];
    }
}

- (void)imageLoadErrorHandler:(NSNotification *)notif {
    
    [self releaseImageLoader];
    
    self.loadImageSuccess = NO;
    
    [self dismissLoadingView];
    
    if ([_delegate conformsToProtocol:@protocol(HLWebImageDelegate)] &&
        [_delegate respondsToSelector:@selector(onLoadImageFail:)])
    {
        [_delegate onLoadImageFail:self];
    }
}

- (void)imageLoadFailHandler:(NSNotification *)notif {
    [self releaseImageLoader];
    
    self.loadImageSuccess = NO;
    
    [self dismissLoadingView];
    
    if ([_delegate conformsToProtocol:@protocol(HLWebImageDelegate)] &&
        [_delegate respondsToSelector:@selector(onLoadImageFail:)])
    {
        [_delegate onLoadImageFail:self];
    }
}

- (void)releaseImageLoader {
    
    [_loader removeEventListener:kIMAGE_EVENT_FAIL target:self];
    [_loader removeEventListener:kIMAGE_EVENT_ERROR target:self];
    [_loader removeEventListener:kIMAGE_EVENT_COMPLETE target:self];
    
    _loader = nil;
}

- (void)handleSingleFingerEvent:(id)sender {
    
    if ([_delegate conformsToProtocol:@protocol(HLWebImageDelegate)] &&
        [_delegate respondsToSelector:@selector(onClick:)])
    {
        [_delegate onClick:self];
    }
}


@end
