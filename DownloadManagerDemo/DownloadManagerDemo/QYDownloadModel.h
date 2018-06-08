//
//  QYDownloadModel.h
//  DownloadManagerDemo
//
//  Created by Zhang jiyong on 2018/6/8.
//  Copyright © 2018年 PasserbyQ. All rights reserved.
//

#import <Foundation/Foundation.h>

//成功回调
typedef void (^successBlock) (NSString *fileStorePath);
//失败回调
typedef void (^faileBlock) (NSError *error);
//进度回调
typedef void (^progressBlock) (NSInteger receivedSize, NSInteger expectedSize, float progress);

@interface QYDownloadModel : NSObject

//流
@property (nonatomic, strong) NSOutputStream *stream;

//下载地址
@property (nonatomic, copy) NSString *url;

//获得服务器返回数据的总长度
@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic,copy) successBlock successBlock;

@property (nonatomic,copy) faileBlock failedBlock;

@property (nonatomic,copy) progressBlock progressBlock;
@end
