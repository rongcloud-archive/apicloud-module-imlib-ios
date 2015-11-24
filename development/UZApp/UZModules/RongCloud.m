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

@interface RongCloud ()<RongCloud2HybridDelegation>
@property (nonatomic, strong)RongCloudHybridAdapter *rongCloudAdapter;
@end


@implementation RongCloud

#pragma mark private methods
- (RongCloudHybridAdapter *)rongCloudAdapter {
    if (!_rongCloudAdapter) {
        _rongCloudAdapter = [[RongCloudHybridAdapter alloc] initWithDelegate:self];
    }
    return _rongCloudAdapter;
}
- (void)sendResult:(NSDictionary *)resultDict error:(NSDictionary *)errorDict withCallbackId:(id)callbackId doDelete:(BOOL)doDelete {
    [self sendResultEventWithCallbackId:[callbackId intValue] dataDict:resultDict errDict:errorDict doDelete:doDelete];
}
- (NSString *)getAbsolutePath:(NSString *)relativePath {
    return [self getPathWithUZSchemeURL:relativePath];;
}

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
        if ([keys containsObject:@"rongCloud2"]) {
            NSDictionary *_root = [modelUrl objectForKey:@"rongCloud2"];
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
        
        if (cbId) {
            [self.rongCloudAdapter init:appKey callbackId:cbId];
        }
    }
}


- (void)connect:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *token = [paramDict objectForKey:@"token"];
        [self.rongCloudAdapter connectWithToken:token callbackId:cbId];
    }
}


- (void)disconnect:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *isReceivePush = [paramDict objectForKey:@"isReceivePush"];
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    if (cbId) {
        [self.rongCloudAdapter disconnect:isReceivePush callbackId:cbId];
    }
}

- (void)setConnectionStatusListener:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    if (cbId) {
        [self.rongCloudAdapter setConnectionStatusListener:cbId];
    }
}

- (void)onConnectionStatusChanged:(RCConnectionStatus)status {
    [self.rongCloudAdapter onConnectionStatusChanged:status];
}


/**
 * message send & receive
 */
- (void)sendTextMessage:(NSDictionary *)paramDict
{
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];

    if (cbId) {
        NSLog(@"%s", __FUNCTION__);
        
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_content                 = [paramDict objectForKey:@"text"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        //NSString *_pushContent             = [paramDict objectForKey:@"pushContent"];
        if (!_extra) {
            _extra = @"";
        }
        [self.rongCloudAdapter sendTextMessage:_conversationTypeString targetId:_targetId content:_content extra:_extra callbackId:cbId];
        
    }
}

- (void)sendImageMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId       = [paramDict objectForKey:@"cbId"];

    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_imagepath               = [paramDict objectForKey:@"imagePath"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        if (!_extra) {
            _extra = @"";
        }
        [self.rongCloudAdapter sendImageMessage:_conversationTypeString targetId:_targetId imagePath:_imagepath extra:_extra callbackId:cbId];
    }
}

- (void)sendVoiceMessage:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId       = [paramDict objectForKey:@"cbId"];

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_voicePath               = [paramDict objectForKey:@"voicePath"];
        NSNumber *_duration                = [paramDict objectForKey:@"duration"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        if (!_extra) {
            _extra = @"";
        }

        [self.rongCloudAdapter sendVoiceMessage:_conversationTypeString targetId:_targetId voicePath:_voicePath duration:_duration extra:_extra callbackId:cbId];
    }
}

- (void)sendLocationMessage:(NSDictionary*)paramDict
{
    //need to confirm
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
 
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_latitude                = [paramDict objectForKey:@"latitude"];
        NSNumber *_longitude               = [paramDict objectForKey:@"longitude"];
        NSString *_locationName            = [paramDict objectForKey:@"poi"];
        NSString *_imagePath               = [paramDict objectForKey:@"imagePath"];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        if (!_extra) {
            _extra = @"";
        }
        [self.rongCloudAdapter sendLocationMessage:_conversationTypeString targetId:_targetId imagePath:_imagePath latitude:_latitude longitude:_longitude locationName:_locationName extra:_extra callbackId:cbId];
    }
}

