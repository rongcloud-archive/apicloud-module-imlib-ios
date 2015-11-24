//
//  RongCloudModule.h
//  UZApp
//
//  Created by xugang on 14/12/17.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import "UZModule.h"
#import <RongIMLib/RongIMLib.h>
#import "RongCloudHybridAdapter.h"

@interface RongCloud : UZModule<RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate>

@end
