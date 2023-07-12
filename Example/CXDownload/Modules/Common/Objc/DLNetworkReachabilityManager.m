//
//  DLNetworkReachabilityManager.m
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/12.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

#import "DLNetworkReachabilityManager.h"
#import "CXDownload_Example-Swift.h"
@import CXDownload;

@interface DLNetworkReachabilityManager ()

@property (nonatomic, assign, readwrite) AFNetworkReachabilityStatus networkReachabilityStatus;

@end

@implementation DLNetworkReachabilityManager

+ (instancetype)sharedManager
{
    static DLNetworkReachabilityManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (void)monitorNetworkStatus
{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        /// Networking reachability change notification. Please send the specified string(**"Reachable", "NotReachable", "ReachableViaWWAN" or "ReachableViaWiFi"**) by notification.object.
        NSString *statusString = @"Reachable";
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                // 未知网络
                NSLog(@"当前网络：未知网络");
                statusString = @"Reachable";
                break;
            case AFNetworkReachabilityStatusNotReachable:
                // 无网络
                NSLog(@"当前网络：无网络");
                statusString = @"NotReachable";
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                // 蜂窝数据
                NSLog(@"当前网络：蜂窝数据");
                statusString = @"ReachableViaWWAN";
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                // 无线网络
                NSLog(@"当前网络：无线网络");
                statusString = @"ReachableViaWiFi";
                break;
            default:
                break;
        }
        
        if (_networkReachabilityStatus != status) {
            _networkReachabilityStatus = status;
            [[NSNotificationCenter defaultCenter] postNotificationName:CXDownloadConfig.networkingReachabilityDidChangeNotification object:statusString];
        }
    }];
    
    // 开始监听
    [manager startMonitoring];
}

@end