- (void)sendRichContentMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
 
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_tiltle                  = [paramDict objectForKey:@"title"];
        NSString *_content                 = [paramDict objectForKey:@"description"];
        NSString *_imageUrl                = [paramDict objectForKey:@"imageUrl" ];
        NSString *_extra                   = [paramDict objectForKey:@"extra"];
        if (!_extra) {
            _extra = @"";
        }
        [self.rongCloudAdapter sendRichContentMessage:_conversationTypeString targetId:_targetId title:_tiltle content:_content imageUrl:_imageUrl extra:_extra callbackId:cbId];
    }
}
-(void)sendCommandNotificationMessage : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSString *_name                    = [paramDict objectForKey:@"name"];
        NSString *_data                    = [paramDict objectForKey:@"data"];
        
        [self.rongCloudAdapter sendCommandNotificationMessage:_conversationTypeString targetId:_targetId name:_name data:_data callbackId:cbId];
    }
}

- (void)setOnReceiveMessageListener:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    if (cbId) {
        [self.rongCloudAdapter setOnReceiveMessageListener:cbId];
    }
}


- (void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object {
    [self.rongCloudAdapter onReceived:message left:nLeft object:object];
}

/**
 * conversation
 */
- (void)getConversationList:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        [self.rongCloudAdapter getConversationList:cbId];
    }
}

- (void)getConversation:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter getConversation:_conversationTypeString targetId:_targetId callbackId:cbId];
    }
}

- (void)removeConversation:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter removeConversation:_conversationTypeString targetId:_targetId callbackId:cbId];
    }
}

- (void)clearConversations: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    
    if (cbId) {
        NSArray *__conversationTypes = [paramDict objectForKey:@"conversationTypes"];
        [self.rongCloudAdapter clearConversations:__conversationTypes callbackId:cbId];
    }
}

- (void)setConversationToTop:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber * _isTop                  = [paramDict objectForKey:@"isTop"];
    
        [self.rongCloudAdapter setConversationToTop:_conversationTypeString targetId:_targetId isTop:_isTop callbackId:cbId];
    }
}

/**
 * conversation notification
 */
- (void)getConversationNotificationStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
    
        [self.rongCloudAdapter getConversationNotificationStatus:_conversationTypeString targetId:_targetId callbackId:cbId];
    }
    
}
- (void)setConversationNotificationStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
 
    if (cbId) {
        NSString * _conversationTypeString        = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId                       = [paramDict objectForKey:@"targetId"];
        NSString *_conversationnotificationStatus = [paramDict objectForKey:@"notificationStatus"];
        
    
        [self.rongCloudAdapter setConversationNotificationStatus:_conversationTypeString targetId:_targetId conversationnotificationStatus:_conversationnotificationStatus callbackId:cbId];
    }
}

/**
 * read message & delete
 */
- (void)getLatestMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_count                   = [paramDict objectForKey:@"count"];
        
       
        [self.rongCloudAdapter getLatestMessages:_conversationTypeString targetId:_targetId count:_count callbackId:cbId];
    }
}

- (void)getHistoryMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSNumber *_count                   = [paramDict objectForKey:@"count"];
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_oldestMessageId         = [paramDict objectForKey:@"oldestMessageId"];
        
       
        [self.rongCloudAdapter getHistoryMessages:_conversationTypeString targetId:_targetId count:_count oldestMessageId:_oldestMessageId callbackId:cbId];
    }
}
- (void)getHistoryMessagesByObjectName:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        //need to confirm
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSNumber *_count                   = [paramDict objectForKey:@"count"];
        
        NSString *_targetId                = [paramDict objectForKey:@"targetId"];
        NSNumber *_oldestMessageId         = [paramDict objectForKey:@"oldestMessageId"];
        NSString *_objectName              = [paramDict objectForKey:@"objectName"];
        
   
        [self.rongCloudAdapter getHistoryMessagesByObjectName:_conversationTypeString targetId:_targetId count:_count oldestMessageId:_oldestMessageId objectName:_objectName callbackId:cbId];
    }
}
- (void) deleteMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSArray *_messageIds = [paramDict objectForKey:@"messageIds"];
        
    
        [self.rongCloudAdapter deleteMessages:_messageIds callbackId:cbId];
    }
}
- (void) clearMessages:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter clearMessages:_conversationTypeString targetId:_targetId callbackId:cbId];
    }
}

