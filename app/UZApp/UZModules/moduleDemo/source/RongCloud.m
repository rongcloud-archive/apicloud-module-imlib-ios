//
//  RongCloudModule.m
//  UZApp
//
//  Created by xugang on 14/12/17.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import "RongCloud.h"
#import "RongCloudModel.h"
#import "RongCloudConstant.h"
#import "RongCloudHandler.h"
#import "UZAppDelegate.h"
#import "UZAppUtils.h"
#import <objc/runtime.h>

#define BAD_PARAMETER_CODE -10002
#define BAD_PARAMETER_MSG @"Argument Exception"

#define NOT_INIT_CODE -10000
#define NOT_INIT_MSG @"Not Init"

#define NOT_CONNECT_CODE -10001
#define NOT_CONNECT_MSG @"Not Connected"

static BOOL isInited = NO;
static BOOL isConnected = NO;

@interface RongCloud ()
{
    NSDictionary *tempDict; // defined this variable just for passing the argument for setConnectedStatusDelegate() method
    
}

@property(nonatomic, strong) RCMessage *sendMessage;

- (BOOL)checkIsInitOrConnect:(id)cbId doDelete:(BOOL)isDelete;
- (NSString *)readRongCloudAppKeyFromConfigXML;
- (void)_sendMessage:(RCConversationType)conversationType withTargetId:(NSString *)targetId withContent:(RCMessageContent *)messageContent withPushContent:(NSString *)pushContent withCallBackId:(NSNumber *)cbId;

@end


@implementation RongCloud

+ (void)launch {
    //在module.json里面配置的launchClassMethod，必须为类方法，引擎会在应用启动时调用配置的方法，模块可以在其中做一些初始化操作
    NSLog(@"%s", __FUNCTION__);
    RongCloudHandler *appHandler = [[RongCloudHandler alloc] init];
    
    [theApp addAppHandle:appHandler];
}


- (id)initWithUZWebView:(UZWebView *)webView_ {
    if (self = [super initWithUZWebView:webView_]) {
        //NSLog(@"%s", __FUNCTION__);
    }
    return self;
}

- (void)dispose {
    //do clean
    //NSLog(@"%s", __FUNCTION__);
}

- (NSString *)readRongCloudAppKeyFromConfigXML
{
    NSString *apiKey = nil;
    NSArray *_features = [theApp features];
    for (NSDictionary* modelUrl in _features) {
        NSArray *keys = [modelUrl allKeys];
        if ([keys containsObject:@"rongCloud"]) {
            NSDictionary *_root = [modelUrl objectForKey:@"rongCloud"];
            NSArray *_root_keys = [_root allKeys];
            if ([_root_keys containsObject:@"appKey"]) {
                apiKey = [_root objectForKey:@"appKey"];
            }
        }
    }
    return apiKey;
}

/**
 * initialize & connection
 */
-(void)init:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
    
        NSString *appKey = [self readRongCloudAppKeyFromConfigXML];
        
        if (![appKey isKindOfClass:[NSString class]]) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
            return;
        }
        
        NSString *_deviceTokenCache = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
        
        [[RCIMClient sharedRCIMClient] init:appKey deviceToken:_deviceTokenCache];
        
        isInited = YES;
        
        NSDictionary *_result = @{@"status":SUCCESS};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}


- (void)connect:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        
        if (NO == isInited) {
            NSDictionary *_result   =   @{@"status": ERROR};
            NSDictionary *_err      =   @{@"code":@(NOT_INIT_CODE), @"msg": NOT_INIT_MSG};
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        self.connectDic = paramDict;
        
        NSString *token = [paramDict objectForKey:@"token"];
        
        if (![token isKindOfClass:[NSString class]]) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
            return;
        }
        //[RCIMClient connect:token delegate:self];
        [[RCIMClient sharedRCIMClient]connectWithToken:token success:^(NSString *userId) {
            NSLog(@"%s", __FUNCTION__);
            
            NSDictionary *paramDict = self.connectDic;
            //self.connected_userId   = userId;
            NSNumber *cbId          = [paramDict objectForKey:@"cbId"];
            
            if (cbId) {
                
                isConnected           = YES;
                NSDictionary *_result = @{@"status": SUCCESS, @"result": @{@"userId":userId}};
                
                [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            }
        } error:^(RCConnectErrorCode status) {
            NSLog(@"%s, errorCode> %ld", __FUNCTION__, status);
            
            NSDictionary *paramDict = self.connectDic;
            
            NSNumber *cbId = [paramDict objectForKey:@"cbId"];
            if (cbId) {
                
                isConnected           = NO;
                NSDictionary *_result = @{@"status": ERROR};
                NSDictionary *_err    = @{@"code":@(status), @"msg": @""};
                
                [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            }
        } tokenIncorrect:^{
//            NSLog(@"%s, tokenIncorrect", __FUNCTION__);
//            
//            NSDictionary *paramDict = self.connectDic;
//            
//            NSNumber *cbId = [paramDict objectForKey:@"cbId"];
//            if (cbId) {
//                
//                isConnected           = NO;
//                NSDictionary *_result = @{@"status": ERROR};
//                NSDictionary *_err    = @{@"code":@(errorCode), @"msg": @""};
//                
//                [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
//            }
        }];
    }
}


