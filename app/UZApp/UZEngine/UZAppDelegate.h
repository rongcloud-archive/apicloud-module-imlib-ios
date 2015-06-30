//
//  UZAppDelegate.h
//  UZEngine
//
//  Created by broad on 14-1-13.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UZWidgetManager;
@class UZWidgetController;

@interface UZAppDelegate : UIResponder
<UIApplicationDelegate>

@property (readonly, strong, nonatomic) NSMutableArray *widgetControllers;
@property (readonly, strong, nonatomic) UZWidgetManager *uzWgtMgr;
@property (readonly, strong, nonatomic) NSMutableDictionary *appHandleDict;
@property (atomic) BOOL UZIsBusy;
@property (nonatomic) BOOL pageLoadDone;

- (NSArray *)features;

- (void)addAppHandle:(id <UIApplicationDelegate>)handle;
- (void)removeAppHandle:(id <UIApplicationDelegate>)handle;

@end

#define theApp ((UZAppDelegate *)[[UIApplication sharedApplication] delegate])
