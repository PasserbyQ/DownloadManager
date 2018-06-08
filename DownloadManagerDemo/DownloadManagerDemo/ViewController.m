//
//  ViewController.m
//  DownloadManagerDemo
//
//  Created by Zhang jiyong on 2018/6/8.
//  Copyright © 2018年 PasserbyQ. All rights reserved.
//

#import "ViewController.h"
#import "QYDownloadManager.h"

@interface ViewController ()

@property (nonatomic, strong) NSString *url;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _url = @"http://39.104.84.2:8088/1_14130/5257a232909f43de0f2051158b1ea8bf.vo";
    [[QYDownloadManager sharedInstance] download:_url progress:^(NSInteger receivedSize, NSInteger expectedSize, float progress) {
        NSLog(@"进度%f",progress*100);
    } success:^(NSString *fileStorePath) {
        
    } faile:^(NSError *error) {
        
    }];
}

- (IBAction)start:(id)sender {
    [[QYDownloadManager sharedInstance] handleTask:_url];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
