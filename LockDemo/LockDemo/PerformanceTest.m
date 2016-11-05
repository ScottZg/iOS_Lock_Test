//
//  PerformanceTest.m
//  LockDemo
//
//  Created by zhanggui on 2016/11/5.
//  Copyright © 2016年 zhanggui. All rights reserved.
//

#import "PerformanceTest.h"
#include <pthread.h>
#import <libkern/OSAtomic.h>
#include <os/lock.h>
@implementation PerformanceTest


+ (void)setup {
    int totalDuration = 1024*1024*50;
    double then,now;
    @autoreleasepool {
        NSLock *lock = [[NSLock alloc] init];
        //NSLock
        then  = CFAbsoluteTimeGetCurrent();
        for (int i=0;i<totalDuration;i++) {
            [lock lock];
            [lock unlock];
        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"NSLock times:%f",now-then);
//@synchorized
        id obj = [[NSObject alloc] init];
        then  = CFAbsoluteTimeGetCurrent();
        for (int i=0;i<totalDuration;i++) {
            @synchronized (obj) {
                
            }
        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"synthorize times:%f",now-then);
//gcd
         dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
        then  = CFAbsoluteTimeGetCurrent();
       
        for (int i=0;i<totalDuration;i++) {
            dispatch_semaphore_wait(semaphore,1);
            dispatch_semaphore_signal(semaphore);

        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"gcd times:%f",now-then);
        //pthread
        pthread_mutex_t mutext = PTHREAD_MUTEX_INITIALIZER;
        then  = CFAbsoluteTimeGetCurrent();
        
        for (int i=0;i<totalDuration;i++) {
            pthread_mutex_lock(&mutext);
            pthread_mutex_unlock(&mutext);
        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"pthread times:%f",now-then);
        //OSS 弃用了，
        OSSpinLock spinLock = OS_SPINLOCK_INIT;
        then  = CFAbsoluteTimeGetCurrent();
        
        for (int i=0;i<totalDuration;i++) {
            OSSpinLockLock(&spinLock);
            OSSpinLockUnlock(&spinLock);
        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"OSSPinLock times:%f",now-then);
        
                //os_unfair_lock
        os_unfair_lock unfairLock = (OS_UNFAIR_LOCK_INIT);
        then  = CFAbsoluteTimeGetCurrent();
        
        for (int i=0;i<totalDuration;i++) {
            os_unfair_lock_lock(&unfairLock);
            os_unfair_lock_unlock(&unfairLock);
        }
        now  = CFAbsoluteTimeGetCurrent();
        NSLog(@"os_unfair_lock times:%f",now-then);
    }
}

@end
