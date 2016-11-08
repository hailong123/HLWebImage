//
//  HLImagePool.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/2.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "HLImagePool.h"

#import "NSString+MD5.h"

@interface ImageLoaderInfo :NSObject

@property (nonatomic, strong) HLImageLoader *loader;

@property (nonatomic, copy) NSString *urlStr;

@end

@implementation ImageLoaderInfo

- (void)dealloc {
    
    self.loader = nil;
    self.urlStr = nil;
}

@end

@interface LoadImageOperation :NSOperation {
    //处理中的数组
    NSMutableArray *_handlingLoaderArr;
    //等待中的数组
    NSMutableArray *_waitingLoaderArr;
    
    //最大的处理数量
    NSInteger _maxHandlingCount;
    
    BOOL _finished;
    
    NSDate  *_idleDate;
    NSTimer *_checkIdleTimer;
    NSTimeInterval _maxIdleTime;
    
    NSThread *_thread;
}

- (BOOL)pushLoaderInfo:(ImageLoaderInfo *)info;

@end

@implementation LoadImageOperation

- (instancetype)init {
    
    if (self = [super init]) {
        
        _handlingLoaderArr = [NSMutableArray array];
        _waitingLoaderArr  = [NSMutableArray array];
        
        _finished = NO;
        
        //闲置时间
        _maxIdleTime      = 2;
        //最大处理数量
        _maxHandlingCount = 4;
        
    }
    
    return self;
}

//加入等待队列
- (BOOL)pushLoaderInfo:(ImageLoaderInfo *)info {
    
    @synchronized (self) {
        
        if (_finished) {
            
            return NO;
            
        }
        
        for (ImageLoaderInfo *aInfo in _waitingLoaderArr) {
            
            if (aInfo.loader == info.loader) {
                
                [_waitingLoaderArr removeObject:info];
                
            }
        }
        
        [_waitingLoaderArr addObject:info];
        
        return YES;
    }
}

//返回加载信息
- (ImageLoaderInfo *)popLoadingInfo {
    
    @synchronized (self) {
        
        if (_waitingLoaderArr.count > 0) {
            
            ImageLoaderInfo *info = [_waitingLoaderArr objectAtIndex:0];
            
            [_waitingLoaderArr removeObject:info];
            
            return info;
        }
        
        return nil;
    }
}

- (void)main {
    
    @autoreleasepool {
        
        _checkIdleTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(checkIdleTime) userInfo:nil repeats:YES];
        
        //同run方法，增加超时参数limitDate，避免进入无限循环 (停止定时器)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
        
    }
 
}

//检查闲置时间
- (void)checkIdleTime {
    
    @synchronized (self) {
        
        if (_handlingLoaderArr.count >= _maxHandlingCount) {
            //加载的图片太多了
            return;
        }
        
        //拿到当前的加载信息
        ImageLoaderInfo *loaderInfo = [self popLoadingInfo];
        
        if (loaderInfo == nil) {
            //没有任务了
            if (_idleDate == nil) {
                
                _idleDate = [NSDate date];
                
            }
            
            if (([[NSDate date] timeIntervalSinceDate:_idleDate] > _maxIdleTime) && _handlingLoaderArr.count == 0) {
                
                _finished = YES;
                
                //取消定时器
                [_checkIdleTimer invalidate];
                
                _checkIdleTimer = nil;
            }
        } else {

            _idleDate = nil;
            
            //添加监听事件
            [loaderInfo.loader addEventListener:kIMAGE_EVENT_FAIL     target:self selector:@selector(onLoaderFinished:)];
            [loaderInfo.loader addEventListener:kIMAGE_EVENT_ERROR    target:self selector:@selector(onLoaderFinished:)];
            [loaderInfo.loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onLoaderFinished:)];
            
            //加载图片
            [loaderInfo.loader loadImageWithURL:loaderInfo.urlStr];
            //添加到队列中
            [_handlingLoaderArr addObject:loaderInfo];
        }
    }
}