- (BOOL)checkIsInitOrConnect:(id)cbId doDelete:(BOOL) isDelete
{
    BOOL isContinue = YES;
    if (cbId) {
        if (NO == isInited) {
            
            NSDictionary *_result = @{@"status": ERROR};
            NSDictionary *_err    = @{@"code":@(NOT_INIT_CODE), @"msg": NOT_INIT_MSG};
            isContinue            = NO;
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:isDelete];
            
        }else if (NO == isConnected)
        {
            NSDictionary *_result = @{@"status": ERROR};
            NSDictionary *_err    = @{@"code":@(NOT_CONNECT_CODE), @"msg": NOT_CONNECT_MSG};
            isContinue            = NO;
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:isDelete];
        }
    }
    return isContinue;
}

- (void)reconnect:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        
        if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]reconnect:^(NSString *userId) {
            //success
            isConnected = YES;
            NSDictionary *_result   =   @{@"status": SUCCESS, @"result": @{@"userId":userId}};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        } error:^(RCConnectErrorCode status) {
            //error
            isConnected           = NO;
            NSDictionary *_result = @{@"status": ERROR};
            NSDictionary *_err    = @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
}

- (void)disconnect:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *isReceivePush = [paramDict objectForKey:@"isReceivePush"];
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    if (cbId) {
        if (NO == isInited) {
            NSDictionary *_result   =   @{@"status": ERROR};
            NSDictionary *_err      =   @{@"code":@(NOT_INIT_CODE), @"msg": NOT_INIT_MSG};
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        if (![isReceivePush isKindOfClass:[NSNumber class]]) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        if (isReceivePush) {
            
            if (1 == isReceivePush.integerValue) {
                [[RCIMClient sharedRCIMClient]disconnect:YES];
            }
            else{
                [[RCIMClient sharedRCIMClient]disconnect:NO];
            }
        }
        else{
            [[RCIMClient sharedRCIMClient]disconnect:YES];
        }
        
        isConnected           = NO;
        NSDictionary *_result = @{@"status": SUCCESS};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}

- (void)setConnectionStatusListener:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    tempDict = paramDict;
    [[RCIMClient sharedRCIMClient]setRCConnectionStatusChangeDelegate:self];
   // [[RCIMClient sharedRCIMClient]setConnectionStatusDelegate:self];
}

- (void)onConnectionStatusChanged:(RCConnectionStatus)status
{
    if (tempDict) {
        NSNumber *cbId = [tempDict objectForKey:@"cbId"];
        if (cbId) {
            
            NSDictionary *_result = @{@"status": SUCCESS, @"result":@{@"code":@(status), @"connectionStatus":@""}};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:NO];
        }
    }
}

- (void)_sendMessage:(RCConversationType)conversationType withTargetId:(NSString *)targetId withContent:(RCMessageContent *)messageContent withPushContent:(NSString *)pushContent withCallBackId:(NSNumber *)cbId
{
    __weak typeof(&*self) blockSelf = self;
    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient]sendMessage:conversationType
                                                            targetId:targetId
                                                             content:messageContent
                                                         pushContent:pushContent
     success:^(long messageId) {
         NSLog(@"%s", __FUNCTION__);
         
         NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
         
         [dic setObject:[NSNumber numberWithLong:messageId] forKey:@"messageId"];
         
         [dic setObject:[NSNumber numberWithBool:YES] forKey:@"isSuccess"];
         
         NSDictionary *_result = @{@"status":SUCCESS, @"result":@{@"message":@{@"messageId":@(messageId)}}};
         [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
     }
       error:^(RCErrorCode nErrorCode, long messageId) {
           
           NSLog(@"%s", __FUNCTION__);
           NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
           
           [dic setObject:[NSNumber numberWithLong:messageId] forKey:@"messageId"];
           
           [dic setObject:[NSNumber numberWithBool:NO] forKey:@"isSuccess"];
           
           NSDictionary *_result = @{@"status":ERROR, @"result":@{@"message": @{@"messageId":@(messageId)}}};
           NSDictionary *_err = @{@"code": @(nErrorCode), @"msg": @""};
           [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];

       }];
    
    NSDictionary *_message = [RongCloudModel RCGenerateMessageModel:rcMessage];
    NSDictionary *_result = @{@"status":PREPARE, @"result": @{@"message":_message}};
    
    [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:NO];
}

