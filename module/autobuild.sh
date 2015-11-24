#!/bin/sh

#  build-imkit.sh
#  RongIMKit
#
#  Created by xugang on 4/8/15.
#  Copyright (c) 2015 RongCloud. All rights reserved.


PROJECT_NAME="RongCloud.xcodeproj"
targetName="RongCloud"
TARGET_DECIVE="iphoneos"

configuration="Release"

xcodebuild clean -configuration $configuration -sdk $TARGET_DECIVE

echo "***开始build iphoneos文件***"
xcodebuild -project ${PROJECT_NAME} -target "$targetName" -configuration $configuration  -sdk $TARGET_DECIVE build

echo "***完成Build ${targetName}静态库${configuration}****"