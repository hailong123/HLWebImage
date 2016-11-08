//
//  Graphics.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//图片处理工具

#import "Graphics.h"

#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

#define USER_AVATAR_WIDTH       136.0
#define USER_AVATAR_HEIGHT      136.0
#define USER_AVATAR_OVAL_WIDTH  15.0
#define USER_AVATAR_OVAL_HEIGHT 15.0

#define PHOTO_WIDTH     640
#define PHOTO_HEIGHT    640
#define HD_PHOTO_WIDTH  640
#define HD_PHOTO_HEIGHT 960

@implementation Graphics

#pragma mark - Private

CGImageRef CreateReflectGradientMaskImage (int pixelsWidth, int pixelsHeiaght,CGFloat gradientPer) {
    
    CGImageRef theCGImage = NULL;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL,
                                                               pixelsWidth,
                                                               pixelsHeiaght,
                                                               8, 0,
                                                               colorSpace,
                                                               kCGImageAlphaNone);
    
    CGFloat colors[] = {
        1,1.0,
        0,1.0,
        0,1.0
    };
    
    CGFloat locations[] = {0,gradientPer,1};
    
    CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 3);
    
    CGColorSpaceRelease(colorSpace);
    
    CGPoint gradientStartPoint = CGPointMake(0, pixelsHeiaght);
    CGPoint gradientEndPoint   = CGPointMake(0, 0);
    
    CGContextDrawLinearGradient(gradientBitmapContext,
                                grayScaleGradient,
                                gradientStartPoint,
                                gradientEndPoint,
                                kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(grayScaleGradient);
    
    theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
    
    CGContextRelease(gradientBitmapContext);
    
    return theCGImage;
}

CGContextRef CreateCGContext (CGSize size) {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             size.width,
                                             size.height,
                                             8, 0,
                                             colorSpace,
                                             kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    return ctx;
}

#pragma mark - Mothed

//等比例缩放照片
+ (UIImage *)scaleImage:(UIImage *)image size:(CGSize)size {
    
    int kMaxResolution = MIN(size.width, size.height);
    
    CGImageRef imgRef  = image.CGImage;
    
    CGFloat width  = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if (width > kMaxResolution || height > kMaxResolution) {
        
        CGFloat ratio = width / height;
        
        if (ratio > 1) {
            
            bounds.size.width  = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
            
        } else {
            
            bounds.size.height = kMaxResolution;
            bounds.size.width  = bounds.size.height * ratio;
            
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    
    CGFloat boundHeight;
    
    UIImageOrientation orient = image.imageOrientation;
    
    //图片的方向
    switch (orient) {
        case UIImageOrientationUp:
        {
            transform = CGAffineTransformIdentity;
        }
            break;
            
        case UIImageOrientationUpMirrored:
        {
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
        }
            break;
            
        case UIImageOrientationDown:
        {
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
        }
            break;
            
        case UIImageOrientationDownMirrored:
        {
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
        }
            
            break;
            
        case UIImageOrientationLeft:
        {
            boundHeight        = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundHeight;
            
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0*M_PI / 2.0);
        }
            
            break;
            
        case UIImageOrientationLeftMirrored:
        {
            boundHeight        = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundHeight;
            
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0*M_PI/2.0);
        }
            
            break;
            
        case UIImageOrientationRight:
        {
            boundHeight        = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundHeight;
            
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI/2.0);
        }
            
            break;
            
        case UIImageOrientationRightMirrored:
        {
            boundHeight        = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundHeight;
            
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI/2.0);
        }
            
            break;
            
        default:
            
            [NSException raise:NSInternalInconsistencyException format:@"Invail image orientation"];
            
            break;
    }
    //floorf 如果参数是小数，则求最大的整数但不大于本身.
    UIGraphicsBeginImageContext(CGSizeMake(floorf(bounds.size.width), floorf(bounds.size.height)));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
        
    } else {
        
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
        
    }
    
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, floorf(width), floorf(height)), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}


//保存Jpeg照片到缓存目录
+ (NSString *)saveJPEGImageToCacheDirectory:(UIImage *)image {
    
    //获取到地址
    NSString *tmpPath = [NSString stringWithFormat:@"%@/Library/Caches/",NSHomeDirectory()];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    //图片进行压缩
    NSData *imgData = UIImageJPEGRepresentation(image, 0.5);
    
    //生成唯一文件名
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    
    NSString *tmpFileName = [NSString stringWithFormat:@"%@%@.jpg",tmpPath,uuidStr];
    CFRelease((__bridge CFTypeRef)(uuidStr));
    
    [[NSFileManager defaultManager] createFileAtPath:tmpFileName contents:imgData attributes:nil];
    
    return tmpFileName;
}