//处理事件
- (void)onLoaderFinished:(NSNotification *)notification {
    
    HLImageLoader *loader = [notification object];
    
    [loader removeEventListener:kIMAGE_EVENT_FAIL     target:self];
    [loader removeEventListener:kIMAGE_EVENT_ERROR    target:self];
    [loader removeEventListener:kIMAGE_EVENT_COMPLETE target:self];
    
    for (ImageLoaderInfo *info in _handlingLoaderArr) {
        
        if (info.loader == loader) {
            
            [_handlingLoaderArr removeObject:info];
            
            break;
        }
    }
}

@end

@interface HLImagePool (Private)

//获取缓存路径
- (NSString *)chchePath;

//判断是否存在本地的缓存
- (BOOL)existsLocalCache:(NSString *)cachePath;

//获取缓存文件
- (NSString *)cacheFileName:(NSString *)cachePath;

//从队列中获取图片加载器
- (HLImageLoader *)loaderByQueue:(NSString *)cachePath;

//获取图片加载器
/*
 *  url: 图片路径
 *  返回: 加载器
 */

- (HLImageLoader *)imageLoaderWithURL:(NSString *)URL;

/*
 *  获取图片加载器
 *  url:      图片路径
 *  size:     裁剪大小
 *  clipType: 裁剪类型
 *  返回:      图片加载器
 */
- (HLImageLoader *)imageLoaderWIthURL:(NSString *)URL
                                 size:(CGSize)size
                             clipType:(HLImageClipType)clipType;

/*
 *  获取图片加载器
 *  url:          图片路径
 *  cornerRadius: 圆角
 *
 *  返回:加载器
 */

- (HLImageLoader *)imageLoaderWithURL:(NSString *)URL
                         cornerRadius:(CGFloat)cornerRadius;

/*
 *
 *  获取图片裁剪图片路径
 *
 *  url:       图片路径
 *  size:      裁剪大小
 *  clipType:  裁剪类型
 *
 *  返回:图片路径
 */
- (NSString *)clipImagePath:(NSString *)URL
                       size:(CGSize)size
                   clipType:(HLImageClipType)clipType;

/*
 *
 *  获取圆角图片路径
 *
 *  url:     图片原始路径
 *  cornerRadius:圆角大小
 *  返回:图片路径
 */

- (NSString *)cornerRadiusPath:(NSString *)URL
                  cornerRadius:(CGFloat)cornerRadius;


//图片加载失败
- (void)onImageLoadFail:(NSNotification *)notification;

//图片加载异常
- (void)onImageLoadError:(NSNotification *)notification;

//图片加载完成
- (void)onImageLoadComplete:(NSNotification *)notification;

@end

@implementation HLImagePool

//实例化
+ (HLImagePool *)shareInstance {

    static HLImagePool *_instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

//初始化
- (instancetype)init {
    
    if (self = [super init]) {
        
        _loaderQueue = [NSMutableArray array];
        _imagePool   = [NSMutableDictionary dictionary];
        
        _loadImageEngineQueue = [NSOperationQueue new];
        _loadImageEngineQueue.maxConcurrentOperationCount = 1;
        
    }
    
    return self;
}

- (void)dealloc {

    _loadImageEngineQueue = nil;

}

//是否存储本地缓存
- (BOOL)existsLocalCacheWithURL:(NSString *)URL {
    
    if (URL.length == 0) {
        return NO;
    }
    
    return [self existsLocalCache:URL.MD5];
}

//获取图片采集器
- (HLImageLoader *)image:(NSString *)URL {
    
    return [self imageLoaderWithURL:URL];
    
}

//获取裁剪后得图片采集器
- (HLImageLoader *)image:(NSString *)URL size:(CGSize)size clipType:(HLImageClipType)clipType {
    
    return [self getImageLoaderWIthURL:URL size:size clipType:clipType];
}

//获取代圆角的图片采集器
- (HLImageLoader *)image:(NSString *)URL cornerRadius:(CGFloat)cornerRadius {
    
    return [self getImage:URL cornerRadius:cornerRadius];
    
}

//获取圆角图片
- (HLImageLoader *)roundImage:(NSString *)URL {
    
    //待修复
    return [self getRoundImage:URL];
    
}

- (void)gc {
    
    NSArray *keys = [_imagePool allKeys];
    
    for (NSInteger i = 0; i < [keys count]; i++) {
        
        UIImage *img = [_imagePool objectForKey:[keys objectAtIndex:i]];
        
//        if ([img retainCount] == 1) {
//            
//            //为1 则表明只有缓冲池引用中,应该进行回收
//            [_imagePool removeObjectForKey:[keys objectAtIndex:i]];
//            
//        }
    }
}

#pragma mark - 私有实现
- (void)loadNetImageInThread:(HLImageLoader *)loader imageURL:(NSString *)urlStr {
    
    //加载网络图片对象
    [loader loadImageWithURL:urlStr];

}

//地址的转换
- (NSString *)converImageURL:(NSString *)url {
    
    return url;
}

//获取缓存路径
- (NSString *)cachePath {
    
    if (_cachePath == nil) {
        
        _cachePath = [NSString stringWithFormat:@"%@/tmp/Cache/",NSHomeDirectory()];
        
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cachePath]) {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:_cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    
    return _cachePath;
}

//判断是否存在本地缓存
- (BOOL)existsLocalCache:(NSString *)cachePath {

    NSString *fileName = [self cacheFileName:cachePath];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:fileName];
}

