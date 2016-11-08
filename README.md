# HLWebImage

###类型SDWebImage部分功能的学习demo (持续更新......)
![demo.gif](https://github.com/hailong123/HLWebImage/blob/master/%E6%98%BE%E7%A4%BA%E6%95%88%E6%9E%9C/%E7%B1%BB%E4%BC%BCSDWebImage%E5%8A%9F%E8%83%BD%E7%9A%84demo.gif)


>###实例化方法

    HLWebImage*_img   = [[HLWebImage alloc] init];
    _img.defaultImage = [UIImage imageNamed:@"img"];
    [self addSubview:_img];
    
>###使用方法

     [_img loadImageWithUrlString:_imgStr];
