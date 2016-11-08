//
//  HLImageLoader.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "HLImageLoader.h"

#import "Graphics.h"

#define OPERATOR_QUEUE_LENGTH 10

//NSString * const kIMAGE_EVENT_FAIL     = @"fail";
//NSString * const kIMAGE_EVENT_ERROR    = @"error";
//NSString * const kIMAGE_EVENT_COMPLETE = @"complete";
//NSString * const kIMAGE_EVENT_LOAD_PER = @"load_per";

@interface HLImageLoader (Private)

//线程处理加载本地文件
- (void)doloadImageWithFilePath:(NSString *)filePath;

//释放请求相关的对象信息
- (void)releaseRequestObject;

//获取裁剪图片区域
- (CGRect)clipImageRect:(UIImage *)image;

//处理裁剪图片的数据
- (void)dealClipImageWithData:(NSData *)data needEvent:(BOOL)needEvent;

//处理圆角图片数据
- (void)dealRoundCornerRectImageWithData:(NSData *)data needEvent:(BOOL)needEvent;

- (void)connection:(NSURLConnection *)connection didFailWithError:(nonnull NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(nonnull NSURLResponse *)response;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@implementation HLImageLoader

@synthesize tag        = _tag;
@synthesize state      = _state;
@synthesize content    = _content;
@synthesize sourceType = _sourceType;

//初始化裁剪器
- (instancetype)initWithClipSize:(CGSize)clipSize clipType:(HLImageClipType)clipType {
    
    if (self = [super init]) {
        
        _iDealType     = 1;
        _clipSize      = clipSize;
        _imageClipType = clipType;
        
    }
    
    return self;
}

- (instancetype)initWithCornerRadius:(CGFloat)cornerRadius {
    
    if (self = [super init]) {
    
        _iDealType     = 2;
        _fCornerRadius = cornerRadius;
        
    }
    
    return self;
}

- (instancetype)initForCenterRoundClip {
    
    if (self = [super init]) {
     
        _iDealType = 3;
        
    }
    
    return self;
}


//MARK:加载网络图片对象
- (void)loadImageWithURL:(NSString *)url {
    
    _sourceType = HLImageLoaderSourceTypeURL;
    _state      = HLImageLoaderStateLoading;
    
    if (_connection != nil) {
        [_connection cancel];
    }
    
    if (_receiveData == nil) {
        _receiveData = [[NSMutableData alloc] init];
    }
    
    [_receiveData setData:nil];
    
    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self startImmediately:NO];
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    
}

//MARK:加载本地图片
- (void)loadImageWithFilePath:(NSString *)filePath {
    
    _sourceType = HLImageLoaderSourceTypeFile;
    
    //直接加载
    _state = HLImageLoaderStateLoading;
    
    [self doloadImageWithFilePath:filePath];
    
}

//MARK:加载缓存
- (void)loadImageWithCache:(UIImage *)imageCache {
    
    _sourceType = HLImageLoaderSourceTypeCache;
    
    _content = imageCache;
    
    _state = HLImageLoaderStateReady;
    
}

