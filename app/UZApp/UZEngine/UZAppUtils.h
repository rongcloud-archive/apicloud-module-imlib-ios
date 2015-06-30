//
//  UZApp.h
//  UZEngine
//
//  Created by broad on 13-11-12.
//  Copyright (c) 2013年 APICloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#define isIPhone6Plus (CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size))

#define isIPhone6 (CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size))

#define isIPhone5 (CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size))

#define isRetina ([[UIScreen mainScreen] scale] > 1)

#define isIOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0

@interface UZAppUtils : NSObject

#pragma mark - Device info
+ (BOOL)isSimulator;
+ (BOOL)popoverSupported;
+ (NSString *)getUUID;

#pragma mark - Paths
+ (NSString *)filePathInBundle:(NSString *)fileName;
+ (NSString *)filePathInWidget:(NSString *)fileName;
+ (NSString *)appLibraryPath;
+ (NSString *)filePathInLibrary:(NSString *)fileName;
+ (NSString *)appDocumentPath;
+ (NSString *)filePathInDocument:(NSString *)fileName;
+ (NSString *)filePathInUZFS:(NSString *)fileName;
+ (NSString *)getPathWithUZSchemeURL:(NSString *)urlStr;
+ (BOOL)isFileReadOnly:(NSString *)filePath;

#pragma mark - Util
+ (UIColor *)colorFromNSString:(NSString *)colorStr;

@end
