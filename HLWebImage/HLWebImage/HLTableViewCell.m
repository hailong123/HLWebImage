//
//  HLTableViewCell.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/8.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "HLTableViewCell.h"

@interface HLTableViewCell ()

@property (nonatomic, strong) HLWebImage *img;

@end


@implementation HLTableViewCell

@synthesize imgStr = _imgStr;

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    _img              = [[HLWebImage alloc] init];
    _img.bounds       = self.contentView.bounds;
    _img.center       = self.contentView.center;
    _img.defaultImage = [UIImage imageNamed:@"img"];
    [self addSubview:_img];
    
}

- (void)setImgStr:(NSString *)imgStr {
    
    _imgStr = imgStr;
    
    [_img loadImageWithUrlString:_imgStr];
//    [_img loadRoundImageWithUrlString:_imgStr];
//    [_img loadImageWithUrlString:_imgStr cornerRadius:20];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