/**
 * message send & receive
 */
- (void)sendTextMessage:(NSDictionary *)paramDict
{
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    //self.sendMessageCbId = cbId;
    
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    if (cbId) {
        NSLog(@"%s", __FUNCTION__);
        
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_content                 = [paramDict objectForKey:@"text"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        //NSString *_pushContent             = [paramDict objectForKey:@"pushContent"];

        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_content isKindOfClass:[NSString class]] ||
            ![_extra isKindOfClass:[NSString class]]
        ) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        RCTextMessage *rcTextMessage         = [RCTextMessage messageWithContent:_content];
        rcTextMessage.extra                  = _extra;
        
        [self _sendMessage:_conversationType withTargetId:_targetId withContent:rcTextMessage withPushContent:nil withCallBackId:cbId];
        
    }
}

- (void)sendImageMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId       = [paramDict objectForKey:@"cbId"];
    //self.sendMessageCbId = cbId;
    
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_imagepath               = [paramDict objectForKey:@"imagePath"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_imagepath isKindOfClass:[NSString class]] ||
            ![_extra isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            
            return;
        }
        
        NSString *_truePath = [self getPathWithUZSchemeURL:_imagepath];
        NSLog(@"_truePath > %@", _truePath);
        
        NSData *imageData   = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_truePath]];
        UIImage* image      = [UIImage imageWithData:imageData];
        
        if (![image isKindOfClass:[UIImage class]]) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];

        RCImageMessage *imageMessage         = [RCImageMessage messageWithImage:image];
        imageMessage.extra                   = _extra;
        imageMessage.thumbnailImage          = [UIImage imageWithData:[RongCloudModel compressedImageAndScalingSize:image targetSize:CGSizeMake(360.0f, 360.0f) percent:0.4f]];

        __weak typeof(&*self) blockSelf = self;
        RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendImageMessage:_conversationType
                                                                      targetId:_targetId
                                                                       content:imageMessage
                                                                   pushContent:nil
        progress:^(int progress, long messageId) {
            if (0 == progress) {
                NSDictionary *_result = @{@"status":PROGRESS, @"result": @{@"message":@{@"messageId":@(messageId)}, @"progress":@(0)}};
                
                [blockSelf sendResultEventWithCallbackId:[self.sendMessageCbId intValue] dataDict:_result errDict:nil doDelete:NO];
            }else if (50 == progress)
            {
                NSDictionary *_result = @{@"status":PROGRESS, @"result": @{@"message":@{@"messageId":@(messageId)}, @"progress":@(50)}};
                
                [blockSelf sendResultEventWithCallbackId:[self.sendMessageCbId intValue] dataDict:_result errDict:nil doDelete:NO];
            }else if (100 == progress)
            {
                NSDictionary *_result = @{@"status":PROGRESS, @"result": @{@"message":@{@"messageId":@(messageId)}, @"progress":@(100)}};
                
                [blockSelf sendResultEventWithCallbackId:[self.sendMessageCbId intValue] dataDict:_result errDict:nil doDelete:NO];
            }
        } success:^(long messageId) {
            NSLog(@"%s", __FUNCTION__);
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            
            [dic setObject:[NSNumber numberWithLong:messageId] forKey:@"messageId"];
            
            [dic setObject:[NSNumber numberWithBool:YES] forKey:@"isSuccess"];
            

            NSDictionary *_result = @{@"status":SUCCESS, @"result":@{@"message":@{@"messageId":@(messageId)}}};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];

        } error:^(RCErrorCode errorCode, long messageId) {
            NSLog(@"%s", __FUNCTION__);
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            
            [dic setObject:[NSNumber numberWithLong:messageId] forKey:@"messageId"];
            
            [dic setObject:[NSNumber numberWithBool:NO] forKey:@"isSuccess"];
            
            NSDictionary *_result = @{@"status":ERROR, @"result":@{@"message": @{@"messageId":@(messageId)}}};
            NSDictionary *_err = @{@"code": @(errorCode), @"msg": @""};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];

        }];

        NSDictionary *_message = [RongCloudModel RCGenerateMessageModel:rcMessage];
        NSDictionary *_result = @{@"status":PREPARE, @"result": @{@"message":_message}};
        
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:NO];
    }
}

