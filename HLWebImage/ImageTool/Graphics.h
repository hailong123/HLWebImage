//
//  Graphics.h
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DEFAULT_BLUR_LEVEL (5)

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

@interface Graphics : NSObject

/***********************
 * 说明:等比例缩放图片
 *
 * 参数:image 图片对象
 *     size  缩放图片的尺寸,如果尺寸不是按照等比例设置,则函数按照宽度或高度最大比例进行等比例缩放
 * 返回:等比缩放后的图片对象
 **********************/
+ (UIImage *)scaleImage:(UIImage *)image size:(CGSize)size;

/***********************
 * 说明:创建标准照片
 *
 * 参数:image 图片对象
 * 返回:照片存放的临时路径
 **********************/
+ (NSString *)createHDPhotoImage:(UIImage *)image;
+ (NSString *)createStandardPhotoImage:(UIImage *)image;


/***********************
 * 说明:创建标准用户头像
 *
 * 参数:image 图片对象
 * 返回:用户头像存放的临时路径
 **********************/
+ (NSString *)createStandarUserAvatarImage:(UIImage *)image;


/***********************
 * 说明:创建用户头图片
 *
 * 参数:image:      图片对象
 *      size:      头像大小
 *      ovalWidth: 圆角角度
 *      ovalHeight:圆角高度
 *
 * 返回:用户头像存放的临时路径
 **********************/
+ (NSString *)createUserAvatarImage:(UIImage *)image
                               size:(CGSize)size
                          ovalWidth:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight;


/***********************
 * 说明:保存JPEG图片到临时目录
 *
 * 参数:image 图片对象
 * 返回:照片存放的临时路径
 **********************/
+ (NSString *)saveJPEGImageToTmpDicectory:(UIImage *)image;


/***********************
 * 说明:保存JPEG图片到缓存目录
 *
 * 参数:image 图片对象
 * 返回:照片存放的缓存路径
 **********************/
+ (NSString *)saveJPEGImageToCacheDirectory:(UIImage *)image;

/***********************
 * 说明:保存JPEG图片到指定目录
 *
 * 参数:image:图片对象
 *      path:指定的目录
 **********************/
+ (void)saveJPEGImageToTmpDirectory:(UIImage *)image path:(NSString *)path;

/****************************
 * 说明：保存PNG照片到临时目录
 * 参数：image			需要保存的图像对象
 * 返回：图片保存的临时路径
 ****************************/
+ (NSString *)savePNGImageToTmpDirectory:(UIImage *)image;

/****************************
 * 说明：保存照片到照片库
 * 参数：image			需要保存的图像对象
 * 返回：图片保存的照片库路径
 ****************************/
+ (NSString *)saveImageToWallPaperLibrary:(UIImage *)image;

/****************************
 * 说明：将颜色值描述字符串转换为UIColor
 * 参数：value			颜色值描述字符串
 * 返回：颜色对象引用
 ****************************/
+ (UIColor *)colorFormString:(NSString *)value;

/****************************
 * 说明：创建圆角图片
 * 参数：image			原图像
 *		size			圆角图像的图片尺寸
 *		ovalWidth		圆角宽度
 *		ovalHeight		圆角高度
 * 返回：圆角图片对象引用
 ****************************/
+ (UIImage *)createRoundedRectImage:(UIImage *)image
                               size:(CGSize)size
                          ovalWidth:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight;


/****************************
 * 说明：创建圆角图片
 * 参数：image			原图像
 *		rect			矩形范围
 *		ovalWidth		圆角宽度
 *		ovalHeight		圆角高度
 * 返回：圆角图片对象引用
 ****************************/
+ (UIImage *)createRoundedRectImage:(UIImage *)image
                               rect:(CGRect)rect
                           ovalWith:(CGFloat)ovalWidth
                         ovalHeight:(CGFloat)ovalHeight;


/****************************
 * 说明：绘制圆角矩形
 * 参数：context		上下文对象
 *		rect		矩形范围
 *		ovalWidth	圆角宽度
 *		ovalHeight	圆角高度
 ****************************/
+ (void)drawRoundedRect:(CGContextRef)context
                   rect:(CGRect)rect
              ovalWidth:(CGFloat)ovalWidth
             ovalHeight:(CGFloat)ovalHeight;

/*****************************
 * 说明：转换视图为图片
 * 参数：view			视图对象
 * 返回：图片对象
 *****************************/
+ (UIImage *)converToJPEGImageWithView:(UIView *)view;

/*****************************
 * 说明：转换PNG文件数据
 * 参数：image		图片对象
 * 返回：数据对象
 *****************************/
+ (NSData *)convertToPNGImageData:(UIImage *)image;

/*****************************
	裁剪图片
	参数:  image 图片对象
	      rect 裁剪范围
	返回: 裁剪后的图片对象
 *****************************/
+ (UIImage *)clipImage:(UIImage *)image rect:(CGRect)rect;

/*****************************
	获取拍照后编辑的图片，由于ImagePicker裁剪后会出现黑色区域问题。
 此方法返回没有黑色区域照片对象。
	参数: originalImage 原图照片
         editImage imagePicker编辑后的照片
	     cropRect 裁剪区域
	返回: 编辑后的照片对象
 *****************************/
+ (UIImage *)cameraEditImageWithOriginalImage:(UIImage *)originalImage
                                    editImage:(UIImage *)editImage
                                     cropRect:(CGRect)cropRect;

/*****************************
 *  获取Accelerate库生产的高斯图
 *  参数: image 原始图
 *       level 高斯等级 0~1
 *
 *  返回: 高斯图
 *****************************/
+ (UIImage *)accelerateBlurWithImage:(UIImage *)image blurLevel:(CGFloat)blur;

/****************************
 *  获取图片的倒影图
 *
 *  参数: image  原图
 *       height 目标图片高度
 *       per    倒影在目标图片中的比例
 *
 *  返回: 目标图
 *****************************/
+ (UIImage *)reflectionImage:(UIImage *)image
                      height:(float)height
               reflectionPer:(float)per;

/****************************
 * 说明：创建标准照片，对图片字节流进行压缩(6.2添加仅适用于聊天)
 * 参数：image			图像对象
 * 返回：照片存放的临时路径
 *****************************/
+ (NSString *)createCompressPhotoImage:(UIImage *)image;

/****************************
 * 说明：保存字节流压缩Jpeg照片到临时目录(6.2添加仅适用于聊天)
 * 参数：image			需要保存的图像对象
 * 返回：图片保存的临时路径
 ****************************/
+ (NSString *)saveCompressJPEGImageToTmpDirectory:(UIImage *)image;
@end