//获取缓存的名称
- (NSString *)cacheFileName:(NSString *)cachePath {
    
    return [NSString stringWithFormat:@"%@%@",[self cachePath],cachePath];
    
}


//获取图片加载器
- (HLImageLoader *)loaderByQueue:(NSString *)cachePath {
    
    for (NSInteger i = 0; i < [_loaderQueue count]; i++) {
        
        HLImageLoader *loader = [_loaderQueue objectAtIndex:i];
        
        if ([loader.tag isEqualToString:cachePath]) {
            return loader;
        }
    }
    
    return nil;
}

//加载网络图片的核心方法

- (HLImageLoader *)imageLoaderWithURL:(NSString *)URL {
    
    if (![URL isKindOfClass:[NSString class]]) {
        
        //非法参数返回nil
        return nil;
    }
    
        /*******************************
         先判断内存中是否有缓存图片对象,如果有则进行返回.
         否则再检测是否有本地缓存,如果有则进行加载.
         加载前需判断加载队列是已有对象的加载,如果存在则直接返回该对象,否则进行创建并进入加载队列.
         如果没有本地缓存则进行网络加载
         加载前需判断是否已有对象加载,如果存在则直接返回对象,否则进行创建并进入加载队列
        ********************************/
    
    //取得缓存名称
    NSString *cacheName = URL.MD5;
    
    if ([_imagePool objectForKey:cacheName] != nil) {
        
        HLImageLoader *loader = [[HLImageLoader alloc] init];
        
        [loader loadImageWithCache:[_imagePool objectForKey:cacheName]];
        
        return loader;
        
    } else {
        
        //判断本地缓存
        BOOL status = [self existsLocalCache:cacheName];
        
        if (status) {
            
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    //加入队列,此处需要加入同步控制,避免在多线程中请求导致加入出错
                    [_loaderQueue addObject:loader];
                    
                }
                
                //添加监听事件
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                [loader loadImageWithFilePath:[self cacheFileName:cacheName]];
            }
            return loader;
            
        } else {
            
            //进行网络加载
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列
                    [_loaderQueue addObject:loader];
                    
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL     target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR    target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                if ([URL rangeOfString:@"://"].location == NSNotFound) {
                    
                    //加载本地
                    [loader loadImageWithFilePath:URL];
                    
                } else {
                    
                    [self loadNetImageInThread:loader imageURL:[self converImageURL:URL]];
                    
                }
            }
            
            return loader;
        }
    }
}


