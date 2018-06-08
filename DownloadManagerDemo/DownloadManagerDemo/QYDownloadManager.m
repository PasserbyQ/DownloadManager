//
//  QYDownloadManager.m
//  DownloadManagerDemo
//
//  Created by Zhang jiyong on 2018/6/8.
//  Copyright © 2018年 PasserbyQ. All rights reserved.
//

#import "QYDownloadManager.h"
#import "NSString+MD5.h"

// 缓存根目录
#define QYCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"QYCache"]

// 保存文件名
#define QYFileName(url) url.md5String

// 文件的存放路径
#define QYFilePath(url) [QYCachesDirectory stringByAppendingPathComponent:QYFileName(url)]

// 文件的已下载长度
#define QYDownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:QYFilePath(url) error:nil][NSFileSize] integerValue]

// 存储文件下载长度的文件路径
#define QYTotalLengthPath [QYCachesDirectory stringByAppendingPathComponent:@"totalLength.plist"]

@interface QYDownloadManager()<NSCopying, NSURLSessionDelegate,NSURLSessionDataDelegate>

// 保存所有任务
@property (nonatomic, strong) NSMutableDictionary *taskDict;
//保存所有下载相关信息
@property (nonatomic, strong) NSMutableDictionary *modelDict;
@end


@implementation QYDownloadManager

static QYDownloadManager *_downloadManager;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    return _downloadManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _downloadManager;
}


//创建缓存目录文件
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:QYCachesDirectory]) {
        [fileManager createDirectoryAtPath:QYCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

- (void)download:(NSString *)url progress:(progressBlock)progressBlock success:(successBlock)successBlock faile:(faileBlock)faileBlock
{
    NSLog(@"%@",QYFilePath(url));
    if (!url) return;
    if ([self isCompletion:url]) {
        successBlock(QYFilePath(url));
        return;
    }
    if ([self getTask:url]) {
        
        return;
    }
    [self createCacheDirectory];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:QYFilePath(url) append:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", QYDownloadLength(url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];

    [self.taskDict setObject:task forKey:QYFileName(url)];
    QYDownloadModel *model = [[QYDownloadModel alloc] init];
    model.url = url;
    model.stream = stream;
    model.successBlock = successBlock;
    model.failedBlock = faileBlock;
    model.progressBlock = progressBlock;

    [self.modelDict setValue:model forKey:@(task.taskIdentifier).stringValue];
    
    [self start:url];

}

- (void)handleTask:(NSString *)url {
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:url];
    } else {
        [self start:url];
    }
}

- (void)start:(NSString *)url {
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
}

- (void)pause:(NSString *)url {
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
}

- (NSURLSessionDataTask *)getTask:(NSString *)url {
    return (NSURLSessionDataTask *)[self.taskDict objectForKey:QYFileName(url)];
}


- (QYDownloadModel *)getModel:(NSUInteger)taskIdentifier
{
    return (QYDownloadModel *)[self.modelDict valueForKey:@(taskIdentifier).stringValue];
}

//判断该文件是否下载完成
- (BOOL)isCompletion:(NSString *)url
{
    NSLog(@"总大小：%ld,文件大小：%ld",(long)[self getFileTotalSize:url],QYDownloadLength(url));
    //已下载文件大小、该文件总大小
    if ([self getFileTotalSize:url] && QYDownloadLength(url) == [self getFileTotalSize:url]) {
        return YES;
    }
    return NO;
}

//获取该资源总大小
- (NSInteger)getFileTotalSize:(NSString *)url
{
    return [[NSDictionary dictionaryWithContentsOfFile:QYTotalLengthPath][QYFileName(url)] integerValue];
}

- (void)deleteFile:(NSString *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:QYFilePath(url)]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:QYFilePath(url) error:nil];
        // 删除任务
        NSURLSessionDataTask *task = [self getTask:url];
        QYDownloadModel *model = [self getModel:task.taskIdentifier];
        [model.stream close];
        [self.modelDict removeObjectForKey:@(task.taskIdentifier).stringValue];
        [task cancel];
        [self.taskDict removeObjectForKey:QYFileName(url)];
        // 删除该资源总长度
        if ([fileManager fileExistsAtPath:QYTotalLengthPath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:QYTotalLengthPath];
            [dict removeObjectForKey:QYFileName(url)];
            [dict writeToFile:QYTotalLengthPath atomically:YES];
        }
    }
}

- (void)deleteAllFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:QYCachesDirectory]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:QYCachesDirectory error:nil];
        // 删除任务
        [[self.taskDict allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.taskDict removeAllObjects];
        for (QYDownloadModel *model in [self.modelDict allValues]) {
            [model.stream close];
        }
        [self.modelDict removeAllObjects];
        // 删除该资源总长度
        if ([fileManager fileExistsAtPath:QYTotalLengthPath]) {
            [fileManager removeItemAtPath:QYTotalLengthPath error:nil];
        }
    }
}


#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    QYDownloadModel *model = [self getModel:dataTask.taskIdentifier];
    // 打开流
    [model.stream open];
    
    model.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] +  QYDownloadLength(model.url);
    
    // 把此次已经下载的文件大小存储在plist文件
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile: QYTotalLengthPath];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    dict[ QYFileName(model.url)] = @(model.totalLength);
    [dict writeToFile: QYTotalLengthPath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 2.接收到服务器返回的数据（这个方法可能会被调用N次）
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    QYDownloadModel *model = [self getModel:dataTask.taskIdentifier];
    // 写入数据
    [model.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = QYDownloadLength(model.url);
    NSUInteger expectedSize = model.totalLength;
    float progress = 1.0 *  receivedSize / expectedSize;
    if (model.progressBlock) {
        model.progressBlock(receivedSize, expectedSize, progress);
    }
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    QYDownloadModel *model = [self getModel:task.taskIdentifier];
    if (!model) return;

    if (error) {
        if (model.failedBlock) {
            model.failedBlock(error);
        }
    }else{
        if (model.successBlock) {
            model.successBlock(QYFilePath(model.url));
        }
    }
    [model.stream close];
    model.stream = nil;
    
    [self.taskDict removeObjectForKey:QYFileName(model.url)];
    [self.modelDict removeObjectForKey:@(task.taskIdentifier).stringValue];

}


#pragma mark getter/setter

- (NSMutableDictionary *)taskDict
{
    if (!_taskDict) {
        _taskDict = [[NSMutableDictionary alloc] init];
    }
    return _taskDict;
}

- (NSMutableDictionary *)modelDict
{
    if (!_modelDict) {
        _modelDict = [[NSMutableDictionary alloc] init];
    }
    return _modelDict;
}


@end
