//
//  KSCrashInstallationFile.h
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "KSCrashInstallation.h"

@interface KSCrashInstallationFile : KSCrashInstallation

@property(nonatomic,readwrite,retain) NSString* fileDir;

+ (KSCrashInstallationFile*) sharedInstance;

@end