//根据大小进行裁剪
- (HLImageLoader *)getImageLoaderWIthURL:(NSString *)URL
                                 size:(CGSize)size
                             clipType:(HLImageClipType)clipType {
    
    
    if (![URL isKindOfClass:[NSString class]]) {
        
        //非法的数值返回nil
        return nil;
    }
    
    //取得缓存名称
    NSString *cacheName = [self getClipImagePath:URL size:size clipType:clipType].MD5;
    
    if ([_imagePool objectForKey:cacheName] != nil) {
        
        HLImageLoader *loader = [[HLImageLoader alloc] init];
        
        [loader loadImageWithCache:[_imagePool objectForKey:cacheName]];
        
        return loader;
    } else {
        
        //判断本地缓存
        if ([self existsLocalCache:cacheName]) {
            
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步控制,避免在多线程中请求导致加入错误
                    [_loaderQueue addObject:loader];
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                [loader loadImageWithFilePath:[self cacheFileName:cacheName]];
            }
            
            return loader;
            
        } else {
            
            //进行网络加载
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步控制,避免在多线程中请求导入加入出错
                    [_loaderQueue addObject:loader];
                }

                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                if ([URL rangeOfString:@"://"].location == NSNotFound) {
                    
                    //加载本地数据
                    [loader loadImageWithFilePath:URL];
                } else {
                    
                    [self loadNetImageInThread:loader imageURL:[self converImageURL:URL]];
                    
                }
            }
            
            return loader;
        }
    }
    
    return nil;
}



- (HLImageLoader *)getImage:(NSString *)URL cornerRadius:(CGFloat)cornerRadius {

    if (![URL isKindOfClass:[NSString class]]) {
        
        //非法参数
        return nil;
        
    }
    
    //取得缓存名称
    NSString *cacheName = [self getCornerRadiusPath:URL cornerRadius:cornerRadius];
    
    if ([_imagePool objectForKey:cacheName] != nil) {
        
        HLImageLoader *loader = [[HLImageLoader alloc] init];
        
        [loader loadImageWithCache:[_imagePool objectForKey:cacheName]];
        
        return loader;
        
    } else {
        
        //判断本地缓存
        if ([self existsLocalCache:cacheName]) {
            
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步队列控制,避免在多线程中请求导致加入出错
                    [_loaderQueue addObject:loader];
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                [loader loadImageWithFilePath:[self cacheFileName:cacheName]];
            }
            
            return loader;
            
        } else {
            
            //进行网络加载
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步控制,避免在多线程中请求导致加入出错
                    [_loaderQueue addObject:loader];
                    
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                if ([URL rangeOfString:@"://"].location == NSNotFound) {
                    
                    //加载本地
                    [loader loadImageWithFilePath:URL];
                    
                } else {
                    
                    [self loadNetImageInThread:loader imageURL:[self converImageURL:URL]];
                }
            }
            return loader;
        }
    }
    return nil;
}

- (HLImageLoader *)getRoundImage:(NSString *)URL {
    
    if (![URL isKindOfClass:[NSString class]]) {
        
        //非法参数返回nil
        return nil;
    }
    
    //取得缓存名称
    NSString *cacheName = [self roundImagePath:URL].MD5;
    
    if ([_imagePool objectForKey:cacheName] != nil) {
        
        HLImageLoader *loader = [[HLImageLoader alloc] init];
        
        [loader loadImageWithCache:[_imagePool objectForKey:cacheName]];
        
        return loader;
        
    } else {
    
        //判断本地缓存
        if ([self existsLocalCache:cacheName]) {
            
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader     = [[HLImageLoader alloc] init];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步控制,避免再多线程中请求导致加入出错
                    [_loaderQueue addObject:loader];
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                [loader loadImageWithFilePath:[self cacheFileName:cacheName]];
            }
            
            return loader;
            
        } else {
            
            //进行网络加载
            HLImageLoader *loader = [self loaderByQueue:cacheName];
            
            if (loader == nil) {
                
                loader = [[[HLImageLoader alloc] init] initForCenterRoundClip];
                loader.tag = cacheName;
                
                @synchronized (self) {
                    
                    //加入队列,此处需要加入同步控制,避免在多线程中请求导致加入出错
                    [_loaderQueue addObject:loader];
                }
                
                [loader addEventListener:kIMAGE_EVENT_FAIL target:self selector:@selector(onImageLoadFail:)];
                [loader addEventListener:kIMAGE_EVENT_ERROR target:self selector:@selector(onImageLoadError:)];
                [loader addEventListener:kIMAGE_EVENT_COMPLETE target:self selector:@selector(onImageLoadComplete:)];
                
                if ([URL rangeOfString:@"://"].location == NSNotFound) {
                    
                    //加载本地
                    [loader loadImageWithFilePath:URL];
                    
                } else {
                    
                    [self loadNetImageInThread:loader imageURL:[self converImageURL:URL]];
                    
                }
            }
            
            return loader;
        }
    }
    
    return nil;
}