//保存Jpeg到指定目录
+ (void)saveJPEGImageToTmpDirectory:(UIImage *)image path:(NSString *)path {
    
    NSData *imgData = UIImageJPEGRepresentation(image, 0.5);
    
    NSParameterAssert(path);
    
    [imgData writeToFile:path atomically:YES];
    
}

//保存PNG照片到临时目录
+ (NSString *)savePNGImageToTmpDirectory:(UIImage *)image {
    
    NSString *tmpPath = [NSString stringWithFormat:@"%@/tmp/upload/",NSHomeDirectory()];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSData *imgData = UIImagePNGRepresentation(image);
    
    //生成唯一文件名
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    
    NSString *tmpFileName = [NSString stringWithFormat:@"%@%@.jpg",tmpPath,uuidStr];
    CFRelease((__bridge CFTypeRef)(uuidStr));
    
    [[NSFileManager defaultManager] createFileAtPath:tmpFileName contents:imgData attributes:nil];
    
    return tmpFileName;
}

//保存照片到照片库
+ (NSString *)saveImageToWallPaperLibrary:(UIImage *)image {
    
    NSString *tmpPath = [NSString stringWithFormat:@"%@/tmp/Wallpaper/",NSHomeDirectory()];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSData *imgData = UIImagePNGRepresentation(image);
    
    //生成唯一文件名
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    
    NSString *fileName = [NSString stringWithFormat:@"%@%@.png",tmpPath,uuidStr];
    CFRelease((__bridge CFTypeRef)(uuidStr));
    
    [[NSFileManager defaultManager] createFileAtPath:fileName contents:imgData attributes:nil];
    
    [imgData writeToFile:fileName atomically:YES];
    
    return fileName;
}

//保存字节流压缩Jpeg照片到临时目录(6.2添加仅适用于聊天)
+ (NSString *)saveCompressJPEGImageToTmpDirectory:(UIImage *)image {
    
    NSString *tmpPath = [NSString stringWithFormat:@"%@/tmp/upload/",NSHomeDirectory()];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSData *imgData = UIImageJPEGRepresentation(image, 0.3);
    
    //生成唯一文件名
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    
    NSString *tmpFileName = [NSString stringWithFormat:@"%@%@.jpg",tmpPath,uuidStr];
    CFRelease((__bridge CFTypeRef)(uuidStr));
    
    [[NSFileManager defaultManager] createFileAtPath:tmpFileName contents:imgData attributes:nil];
    [imgData writeToFile:tmpFileName atomically:YES];
    
    return tmpFileName;
}

//创建标准照片
+ (NSString *)createStandardPhotoImage:(UIImage *)image {
    
    UIImage *scaleImg;
    
    if (image.size.width > PHOTO_WIDTH || image.size.height > PHOTO_HEIGHT) {
        scaleImg = [Graphics scaleImage:image size:CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT)];
    } else {
        scaleImg = image;
    }
    
    return [Graphics saveJPEGImageToTmpDicectory:scaleImg];
}

+ (NSString *)createHDPhotoImage:(UIImage *)image {
    
    UIImage *scaleImg;
    
    if (image.size.width > HD_PHOTO_WIDTH || image.size.width > HD_PHOTO_HEIGHT) {
        
        scaleImg = [Graphics scaleImage:image size:CGSizeMake(HD_PHOTO_WIDTH, HD_PHOTO_HEIGHT)];
        
    } else {
        
        scaleImg = image;
        
    }
    
    return [Graphics saveJPEGImageToTmpDicectory:scaleImg];
}

//创建标准照片，对图片字节流进行压缩(6.2添加仅适用于聊天)
+ (NSString *)createCompressPhotoImage:(UIImage *)image {
    
    UIImage *scaleImg;
    
    if ((image.size.width > HD_PHOTO_WIDTH || image.size.height > HD_PHOTO_HEIGHT) && image.size.height / image.size.width <=2) {
        scaleImg = [Graphics scaleImage:image size:CGSizeMake(HD_PHOTO_WIDTH, HD_PHOTO_HEIGHT)];
    } else {
        scaleImg = [Graphics scaleImage:image size:CGSizeMake(image.size.width, image.size.height)];
    }
    
    return [Graphics saveCompressJPEGImageToTmpDirectory:scaleImg];
    
}

