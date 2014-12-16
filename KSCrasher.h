//
//  KSCrasher.h
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCrasher : NSObject

- (void) throwException;

- (void) dereferenceBadPointer;

- (void) dereferenceNullPointer;

- (void) useCorruptObject;

- (void) spinRunloop;

- (void) causeStackOverflow;

- (void) doAbort;

- (void) doDiv0;

- (void) doIllegalInstruction;

- (void) accessDeallocatedObject;

- (void) accessDeallocatedPtrProxy;

- (void) zombieNSException;

- (void) corruptMemory;

- (void) deadlock;

@end