- (void)sendVoiceMessage:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId       = [paramDict objectForKey:@"cbId"];
    //self.sendMessageCbId = cbId;
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];

        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_voicePath               = [paramDict objectForKey:@"voicePath"];
        NSNumber *_duration                = [paramDict objectForKey:@"duration"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];

        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_voicePath isKindOfClass:[NSString class]] ||
            ![_duration isKindOfClass:[NSNumber class]]||
            ![_extra isKindOfClass:[NSString class]]
        ) {
        
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        NSString *_truePath = [self getPathWithUZSchemeURL:_voicePath];
        NSLog(@"_truePath > %@", _truePath);
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        
        NSData *amrData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_truePath]];
        if (amrData == nil) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        NSData *wavData                = [[RCAMRDataConverter sharedAMRDataConverter]dcodeAMRToWAVE:amrData];
        RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:wavData duration:_duration.intValue];
        rcVoiceMessage.extra           = _extra;
        [self _sendMessage:_conversationType withTargetId:_targetId withContent:rcVoiceMessage withPushContent:nil withCallBackId:cbId];
    }
}

- (void)sendLocationMessage:(NSDictionary*)paramDict
{
    //need to confirm
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    self.sendMessageCbId = cbId;
    
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];

        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_latitude                = [paramDict objectForKey:@"latitude"];
        NSNumber *_longitude               = [paramDict objectForKey:@"longitude"];
        NSString *_locationName            = [paramDict objectForKey:@"poi"];
        NSString *_imagePath               = [paramDict objectForKey:@"imagePath"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_latitude isKindOfClass:[NSNumber class]] ||
            ![_longitude isKindOfClass:[NSNumber class]] ||
            ![_locationName isKindOfClass:[NSString class]] ||
            ![_imagePath isKindOfClass:[NSString class]]||
            ![_extra isKindOfClass:[NSString class]]
        ) {
        
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        NSString *_truePath = [self getPathWithUZSchemeURL:_imagePath];
        NSLog(@"_truePath > %@", _truePath);
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        CLLocationCoordinate2D location;
        location.latitude                    = (CLLocationDegrees)[_latitude doubleValue];
        location.longitude                   = (CLLocationDegrees)[_longitude doubleValue];

        NSData *thumbnailData                = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_truePath]];

        UIImage *thumbnailImage              = [UIImage imageWithData:thumbnailData];
        
        RCLocationMessage *locationMessage = [RCLocationMessage messageWithLocationImage:thumbnailImage location:location locationName:_locationName];
        locationMessage.extra              = _extra;
        [self _sendMessage:_conversationType withTargetId:_targetId withContent:locationMessage withPushContent:nil withCallBackId:cbId];
    }
}

- (void)sendRichContentMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    self.sendMessageCbId = cbId;
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];

        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_tiltle                  = [paramDict objectForKey:@"title"];
        NSString *_content                 = [paramDict objectForKey:@"description"];
        NSString *_imageUrl                = [paramDict objectForKey:@"imageUrl" ];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];

        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_tiltle isKindOfClass:[NSString class]] ||
            ![_content isKindOfClass:[NSString class]] ||
            ![_imageUrl isKindOfClass:[NSString class]] ||
            ![_extra isKindOfClass:[NSString class]]
        ) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        
        if (nil == _extra) {
            _extra = @"";
        }
        RCRichContentMessage  * rcRichMessage = [RCRichContentMessage messageWithTitle:_tiltle
                                                                                digest:_content
                                                                              imageURL:_imageUrl
                                                                                 extra:_extra];
        
        [self _sendMessage:_conversationType withTargetId:_targetId withContent:rcRichMessage withPushContent:nil withCallBackId:cbId];
    }
}
-(void)sendCommandNotificationMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    self.sendMessageCbId = cbId;
    if (![self checkIsInitOrConnect:cbId doDelete:NO]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_name                    = [paramDict objectForKey:@"name"];
        NSString *_data                    = [paramDict objectForKey:@"data"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_name isKindOfClass:[NSString class]] ||
            ![_data isKindOfClass:[NSString class]]
        ) {
        
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:NO];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        RCCommandNotificationMessage *msg    = [RCCommandNotificationMessage notificationWithName:_name data:_data];
        [self _sendMessage:_conversationType withTargetId:_targetId withContent:msg withPushContent:nil withCallBackId:cbId];
    }
}