/**
 * unread message count
 */
- (void) getTotalUnreadCount:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
 
    if (cbId) {
        [self.rongCloudAdapter getTotalUnreadCount:cbId];
    }
}

- (void) getUnreadCount:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter getUnreadCount:_conversationTypeString targetId:_targetId callbackId:cbId];
    }
}
-(void)getUnreadCountByConversationTypes:(NSDictionary *)paramDict
{
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSArray *nsstring_conversationTypes = [paramDict objectForKey:@"conversationTypes"];
        [self.rongCloudAdapter getUnreadCountByConversationTypes:nsstring_conversationTypes callbackId:cbId];
    }
    
}

/**
 * message status
 */
-(void) setMessageReceivedStatus: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSNumber *__messageId =[paramDict objectForKey:@"messageId"];
        NSString *__receivedStatus = [paramDict objectForKey:@"receivedStatus"];
        
        [self.rongCloudAdapter setMessageSentStatus:__messageId sentStatus:__receivedStatus withCallBackId:cbId];
    }
}

- (void) clearMessagesUnreadStatus: (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter clearMessagesUnreadStatus:_conversationTypeString withTargetId:_targetId withCallBackId:cbId];
    }
    
}
-(void) setMessageExtra : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSNumber *__messageId =[paramDict objectForKey:@"messageId"];
        NSString *__value = [paramDict objectForKey:@"value"];
        
        [self.rongCloudAdapter  setMessageExtra:__messageId withValue:__value withCallBackId:cbId];
    }
}

/**
 * message draft
 */
-(void) getTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        
        [self.rongCloudAdapter getTextMessageDraft:_conversationTypeString withTargetId:_targetId withCallBackId:cbId];
    }
    
}
-(void) saveTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        NSString *_content =  [paramDict objectForKey:@"content"];
        
        
        [self.rongCloudAdapter saveTextMessageDraft:_conversationTypeString withTargetId:_targetId withContent:_content withCallBackId:cbId];
    }
}
-(void)clearTextMessageDraft : (NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        [self.rongCloudAdapter clearTextMessageDraft:_conversationTypeString withTargetId:_targetId withCallBackId:cbId];
    }
}

/**
 * discussion
 */
- (void) createDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_name = [paramDict objectForKey:@"name"];
        NSArray *_userIds = [paramDict objectForKey:@"userIdList"];
        
        [self.rongCloudAdapter createDiscussion:_name withUserIdList:_userIds withCallBackId:cbId];
    }
}

-(void)getDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *__discussionId = [paramDict objectForKey:@"discussionId"];
        [self.rongCloudAdapter getDiscussion:__discussionId withCallBackId:cbId];
    }
}

-(void)setDiscussionName :(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *__discussionId = [paramDict objectForKey:@"discussionId"];
        NSString *__name = [paramDict objectForKey:@"name"];
        [self.rongCloudAdapter setDiscussionName:__discussionId withName:__name withCallBackId:cbId];
    }
}

- (void) addMemberToDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        NSArray *_userIds = [paramDict objectForKey:@"userIdList"];
        [self.rongCloudAdapter  addMemberToDiscussion:_discussionId withUserIdList:_userIds withCallBackId:cbId];
    }
}
- (void) removeMemberFromDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        NSString *_userIds = [paramDict objectForKey:@"userId"];
        [self.rongCloudAdapter  removeMemberFromDiscussion:_discussionId withUserIds:_userIds withCallBackId:cbId];
    }
}
- (void) quitDiscussion:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_discussionId = [paramDict objectForKey:@"discussionId"];
        [self.rongCloudAdapter quitDiscussion:_discussionId withCallBackId:cbId];
    }
}
- (void) setDiscussionInviteStatus:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_targetId = [paramDict objectForKey:@"discussionId"];
        NSString *_discussionInviteStatus = [paramDict objectForKey:@"inviteStatus"];
        
        [self.rongCloudAdapter setDiscussionInviteStatus:_targetId withInviteStatus:_discussionInviteStatus withCallBackId:cbId];
    }
}