#pragma mark - 缓存图片的名称
- (NSString *)getClipImagePath:(NSString *)URL size:(CGSize)size clipType:(HLImageClipType)clipType {
    
    NSString *prefixString = @"";
    
    switch (clipType) {
            
        case HLImageClipTypeTop:
            prefixString = @"_ct";
            break;
            
        case HLImageClipTypeCenter:
            prefixString = @"_cc";
            break;
            
        case HLImageTypeBottom:
            prefixString = @"_cb";
            break;
        default:
            
            break;
    }
    
    return [NSString stringWithFormat:@"%@#%@%0.f%.0f",URL,prefixString,size.width,size.height];
    
}

- (NSString *)getCornerRadiusPath:(NSString *)url cornerRadius:(CGFloat)cornerRadius {
    
    return [NSString stringWithFormat:@"%@#_r%.0f",url,cornerRadius];
    
}

- (NSString *)roundImagePath:(NSString *)URL {
    
    return [NSString stringWithFormat:@"%@#%.0f",URL,-1.0f];
}

#pragma mark - 回调
- (void)onImageLoadComplete:(NSNotification *)notification {
    
    HLImageLoader *loader = [notification object];
    
    //移除监听
    [loader removeEventListener:kIMAGE_EVENT_FAIL target:self];
    [loader removeEventListener:kIMAGE_EVENT_ERROR target:self];
    [loader removeEventListener:kIMAGE_EVENT_COMPLETE target:self];
    
    @synchronized (self) {
        
        if ([_loaderQueue containsObject:loader]) {
            
            [_loaderQueue removeObject:loader];
            
        }
    }
    
    if (loader.sourceType == HLImageLoaderSourceTypeURL) {
        
        NSDictionary *userInfo = [notification userInfo];
        
        if (userInfo != nil) {
            
            //缓存到本地
            NSString *cacheName     = loader.tag;
            NSString *cacheFileName = [self cacheFileName:cacheName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:cacheName]) {
                
                //删除缓存文件
                [[NSFileManager defaultManager] removeItemAtPath:cacheFileName error:nil];
                
            }
            
            NSData *data = [userInfo objectForKey:@"data"];
            
            if (data) {
                //保存缓存文件到本地
                [[NSFileManager defaultManager] createFileAtPath:cacheFileName contents:data attributes:nil];
            }
        }
    } else if (loader.sourceType == HLImageLoaderSourceTypeFile) {
        
        //加入缓存池
        //PS：不保留缓存，缓存保留太多导致其他模块出现异常
        NSString *cacheName = loader.tag;
        
         if (loader.content != nil) {
             
             [_imagePool setObject:loader.content forKey:cacheName];
             
         }
    }
}

- (void)onImageLoadError:(NSNotification *)notification {
    
    HLImageLoader *loader = [notification object];
    
    [loader removeEventListener:kIMAGE_EVENT_FAIL target:self];
    [loader removeEventListener:kIMAGE_EVENT_ERROR target:self];
    [loader removeEventListener:kIMAGE_EVENT_COMPLETE target:self];
    
    @synchronized (self) {
        
        if ([_loaderQueue containsObject:loader]) {
            
            [_loaderQueue removeObject:loader];
            
        }
    }
}

- (void)onImageLoadFail:(NSNotification *)notification {
    
    HLImageLoader *loader = [notification object];
    
    //移除监听
    [loader removeEventListener:kIMAGE_EVENT_FAIL target:self];
    [loader removeEventListener:kIMAGE_EVENT_ERROR target:self];
    [loader removeEventListener:kIMAGE_EVENT_COMPLETE target:self];
    
    if (loader.sourceType == HLImageLoaderSourceTypeFile) {
        
        NSString *cacheName     = loader.tag;
        NSString *cacheFileName = [self cacheFileName:cacheName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFileName]) {
            
            //删除缓存文件
            [[NSFileManager defaultManager] removeItemAtPath:cacheFileName error:nil];
            
        }
    }
    
    @synchronized (self) {
    
        if ([_loaderQueue containsObject:loader]) {
            
            [_loaderQueue removeObject:loader];
            
        }
    }
}

@end
