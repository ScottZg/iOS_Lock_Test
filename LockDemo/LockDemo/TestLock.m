//
//  TestLock.m
//  LockDemo
//
//  Created by zhanggui on 2016/11/4.
//  Copyright © 2016年 zhanggui. All rights reserved.
//

#import "TestLock.h"

@implementation TestLock

- (void)method1 {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)method2 {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
@end
