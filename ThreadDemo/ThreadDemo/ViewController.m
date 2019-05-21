//
//  ViewController.m
//  ThreadDemo
//
//  Created by zhanggui on 2019/5/20.
//  Copyright © 2019 zhanggui. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#include <pthread.h>
#import <libkern/OSAtomic.h>
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *lockArray;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) __block Person *person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 54;
    _person = [Person new];
}

#pragma mark - UITabViewDelegate && UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.lockArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LockCell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell.textLabel setText:self.lockArray[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.person.age = 0;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self nsLockDemo];
            break;
        case 1:
            [self synchronizedDemo];
            break;
        case 2:
            [self pthreadmutexDemo];
            break;
        case 3:
            [self pthreadRecursiveDemo];
            break;
        case 4:
            [self pthreadSingalDemo];
            break;
        case 5:
            [self pthreadReadAndWriteDemo];
            break;
        case 6:
            [self singalDemo];
            break;
        case 7:
            [self conditionLockDemo];
            break;
        case 8:
            [self nsconditionDemo];
            break;
        case 9:
            [self rescureLockDemo:10];
            break;
        default:
            break;
    }
}

#pragma mark - lock
/**
 NSLock的使用
 */
- (void)nsLockDemo {
    NSLock *lock = [[NSLock alloc] init];
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            [lock lock];
            self.person.age += 1;
            [lock unlock];
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            [lock lock];
            self.person.age += 1;
            [lock unlock];
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}

/**
 synchronized
 */
- (void)synchronizedDemo {
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            @synchronized (self.person) {
                self.person.age += 1;
            }
            
           
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            @synchronized (self.person) {
                self.person.age += 1;
            }
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];

}
- (void)pthreadmutexDemo {
    __block pthread_mutex_t t;
    pthread_mutex_init(&t, NULL);
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            pthread_mutex_lock(&t);
            self.person.age += 1;
            pthread_mutex_unlock(&t);
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            pthread_mutex_lock(&t);
            self.person.age += 1;
            pthread_mutex_unlock(&t);
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}
- (void)pthreadRecursiveDemo {
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    
    pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, &attr);
    pthread_mutexattr_destroy(&attr);
    __block pthread_mutex_t t = mutex;
    
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            pthread_mutex_lock(&t);
            self.person.age += 1;
            pthread_mutex_unlock(&t);
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            pthread_mutex_lock(&t);
            self.person.age += 1;
            pthread_mutex_unlock(&t);
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}
- (void)pthreadSingalDemo {
    __block pthread_mutex_t t = PTHREAD_MUTEX_INITIALIZER;
    __block pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
    NSLog(@"begin");
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            pthread_mutex_lock(&t);
            pthread_cond_wait(&cond, &t);
            self.person.age += 1;
            pthread_mutex_unlock(&t);
           
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            pthread_mutex_lock(&t);
            self.person.age += 1;
            pthread_cond_signal(&cond);
            pthread_mutex_unlock(&t);
        
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}
- (void)pthreadReadAndWriteDemo {
    __block pthread_rwlock_t rwl = PTHREAD_RWLOCK_INITIALIZER;
    NSLog(@"begin");
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            pthread_rwlock_rdlock(&rwl);
            self.person.age += 1;
            NSLog(@"打印age为：%ld",self.person.age);
            pthread_rwlock_unlock(&rwl);
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            pthread_rwlock_wrlock(&rwl);
            self.person.age += 1;
            NSLog(@"新增,变成%ld",self.person.age);
            pthread_rwlock_unlock(&rwl);
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}

/**
 信号量
 */
- (void)singalDemo {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            self.person.age += 1;
            dispatch_semaphore_signal(semaphore);
           
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            self.person.age += 1;
            dispatch_semaphore_signal(semaphore);
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
}

/**
 状态锁
 */
- (void)conditionLockDemo {
//    //主线程中
//    NSConditionLock *theLock = [[NSConditionLock alloc] init];
//    //线程1
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (int i=0;i<=5;i++)
//        {
//            [theLock lockWhenCondition:0];
//            NSLog(@"thread1:%d",i);
//            sleep(2);
//            [theLock unlockWithCondition:1];
//        }
//    });
//    //线程2
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [theLock lockWhenCondition:1];
//        NSLog(@"thread2");
//        [theLock unlockWithCondition:0];
//    });
    NSConditionLock *lock = [NSConditionLock new];

    NSInteger thread1 = 1;
    NSInteger thread2 = 0;

    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            [lock lockWhenCondition:thread1];
            self.person.age += 1;
            NSLog(@"thread1 age:%ld",self.person.age);
//            NSLog(@"age变大，为：%ld",self.person.age);
            [lock unlockWithCondition:thread2];
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            [lock lockWhenCondition:thread2];
            self.person.age += 1;
            NSLog(@"thread2 age:%ld",self.person.age);
            [lock unlockWithCondition:thread1];
        }
//        [lock lockWhenCondition:thread2];
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
//        [lock unlockWithCondition:thread1];
    }];
}
- (void)nsconditionDemo {
    NSCondition *lock = [[NSCondition alloc] init];
    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i <1000; i++) {
            [lock lock];
            while (self.person.age % 2 == 0) {
                [lock wait];
            }
            self.person.age += 1;
            [lock signal];
            [lock unlock];
          
            
        }
        NSLog(@"1-%@",[NSThread currentThread]);
        NSLog(@"p1:%ld",(long)self.person.age);
    }];
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i < 1000; i++) {
            [lock lock];
            while (self.person.age % 2 == 1) {
                [lock wait];
            }
            self.person.age += 1;
            [lock signal];
            [lock unlock];
        }
        NSLog(@"2-%@",[NSThread currentThread]);
        NSLog(@"p2:%ld",(long)self.person.age);
    }];
    
}
- (void)rescureLockDemo:(NSInteger)value {
   
    NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
    [lock lock];
    if (value != 0) {
        --value;
        [self rescureLockDemo:value];
    }
    [lock unlock];
    NSLog(@"2323");
    
}
#pragma mark - lazy load
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self.view addSubview:_tableView];
    }
    
    return _tableView;
}
- (NSArray *)lockArray {
    if (!_lockArray) {
        _lockArray = @[@"NSLock",
                       @"synchronized",
                       @"pthread（互斥锁or普通锁）",
                       @"pthread（递归锁）",
                       @"pthread（信号量）",
                       @"pthread（读写锁）",
                       @"信号量",
                       @"NSConditionalLock",
                       @"NSCondition",
                       @"递归锁"
                       ];
    }
    return _lockArray;
}
@end
