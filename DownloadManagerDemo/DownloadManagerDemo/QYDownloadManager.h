//
//  QYDownloadManager.h
//  DownloadManagerDemo
//
//  Created by Zhang jiyong on 2018/6/8.
//  Copyright © 2018年 PasserbyQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYDownloadModel.h"

@interface QYDownloadManager : NSObject

//单例
+ (instancetype)sharedInstance;

//开启任务下载资源
- (void)download:(NSString *)url
        progress:(progressBlock)progressBlock
         success:(successBlock)successBlock
           faile:(faileBlock)faileBlock;

//判断该资源是否下载完成
- (BOOL)isCompletion:(NSString *)url;

//删除资源
- (void)deleteFile:(NSString *)url;

//清空所有资源
- (void)deleteAllFile;

- (void)handleTask:(NSString *)url;

@end