- (void)setOnReceiveMessageListener:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    self.receiveMessageCbId = cbId;
    
    [[RCIMClient sharedRCIMClient]setReceiveMessageDelegate:self object:nil];
}

- (void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object
{
    NSLog(@"%s, isMainThread > %d", __FUNCTION__, [NSThread isMainThread]);

    if (self.receiveMessageCbId) {
        NSDictionary *_message = [RongCloudModel RCGenerateMessageModel:message];
        NSDictionary *_result = @{@"status":SUCCESS, @"result": @{@"message":_message, @"left":@(nLeft)}};

        [self sendResultEventWithCallbackId:[self.receiveMessageCbId intValue] dataDict:_result errDict:nil doDelete:NO];
    }
    
    /**
     *  Add Local Notification Event
     */
    NSNumber *nAppbackgroundMode = [[NSUserDefaults standardUserDefaults]objectForKey:kAppBackgroundMode];
    BOOL _bAppBackgroundMode = [nAppbackgroundMode boolValue];
    if (YES == _bAppBackgroundMode && 0 == nLeft) {
        //post local notification
        [[RCIMClient sharedRCIMClient]getConversationNotificationStatus:message.conversationType targetId:message.targetId success:^(RCConversationNotificationStatus nStatus) {
            if (NOTIFY == nStatus) {
                NSString *_notificationMessae = @"您收到了一条新消息";
                
                [RongCloudModel postLocalNotification:_notificationMessae];

            }
        } error:^(RCErrorCode status) {
            NSLog(@"notification error code= %d",(int)status);
        }];
    }
}

/**
 * conversation
 */
- (void)getConversationList:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSArray *typeList                       = [[NSArray alloc]initWithObjects:[NSNumber numberWithInt:ConversationType_PRIVATE],
                                                        [NSNumber numberWithInt:ConversationType_DISCUSSION],
                                                        [NSNumber numberWithInt:ConversationType_GROUP],
                                                        [NSNumber numberWithInt:ConversationType_SYSTEM],nil];

        NSArray *_conversationList              = [[RCIMClient sharedRCIMClient]getConversationList:typeList];

        NSMutableArray * _conversationListModel = nil;
        _conversationListModel                  = [RongCloudModel RCGenerateConversationListModel:_conversationList];

        NSDictionary *_result                   = @{@"status":SUCCESS, @"result": _conversationListModel};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}

- (void)getConversation:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        RCConversation *_rcConversion        = [[RCIMClient sharedRCIMClient]getConversation:_conversationType targetId:_targetId];
        NSDictionary *_ret                   = nil;
        _ret                                 = [RongCloudModel RCGenerateConversationModel:_rcConversion];

        NSDictionary *_result = @{@"status":SUCCESS, @"result": _ret};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}

- (void)removeConversation:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        
        BOOL isRemoved = [[RCIMClient sharedRCIMClient] removeConversation:_conversationType targetId:_targetId];
        if(isRemoved)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}

