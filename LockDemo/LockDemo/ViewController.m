//
//  ViewController.m
//  LockDemo
//
//  Created by zhanggui on 2016/11/4.
//  Copyright © 2016年 zhanggui. All rights reserved.
//

#import "ViewController.h"
#import "TestLock.h"
#include <pthread.h>
#import "PerformanceTest.h"
@interface ViewController ()

@property (nonatomic,strong)TestLock *testLock;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PerformanceTest setup];
    
}
- (IBAction)testLock:(id)sender {
   
}



//信号量加锁
- (void)gcdDemo {
    _testLock = [[TestLock alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [_testLock method1];
        sleep(5);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [_testLock method2];
        dispatch_semaphore_signal(semaphore);
    });

}
//C语言 互斥锁
- (void)pthreadDemo {
    _testLock = [[TestLock alloc] init];
    
    __block pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, NULL);
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pthread_mutex_lock(&mutex);
        [_testLock method1];
        sleep(5);
        pthread_mutex_unlock(&mutex);
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        pthread_mutex_lock(&mutex);
        [_testLock method2];
        pthread_mutex_unlock(&mutex);
    });

}
//互斥锁
- (void)synchronizeDemo {
    _testLock = [[TestLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (_testLock) {
            [_testLock method1];
            sleep(5);
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        @synchronized (_testLock) {
            
            [_testLock method2];
        }
    });
}
- (void)nslockDemo {
    NSLock *myLock = [[NSLock alloc] init];
    _testLock = [[TestLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [myLock lock];
        [_testLock method1];
        sleep(5);
        [myLock unlock];
        if ([myLock tryLock]) {
            NSLog(@"可以获得锁");
        }else {
            NSLog(@"不可以获得所");
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        if ([myLock tryLock]) {
            NSLog(@"---可以获得锁");
        }else {
            NSLog(@"----不可以获得所");
        }
        [myLock lock];
        [_testLock method2];
        [myLock unlock];
    });
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