//创建标准用户头像
+ (NSString *)createStandarUserAvatarImage:(UIImage *)image {
    
    return [Graphics createUserAvatarImage:image
                                      size:CGSizeMake(USER_AVATAR_WIDTH, USER_AVATAR_HEIGHT)
                                 ovalWidth:USER_AVATAR_OVAL_WIDTH
                                ovalHeight:USER_AVATAR_OVAL_HEIGHT];
    
}

+ (NSString *)createUserAvatarImage:(UIImage *)image
                               size:(CGSize)size
                          ovalWidth:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight {
    
    UIImage *scaleImg   = [Graphics scaleImage:image size:size];
    
    UIImage *roundedImg = [Graphics createRoundedRectImage:scaleImg
                                                      size:size
                                                 ovalWidth:ovalWidth
                                                ovalHeight:ovalHeight];
    
    return [Graphics savePNGImageToTmpDirectory:roundedImg];
    
}

//将颜色值描述字符串转换为UIColor
+ (UIColor *)colorFormString:(NSString *)value {
    
    UIColor *colorRef = nil;
    
    if (value != nil) {
        
        NSInteger tmp = 0;
        
        if ([value characterAtIndex:0] == '#') {
            
            tmp = strtoul([[value substringFromIndex:1] UTF8String], nil, 16);
            
        } else {
            
            tmp = strtoul([value UTF8String], nil, 16);
            
        }
        
        NSInteger blue  = tmp & 0xff;
        NSInteger green = tmp>>8 & 0xff;
        NSInteger red   = tmp>>16 & 0xff;
        
        colorRef = [UIColor colorWithRed:red/255.0
                                   green:green/255.0
                                    blue:blue/255.0
                                   alpha:1.0];
    }
    
    return colorRef;
    
}

//绘制圆角矩形
+ (void)drawRoundedRect:(CGContextRef)context
                   rect:(CGRect)rect
              ovalWidth:(CGFloat)ovalWidth
             ovalHeight:(CGFloat)ovalHeight {
    
    float fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    
    fw = CGRectGetWidth(rect)/ovalWidth;
    fh = CGRectGetHeight(rect)/ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
    
}

//创建圆角图片
+ (UIImage *)createRoundedRectImage:(UIImage *)image
                               size:(CGSize)size
                          ovalWidth:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight {
    
    int weight = size.width;
    int height = size.height;
    
    UIImage *img               = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = CGBitmapContextCreate(NULL, weight, height, 8, 4*weight, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect                = CGRectMake(0, 0, weight, height);
    
    CGContextBeginPath(context);
    
    [Graphics drawRoundedRect:context rect:rect ovalWidth:ovalWidth ovalHeight:ovalHeight];
    
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, weight, height), img.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *targetImage   = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    
    return targetImage;
}

+ (UIImage *)createRoundedRectImage:(UIImage *)image
                               rect:(CGRect)rect
                           ovalWith:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight {
    
    int w = rect.size.width;
    int h = rect.size.height;
    
    UIImage *img               = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextBeginPath(context);
    
    [Graphics drawRoundedRect:context
                         rect:CGRectMake(0, 0, w, h)
                    ovalWidth:ovalWidth
                   ovalHeight:ovalHeight];
    
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextDrawImage(context, CGRectMake( -rect.origin.x, -rect.origin.y , img.size.width, img.size.height), img.CGImage);
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage * targetImage = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    return targetImage;
    
}

//转换视图为图片
+ (UIImage *)converToJPEGImageWithView:(UIView *)view {
    
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    image             = [UIImage imageWithData:imageData];
    
    return image;
}

//转换PNG文件数据
+ (NSData *)convertToPNGImageData:(UIImage *)image {
    
    return UIImagePNGRepresentation(image);
    
}