- (void)clearConversations: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    
    if (cbId) {
        NSArray *__conversationTypes = [paramDict objectForKey:@"conversationTypes"];
        if (![__conversationTypes isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        if (nil != __conversationTypes && [__conversationTypes count] > 0) {
            
            NSUInteger _count      = [__conversationTypes count];
            NSMutableArray *argums = [[NSMutableArray alloc] init];
            for (NSUInteger i=0; i< _count; i++) {
                RCConversationType _type = [RongCloudModel RCTransferConversationType:[__conversationTypes objectAtIndex:i]];
                [argums addObject:@(_type)];
            }
            
            BOOL __ret =[[RCIMClient sharedRCIMClient]clearConversations:argums];
            
            if(__ret)
            {
                NSDictionary *_result = @{@"status":SUCCESS};
                [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            }else{
                NSDictionary *_result = @{@"status":ERROR};
                [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            }
            
        }
    }
}

- (void)setConversationToTop:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber * _isTop                  = [paramDict objectForKey:@"isTop"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_isTop isKindOfClass:[NSNumber class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL isSetted = [[RCIMClient sharedRCIMClient] setConversationToTop:_conversationType targetId:_targetId isTop:[_isTop boolValue]];
        if(isSetted)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}

/**
 * conversation notification
 */
- (void)getConversationNotificationStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];

        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err    = @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]getConversationNotificationStatus:_conversationType targetId:_targetId success:^(RCConversationNotificationStatus nStatus) {
            NSDictionary *_result = @{@"status":SUCCESS, @"result":@{@"code": @(nStatus), @"notificationStatus": @""}};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        } error:^(RCErrorCode status) {
            NSLog(@"notification error code= %d",(int)status);
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err = @{@"code": @(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
    
}
- (void)setConversationNotificationStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString        = [paramDict objectForKey:@"conversationType"];

        NSString *_targetId                       = [paramDict objectForKey:@"targetId"];
        NSString *_conversationnotificationStatus = [paramDict objectForKey:@"notificationStatus"];
        
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_conversationnotificationStatus isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL _isBlocked = NO;
        if ([_conversationnotificationStatus isEqualToString:@"DO_NOT_DISTURB"]) {
            _isBlocked = YES;
        }
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]setConversationNotificationStatus:_conversationType targetId:_targetId isBlocked:_isBlocked success:^(RCConversationNotificationStatus nStatus) {
            
            NSDictionary *_result = @{@"status":SUCCESS, @"result":@{@"code": @(nStatus), @"notificationStatus": @""}};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            NSDictionary *_result   =   @{@"status":ERROR};
            NSDictionary *_err      =   @{@"code": @(status), @"status": @""};

            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
}

/**
 * read message & delete
 */
- (void)getLatestMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_count                   = [paramDict objectForKey:@"count"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_count isKindOfClass:[NSNumber class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType     = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        NSArray *_latestMessages                 = [[RCIMClient sharedRCIMClient]getLatestMessages:_conversationType targetId:_targetId count:[_count intValue]];
        NSMutableArray * _latestMessageListModel = nil;

        _latestMessageListModel                  = [RongCloudModel RCGenerateMessageListModel:_latestMessages];
        
        NSDictionary *_result = @{@"status":SUCCESS, @"result": _latestMessageListModel};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}

- (void)getHistoryMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSNumber *_count                   = [paramDict objectForKey:@"count"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_oldestMessageId         = [paramDict objectForKey:@"oldestMessageId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_count isKindOfClass:[NSNumber class]] ||
            ![_oldestMessageId isKindOfClass:[NSNumber class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType      = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        NSArray *_historyMessages                 = [[RCIMClient sharedRCIMClient] getHistoryMessages:_conversationType targetId:_targetId oldestMessageId:[_oldestMessageId longValue] count:[_count intValue]];
        NSMutableArray * _historyMessageListModel = nil;

        _historyMessageListModel                  = [RongCloudModel RCGenerateMessageListModel:_historyMessages];
        
        NSDictionary *_result = @{@"status":SUCCESS, @"result": _historyMessageListModel};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}
- (void)getHistoryMessagesByObjectName:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        //need to confirm
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];

        NSNumber *_count                   = [paramDict objectForKey:@"count"];

        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_oldestMessageId         = [paramDict objectForKey:@"oldestMessageId"];
        NSString *_objectName              = [paramDict objectForKey:@"objectName"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_count isKindOfClass:[NSNumber class]] ||
            ![_oldestMessageId isKindOfClass:[NSNumber class]] ||
            ![_objectName isKindOfClass:[NSString class]]
        ) {
        
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        RCConversationType _conversationType      = [RongCloudModel RCTransferConversationType:_conversationTypeString];
       
        NSArray *_historyMessages = [[RCIMClient sharedRCIMClient]getHistoryMessages:_conversationType targetId:_targetId oldestMessageId:[_oldestMessageId longValue] count:[_count intValue]];
        NSMutableArray * _historyMessageListModel = nil;
        
        _historyMessageListModel = [RongCloudModel RCGenerateMessageListModel:_historyMessages];
        
        NSDictionary *_result = @{@"status":SUCCESS, @"result": _historyMessageListModel};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}
- (void) deleteMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSArray *_messageIds = [paramDict objectForKey:@"messageIds"];
        
        if (![_messageIds isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        BOOL isDeleted = [[RCIMClient sharedRCIMClient]deleteMessages:_messageIds];
        if(isDeleted)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}
- (void) clearMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL isCleared = [[RCIMClient sharedRCIMClient]clearMessages:_conversationType targetId:_targetId];
        if(isCleared)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}

/**
 * unread message count
 */
- (void) getTotalUnreadCount:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        int totalUnReadCount = (int)[[RCIMClient sharedRCIMClient]getTotalUnreadCount];
        
        NSDictionary *_result = @{@"status":SUCCESS, @"result": @(totalUnReadCount)};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}

- (void) getUnreadCount:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        NSInteger unReadCount = [[RCIMClient sharedRCIMClient]getUnreadCount:_conversationType targetId:_targetId];
        NSDictionary *_result = @{@"status":SUCCESS, @"result": @(unReadCount)};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
}
-(void)getUnreadCountByConversationTypes:(NSDictionary *)paramDict
{
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSArray *nsstring_conversationTypes = [paramDict objectForKey:@"conversationTypes"];
        
        if (![nsstring_conversationTypes isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        NSMutableArray * _conversationTypes = [NSMutableArray new];
        for(int i=0; i< [nsstring_conversationTypes count]; i++)
        {
            RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:nsstring_conversationTypes[i]];
            [_conversationTypes addObject:@(_conversationType)];
        }
        
        NSInteger _unread_count = [[RCIMClient sharedRCIMClient]getUnreadCount:_conversationTypes];
        
        
        NSDictionary *_result = @{@"status":SUCCESS, @"result": @(_unread_count)};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
    
}

/**
 * message status
 */
-(void) setMessageReceivedStatus: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSNumber *__messageId =[paramDict objectForKey:@"messageId"];
        NSNumber *__receivedStatus = [paramDict objectForKey:@"receivedStatus"];
        
        if (![__messageId isKindOfClass:[NSNumber class]] ||
            ![__receivedStatus isKindOfClass:[NSNumber class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        BOOL __ret = [[RCIMClient sharedRCIMClient]setMessageReceivedStatus:__messageId.intValue
                                                                 receivedStatus:__receivedStatus.intValue];
       if(__ret)
       {
           NSDictionary *_result = @{@"status":SUCCESS};
           [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
       }else{
           NSDictionary *_result = @{@"status":ERROR};
           [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
       }
    }
}

- (void) clearMessagesUnreadStatus: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL __ret = [[RCIMClient sharedRCIMClient]clearMessagesUnreadStatus:_conversationType targetId:_targetId];
        if(__ret)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
    
}
-(void) setMessageExtra : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSNumber *__messageId =[paramDict objectForKey:@"messageId"];
        NSString *__value = [paramDict objectForKey:@"value"];
        
        if (![__messageId isKindOfClass:[NSNumber class]] ||
            ![__value isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        BOOL __ret = [[RCIMClient sharedRCIMClient]setMessageExtra:__messageId.longValue value:__value];
        if(__ret)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}

/**
 * message draft
 */
-(void) getTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        NSString *__draft = [[RCIMClient sharedRCIMClient]getTextMessageDraft:_conversationType targetId:_targetId];
        if (nil == __draft) {
            __draft = @"";
        }
        NSDictionary *_result = @{@"status":SUCCESS, @"result": __draft};
        [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
    }
    
}
-(void) saveTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        NSString *_content =  [paramDict objectForKey:@"content"];
        
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]] ||
            ![_content isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL __ret = [[RCIMClient sharedRCIMClient] saveTextMessageDraft:_conversationType
                                                                targetId:_targetId
                                                                 content:_content];
        if(__ret)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}
-(void)clearTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        if (![_conversationTypeString isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        RCConversationType _conversationType = [RongCloudModel RCTransferConversationType:_conversationTypeString];
        BOOL __ret = [[RCIMClient sharedRCIMClient] clearTextMessageDraft:_conversationType targetId:_targetId];
        if(__ret)
        {
            NSDictionary *_result = @{@"status":SUCCESS};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }else{
            NSDictionary *_result = @{@"status":ERROR};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }
    }
}

/**
 * discussion
 */
- (void) createDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_name = [paramDict objectForKey:@"name"];
        NSArray *_userIds = [paramDict objectForKey:@"userIdList"];
        
        if (![_name isKindOfClass:[NSString class]] ||
            ![_userIds isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        __weak typeof(&*self) blockSelf = self;
        
        [[RCIMClient sharedRCIMClient]createDiscussion:_name userIdList:_userIds success:^(RCDiscussion *discussion) {
            NSDictionary *_result = @{@"status":SUCCESS, @"result": @{@"discussionId": discussion.discussionId}};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        } error:^(RCErrorCode status) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
        
    }
}

-(void)getDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *__discussionId = [paramDict objectForKey:@"discussionId"];
        if (![__discussionId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockself = self;
        [[RCIMClient sharedRCIMClient]getDiscussion:__discussionId success:^(RCDiscussion *discussion) {
            NSDictionary *_dic = [RongCloudModel RCGenerateDiscussionModel:discussion];
            NSDictionary *_result = @{@"status":SUCCESS, @"result": _dic};
            [blockself sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        } error:^(RCErrorCode status) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            [blockself sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
}

-(void)setDiscussionName :(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *__discussionId = [paramDict objectForKey:@"discussionId"];
        NSString *__name = [paramDict objectForKey:@"name"];
        if (![__discussionId isKindOfClass:[NSString class]] ||
            ![__name isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        __weak typeof(&*self) blockself = self;
        
        [[RCIMClient sharedRCIMClient]setDiscussionName:__discussionId name:__name success:^{
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockself sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        } error:^(RCErrorCode status) {
            NSDictionary *_result = @{@"status":ERROR};
            [blockself sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
        }];
    }
}

- (void) addMemberToDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        NSArray *_userIds = [paramDict objectForKey:@"userIdList"];
        if (![_discussionId isKindOfClass:[NSString class]] ||
            ![_userIds isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient] addMemberToDiscussion:_discussionId userIdList:_userIds success:^(RCDiscussion *discussion){
        
            NSDictionary *_result = @{@"status":SUCCESS};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}
- (void) removeMemberFromDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        NSString *_userIds = [paramDict objectForKey:@"userId"];
        if (![_discussionId isKindOfClass:[NSString class]] ||
            ![_userIds isKindOfClass:[NSString class]]
        ) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient] removeMemberFromDiscussion:_discussionId userId:_userIds success:^(RCDiscussion *discussion) {

            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}
- (void) quitDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        if (![_discussionId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient] quitGroup:_discussionId success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
        
    }
}
- (void) setDiscussionInviteStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_targetId = [paramDict objectForKey:@"discussionId"];
        NSString *_discussionInviteStatus = [paramDict objectForKey:@"inviteStatus"];
        
        if (![_discussionInviteStatus isKindOfClass:[NSString class]] ||
            ![_targetId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        BOOL _isOpen = YES;
        
        if ([_discussionInviteStatus isEqualToString:@"CLOSED"]) {
            _isOpen = NO;
        }
        __weak typeof(&*self) blockSelf = self;
        
        [[RCIMClient sharedRCIMClient]setDiscussionInviteStatus:_targetId isOpen:_isOpen success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}

/**
 * group
 */
- (void) syncGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSArray *_groups = [paramDict objectForKey:@"groups"];
        
        if (![_groups isKindOfClass:[NSArray class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        NSMutableArray *_groupList = [RongCloudModel RCGenerateGroupList:_groups];
        
        if (nil == _groupList) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]syncGroups:_groupList success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}
- (void) joinGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_groupId      = [paramDict objectForKey:@"groupId"];
        NSString *_groupName    = [paramDict objectForKey:@"groupName"];
        if (![_groupId isKindOfClass:[NSString class]] ||
            ![_groupName isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]joinGroup:_groupId groupName:_groupName success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}
- (void) quitGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_groupId = [paramDict objectForKey:@"groupId"];
        if (![_groupId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        
        [[RCIMClient sharedRCIMClient]quitGroup:_groupId success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
}

/**
 * chatRoom
 */
- (void)joinChatRoom:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_chatRoomId       = [paramDict objectForKey:@"chatRoomId"];
        NSNumber *_defMessageCount  = [paramDict objectForKey:@"defMessageCount"];
        if (![_chatRoomId isKindOfClass:[NSString class]] ||
            ![_defMessageCount isKindOfClass:[NSNumber class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        [[RCIMClient sharedRCIMClient]joinChatRoom:_chatRoomId messageCount:[_defMessageCount intValue] success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            
        }];
    }
}
- (void)quitChatRoom:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (![self checkIsInitOrConnect:cbId doDelete:YES]) {
        return;
    }
    if (cbId) {
        NSString *_chatRoomId = [paramDict objectForKey:@"chatRoomId"];
        if (![_chatRoomId isKindOfClass:[NSString class]]
        ) {
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(BAD_PARAMETER_CODE), @"msg": BAD_PARAMETER_MSG};
            [self sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
            return;
        }
        __weak typeof(&*self) blockSelf = self;
        
        [[RCIMClient sharedRCIMClient]quitChatRoom:_chatRoomId success:^{
            
            NSDictionary *_result = @{@"status":SUCCESS};
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:nil doDelete:YES];
            
        } error:^(RCErrorCode status) {
            
            NSDictionary *_result = @{@"status":ERROR};
            NSDictionary *_err =  @{@"code":@(status), @"msg": @""};
            
            [blockSelf sendResultEventWithCallbackId:[cbId intValue] dataDict:_result errDict:_err doDelete:YES];
        }];
    }
}
@end
