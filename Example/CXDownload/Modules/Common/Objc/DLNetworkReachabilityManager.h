//
//  DLNetworkReachabilityManager.h
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/12.
//  Copyright © 2023 Tenfay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLNetworkReachabilityManager : NSObject

/// Gets the network status
@property (nonatomic, assign, readonly) AFNetworkReachabilityStatus networkReachabilityStatus;

/// Returns a `DLNetworkReachabilityManager` singleton instance.
+ (instancetype)sharedManager;

/// Monitors the network status.
- (void)monitorNetworkStatus;

/// Stop monitoring the network status.
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