#pragma mark - 私有实现方法
- (void)doloadImageWithFilePath:(NSString *)filePath {
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    if (data) {
        
        switch (_iDealType) {
            case 1:
            {
                [self dealClipImageWithData:data needEvent:NO];
            }
                break;
                
            case 2:
            {
                [self dealRoundCornerRectImageWithData:data needEvent:NO];
            }
                break;
            case 3:
            {
                [self dealClipRoundImageWidthData:data needEvent:NO];
            }
                break;
            default:
            {
                _content = [UIImage imageWithData:data];
            }
                break;
        }
        
        if (_content)
        {
            _state = HLImageLoaderStateReady;
            [self dispatchEvent:kIMAGE_EVENT_COMPLETE data:nil];
        }
        else
        {
            _state = HLImageLoaderStateUnset;
            [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
        }
        
    } else {
        
        _state = HLImageLoaderStateUnset;
        [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
        
    }
    
}

//清除请求
- (void)releaseRequestObject {
    
    _response    = nil;
    _connection  = nil;
    _receiveData = nil;
    
}

//获取图片的大小
- (CGRect)clipImageRect:(UIImage *)image {
    
    if (image == nil) {
        return CGRectZero;
    }
    
    CGFloat vw = _clipSize.width;
    CGFloat vh = _clipSize.height;
    
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    
    CGFloat scale = w/vw < h/vh ? w/vw : h/vh;
    
    vw = vw * scale;
    vh = vh * scale;
    
    switch (_imageClipType) {
        case HLImageClipTypeCenter:
        {
            return CGRectMake((w - vw)/2, (h - vh)/2, vw, vh);
        }
            break;
            
        case HLImageTypeBottom:
        {
            return CGRectMake((w - vw)/2, h - vh, vw, vh);
        }
            break;
            
        case HLImageClipTypeTop:
        {
            return CGRectMake((w - vw) / 2, h - vh, vw, vh);
        }
            break;
            
        case HLImageClipTypeNone:
        {
            return CGRectZero;
        }
            break;
    }
}

//处理裁剪图片的数据
- (void)dealClipImageWithData:(NSData *)data needEvent:(BOOL)needEvent {
    
    //进行裁剪
    UIImage *srcImg  = [UIImage imageWithData:data];
    
    CGRect clipRect  = [self clipImageRect:srcImg];
    
    UIImage *clipImg = [Graphics clipImage:srcImg rect:clipRect];
    
    _content = clipImg;
    
    if (needEvent) {
        if (_content) {
            
            NSData *clipData = UIImageJPEGRepresentation(_content, 0.6);
            
            if (clipData == nil) {
                
                [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
                
            } else {
                
                [self dispatchEvent:kIMAGE_EVENT_COMPLETE
                               data:[NSDictionary dictionaryWithObject:clipData forKey:@"data"]];
                
            }
        } else {
            
            [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
            
        }
    }
}

//处理圆角图片数据
- (void)dealRoundCornerRectImageWithData:(NSData *)data needEvent:(BOOL)needEvent {

    UIImage *srcImage           = [UIImage imageWithData:data];
    
    UIImage *roundedCornerImage = [Graphics createRoundedRectImage:srcImage
                                                              size:srcImage.size
                                                         ovalWidth:_fCornerRadius
                                                        ovalHeight:_fCornerRadius];
    
    _content = roundedCornerImage;
    
    if (needEvent) {
        
        if (_content) {
            
            NSData *targetData = UIImagePNGRepresentation(_content);
            
            if (targetData == nil) {
                
                [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
                
            } else {
                
                [self dispatchEvent:kIMAGE_EVENT_COMPLETE
                               data:[NSDictionary dictionaryWithObject:targetData forKey:@"data"]];
                
            }
        } else {
            
            [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
            
        }
    }
}

//裁剪图片
- (void)dealClipRoundImageWidthData:(NSData *)data needEvent:(BOOL)needEvent {
    
    UIImage *srcImage = [UIImage imageWithData:data];
    
    CGFloat w = srcImage.size.width;
    CGFloat h = srcImage.size.height;
    
    CGFloat length = MIN(w, h);
    
    CGRect rect    = CGRectMake((w - length) / 2, (h - length) / 2, length, length);
    
    UIImage *roundCornerImage = [Graphics createRoundedRectImage:srcImage
                                                            rect:rect
                                                        ovalWith:length/2
                                                      ovalHeight:length/2];
    
    _content = roundCornerImage;
    
    if (needEvent) {
        
        if (_content) {
            
            NSData *targetData = UIImagePNGRepresentation(_content);
            
            if (targetData == nil) {
                
                [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
                
            } else {
                
                [self dispatchEvent:kIMAGE_EVENT_COMPLETE
                               data:[NSDictionary dictionaryWithObject:targetData forKey:@"data"]];
                
            }
        } else {
            
            [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
            
        }
    }
}


#pragma mark - 网络处理状态
//请求失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    _state = HLImageLoaderStateUnset;
    
    //派发异常事件
    [self dispatchEvent:kIMAGE_EVENT_ERROR
                   data:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
    //取消请求
    [self releaseRequestObject];
    
}

//请求到数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    //拼接数据
    [_receiveData appendData:data];
    
    _loadPer = ((double)_receiveData.length)/_expectedContentLength;
    
    [self dispatchEvent:kIMAGE_EVENT_LOAD_PER
                   data:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:_loadPer]
                                                    forKey:@"load_per"]];
}

//数据请求连接成功
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    //数据的总长度
    _expectedContentLength = response.expectedContentLength;
    
    
    _response = response;
}

//数据请求完毕
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)_response;
    
    if ([response statusCode]/100 == 2) {
        
        //请求成功
        _state = HLImageLoaderStateReady;
        
        NSData *data = [NSData dataWithData:_receiveData];
        
        switch (_iDealType) {
            case 1:
            {
                [self dealClipImageWithData:data needEvent:YES];
            }
                break;
                
            case 2:
            {
                [self dealRoundCornerRectImageWithData:data needEvent:YES];
            }
                break;
            case 3:
            {
                [self dealClipRoundImageWidthData:data needEvent:YES];
            }
                break;
            default:
            {
                _content = [UIImage imageWithData:data];
                
                if (_content) {
                    
                    [self dispatchEvent:kIMAGE_EVENT_COMPLETE
                                   data:[NSDictionary dictionaryWithObject:data forKey:@"data"]];
                    
                } else {
                    
                    _state = HLImageLoaderStateUnset;
                    
                    [self dispatchEvent:kIMAGE_EVENT_ERROR data:nil];
                    
                }
                
            }
                break;
        }
    } else {
        
        _state = HLImageLoaderStateUnset;
        
        //请求失败
        [self dispatchEvent:kIMAGE_EVENT_FAIL
                       data:[NSDictionary dictionaryWithObject:_response forKey:@"response"]];
        
    }
    
    //取消请求
    [self releaseRequestObject];
    
}

@end
