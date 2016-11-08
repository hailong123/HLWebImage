//
//  ViewController.m
//  HLWebImage
//
//  Created by 123456 on 2016/11/1.
//  Copyright © 2016年 KuXing. All rights reserved.
//

#import "ViewController.h"

#import "HLTableViewCell.h"

NSString * const kIdentifier = @"TableViewCellID";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView *tableView;


@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 150;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    
    if (indexPath.row %2 == 0) {
        
        cell.imgStr = @"http://fdfs.xmcdn.com/group8/M02/ED/4E/wKgDYFagTTGQpgWTAAA6YH5lMbo811.jpg";
        
    } else {
        
        cell.imgStr = @"http://b.appsimg.com/2016/11/07/5771/14785238835717.jpg";
        
    }
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [tableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
