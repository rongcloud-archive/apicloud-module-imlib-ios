//
//  RongCloudModule.h
//  UZApp
//
//  Created by xugang on 14/12/17.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import "UZModule.h"
#import <RongIMLib/RongIMLib.h>


@interface RongCloud : UZModule<RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate>

//用于连接存储字典
@property (nonatomic,strong) NSDictionary* connectDic;

//xugang
@property (nonatomic,strong) NSNumber *sendMessageCbId;
@property (nonatomic,strong) NSNumber *receiveMessageCbId;

@end