/**
 * group
 */
- (void) syncGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSArray *_groups = [paramDict objectForKey:@"groups"];
        
        [self.rongCloudAdapter syncGroup:_groups withCallBackId:cbId];
    }
}
- (void) joinGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_groupId      = [paramDict objectForKey:@"groupId"];
        NSString *_groupName    = [paramDict objectForKey:@"groupName"];
        [self.rongCloudAdapter joinGroup:_groupId withGroupName:_groupName withCallBackId:cbId];
    }
}
- (void) quitGroup:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_groupId = [paramDict objectForKey:@"groupId"];
        
        [self.rongCloudAdapter quitGroup:_groupId withCallBackId:cbId];
    }
}

/**
 * chatRoom
 */
- (void)joinChatRoom:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_chatRoomId       = [paramDict objectForKey:@"chatRoomId"];
        NSNumber *_defMessageCount  = [paramDict objectForKey:@"defMessageCount"];
        [self.rongCloudAdapter joinChatRoom:_chatRoomId messageCount:_defMessageCount withCallBackId:cbId];
    }
}
- (void)quitChatRoom:(NSDictionary *)paramDict
{
    NSLog(@"%s", __FUNCTION__);
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    

    if (cbId) {
        NSString *_chatRoomId = [paramDict objectForKey:@"chatRoomId"];
        [self.rongCloudAdapter  quitChatRoom:_chatRoomId withCallBackId:cbId];
    }
}
- (void)getConnectionStatus:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        [self.rongCloudAdapter getConnectionStatus:cbId];
    }
}

- (void)logout:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    if (cbId) {
        [self.rongCloudAdapter  logout:cbId];
    }
}

- (void)getRemoteHistoryMessages:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString * _conversationTypeString = [paramDict objectForKey:@"conversationType"];
        NSString *_targetId = [paramDict objectForKey:@"targetId"];
        NSNumber *_dateTime = [paramDict objectForKey:@"dateTime"];
        NSNumber *_count = [paramDict objectForKey:@"count"];
        [self.rongCloudAdapter getRemoteHistoryMessages:_conversationTypeString targetId:_targetId recordTime:_dateTime count:_count withCallBackId:cbId];
    }
}
- (void)setMessageSentStatus:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *_status = [paramDict objectForKey:@"sentStatus"];
        NSNumber *_messageId = [paramDict objectForKey:@"messageId"];
        [self.rongCloudAdapter setMessageSentStatus:_messageId sentStatus:_status withCallBackId:cbId];
    }
}
- (void)getCurrentUserId:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        [self.rongCloudAdapter getCurrentUserId:cbId];
    }
}
- (void)addToBlacklist:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *_userId = [paramDict objectForKey:@"userId"];
        [self.rongCloudAdapter addToBlacklist:_userId withCallBackId:cbId];
    }
}
- (void)removeFromBlacklist:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *_userId = [paramDict objectForKey:@"userId"];
        [self.rongCloudAdapter removeFromBlacklist:_userId withCallBackId:cbId];
    }
}
- (void)getBlacklistStatus:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *userId = [paramDict objectForKey:@"userId"];
        [self.rongCloudAdapter getBlacklistStatus:userId withCallBackId:cbId];
    }
}
- (void)getBlacklist:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        [self.rongCloudAdapter getBlacklist:cbId];
    }
}
- (void)setNotificationQuietHours:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        NSString *startTime = [paramDict objectForKey: @"startTime"];
        NSNumber *spanMinutes = [paramDict objectForKey: @"spanMinutes"];
        [self.rongCloudAdapter setNotificationQuietHours:startTime spanMins:spanMinutes withCallBackId:cbId];
    }
}
- (void)removeNotificationQuietHours:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        [self.rongCloudAdapter removeNotificationQuietHours:cbId];
    }
}
- (void)getNotificationQuietHours:(NSDictionary *)paramDict {
    NSLog(@"%s", __FUNCTION__);
    
    NSNumber *cbId = [paramDict objectForKey:@"cbId"];
    
    if (cbId) {
        [self.rongCloudAdapter getNotificationQuietHours:cbId];
    }
}
@end