//裁剪图片
+ (UIImage *)clipImage:(UIImage *)image rect:(CGRect)rect {
    
    if (image == nil) {
        return nil;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        {
            rect = CGRectMake(rect.origin.y,
                              rect.origin.x,
                              rect.size.height,
                              rect.size.width);
        }
            break;
            
        case UIImageOrientationRight:
        {
            rect = CGRectMake(rect.origin.y,
                              image.size.width - rect.size.width - rect.origin.x,
                              rect.size.height,
                              rect.size.width);
        }
            break;
        case UIImageOrientationDown:
        {
            rect = CGRectMake(image.size.width - rect.size.width - rect.origin.x,
                              image.size.height - rect.size.height - rect.origin.y,
                              rect.size.width,
                              rect.size.height);
        }
            break;
    }
    
    CGImageRef clilpImageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    CGRect clipBounds        = CGRectMake(0, 0, CGImageGetWidth(clilpImageRef), CGImageGetHeight(clilpImageRef));
    
    UIGraphicsBeginImageContext(clipBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, clipBounds, clilpImageRef);
    UIGraphicsEndImageContext();
    
    UIImage *clipImage = [UIImage imageWithCGImage:clilpImageRef
                                             scale:image.scale
                                       orientation:image.imageOrientation];
    CGImageRelease(clilpImageRef);
    
    return clipImage;
}

//获取拍照后编辑的图片，由于ImagePicker裁剪后会出现黑色区域问题。此方法返回没有黑色区域照片对象。
+ (UIImage *)cameraEditImageWithOriginalImage:(UIImage *)originalImage
                                    editImage:(UIImage *)editImage
                                     cropRect:(CGRect)cropRect {
    
    
    //计算原图需要裁剪的区域
    CGRect rect = CGRectMake(0.0, 0.0, cropRect.size.width, cropRect.size.height);
    
    if (cropRect.origin.x > 0) {
        rect.origin.x = cropRect.origin.x;
    } else {
        rect.size.width -= cropRect.origin.x;
    }
    
    if (cropRect.origin.y > 0) {
        rect.origin.y = cropRect.origin.y;
    } else {
        rect.size.height -= cropRect.origin.y;
    }
    
    if (rect.origin.x + rect.size.width > originalImage.size.width) {
        rect.size.width = originalImage.size.width - rect.origin.x;
    }
    
    if (rect.origin.y + rect.size.height > originalImage.size.height) {
        rect.size.height = originalImage.size.height - rect.origin.y;
    }
    
    //参见原图
    UIImage *image = [Graphics clipImage:originalImage rect:rect];
    
    //拉伸原图
    return [Graphics scaleImage:image size:editImage.size];
}

//获取Accelerate库生产的高斯图
+ (UIImage *)accelerateBlurWithImage:(UIImage *)image blurLevel:(CGFloat)blur {
    
    image = [UIImage imageWithData:UIImageJPEGRepresentation(image, 0.5)];
    
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    
    int boxSize = (int)(blur * 40);
    boxSize     = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    //create vImage_Buffer with data from CGImageRef
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData       = CGDataProviderCopyData(inProvider);
    
    inBuffer.width    = CGImageGetWidth(img);
    inBuffer.height   = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data     = pixelBuffer;
    outBuffer.width    = CGImageGetWidth(img);
    outBuffer.height   = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2  = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data     = pixelBuffer2;
    outBuffer2.width    = CGImageGetWidth(img);
    outBuffer2.height   = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef  = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    free(pixelBuffer2);
    CFRelease(inBitmapData);
    CGImageRelease(imageRef);
    
    return returnImage;
    
}

//获取图片的倒影图
+ (UIImage *)reflectionImage:(UIImage *)image height:(float)height reflectionPer:(float)per {
    
    if (image == nil && height < 0) {
        return nil;
    }
    
    UIImage *reflectUIImg   = nil;
    CGImageRef reflectCGImg = NULL;
    
    per = per > 1 ? 1 : per;
    per = per < 0 ? 0 : per;
    
    CGSize reflectImgSize = CGSizeMake(image.size.width, height);
    
    CGContextRef ctx = CreateCGContext(reflectImgSize);
    CGContextSetAllowsAntialiasing(ctx, true);
    CGContextSetShouldAntialias(ctx, true);
    
    //画蒙版
    CGImageRef maskCGImg = CreateReflectGradientMaskImage(1, height, per);
    CGContextClipToMask(ctx, CGRectMake(0, 0, reflectImgSize.width, reflectImgSize.height), maskCGImg);
    CGImageRelease(maskCGImg);
    
    //画相反图
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, reflectImgSize.height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    CGContextRestoreGState(ctx);
    
    reflectCGImg = CGBitmapContextCreateImage(ctx);
    
    reflectUIImg = [[UIImage alloc] initWithCGImage:reflectCGImg];
    
    CGImageRelease(reflectCGImg);
    
    CGContextRelease(ctx);
    
    return reflectUIImg;
    
}
@end
