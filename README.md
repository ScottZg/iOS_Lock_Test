##### 谈谈iOS中的锁(解析一下NSLock)
##### 1 前言
近日工作不是太忙，刚好有时间了解一些其他东西，本来打算今天上午去体检，但是看看天气还是明天再去吧，也有很大一个原因：就是周六没有预约上！闲话少说，这里简单对锁来个简单介绍分享。
##### 2 目录
* 第一部分：什么是锁
* 第二部分：锁的分类
* 第三部分：锁的作用
* 第四部分：iOS中锁的实现
##### 第一部分：什么是锁
从小就知道锁，就是家里门上的那个锁，用来防止盗窃的锁。它还有钥匙，用于开锁。不过这里的锁，并不是小时候认知的锁，而是站在程序员的角度的锁。这里我就按照我的理解来介绍一下锁。   
在计算机科学中，锁是一种同步机制，用于在存在多线程的环境中实施对资源的访问限制。你可以理解成它用于排除并发的一种策略。看例子
```c
if (lock == 0) {
lock = myPID;
}
```
上面这段代码并不能保证这个任务有个锁，因此它可以在同一时间被多个任务执行。这个时候就有可能多个任务都检测到lock是空闲的，因此两个或者多个任务都将尝试设置lock，而不知道其他的任务也在尝试设置lock。这个时候就会出问题了。
再看看这段代码：
```c#
class Acccount {
long val = 0;  //这里不可在其他方法修改，只能通过add/minus修改
object thisLock = new object();
public void add(const long x) {
	lock(thisLock) {
		val +=x;
	}
}
public void minus(const long x) {
	lock(thisLock) {
		val -=x;
		}
	}
}
```
这样就能防止多个任务去修改val了，(这里注意，如果val是public的，那个也会导致一些问题)。
##### 第二部分：锁的分类
锁根据不同的性质可以分成不同的类。   
在WiKiPedia介绍中，一般的锁都是建议锁，也就四每个任务去访问公共资源的时候，都需要取得锁的资讯，再根据锁资讯来确定是否可以存取。若存取对应资讯，锁的状态会改变为锁定，因此其他线程不会访问该资源，当结束访问时，锁会释放，允许其他任务访问。有些系统有强制锁，若未经授权的锁访问锁定的资料，在访问时就会产生异常。   
在iOS中，锁分为递归锁、条件锁、分布式锁、一般锁（这里是看着NSLock类里面的分类划分的）。    
对于数据库的锁分类：

| 分类方式      | 分类          |
| --------- | ----------- |
| 按锁的粒度划分   | 表级锁、行级锁、页级锁 |
| 按锁的级别划分   | 共享锁、排他锁     |
| 按加锁方式划分   | 自动锁、显示锁     |
| 按锁的使用方式划分 | 乐观锁、悲观锁     |
| 按操作划分     | DML锁、DDL锁   |
这里就不在详细介绍了，感兴趣的大家可以自己查阅相关资料。
##### 第三部分：锁的作用
这个比较通俗来讲：就是为了防止在多线程(多任务)的情况下对共享资源(临界资源)的脏读或者脏写。也可以理解为：执行多线程时用于强行限制资源访问的同步机制，即并发控制中保证互斥的要求。
##### 第四部分：iOS中锁的实现
先看看iOS中NSLock类的.h文件。这里就不在写上来了。从代码中可以看出，该类分成了几个子类：NSLock、NSConditionLock、NSRecursiveLock以及NSCondition。然后有一个NSLocking的协议：
```Objective-c
@protocol NSLocking
- (void)lock;
- (void)unlock;
@end
```
这几个子类都遵循了NSLock的协议，这里简单介绍一下其中的几个方法：
对于tryLock方法，尝试获取一个锁，并且立刻返回Bool值，YES表示获取了锁，NO表示没有获取锁失败。 lockBeforeDate:方法，在某个时刻之前获取锁，如果获取成功，则返回YES，NO表示获取锁失败。接下来就让我们看一下iOS中实现锁的方式：
###### 方式1 使用NSLock类
```Objective-c
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
```
###### 方式2 使用@synchorize
```Objective-c
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
```
对于@synchorize指令中使用的testLock为该锁标示，只有标示相同的时候才满足锁的效果。它的优点是不用显式地创建锁，便可以实现锁的机制。但是它会隐式地添加异常处理程序来保护代码，该程序在抛出异常的时候自动释放锁。
###### 方式3 使用gcd
```Objective-c
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
```
###### 方式4 使用phtread
```Objective-c
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
```
pthread_mutex_t定义在pthread.h，所以记得#include。

##### 3 性能对比
这里简单写一个[小程序](https://github.com/ScottZg/iOS_Lock_Test)来进行四种方式的性能对比，这里再固定次数内进行了加锁解锁，然后输出用时，结果如下（测试1、2执行次数不一样：测试1 < 测试2）：
```shell
测试1
2016-11-05 15:27:52.595 LockDemo[4394:202297] NSLock times:0.871843
2016-11-05 15:27:56.335 LockDemo[4394:202297] synthorize times:3.738939
2016-11-05 15:27:56.691 LockDemo[4394:202297] gcd times:0.355344
2016-11-05 15:27:57.328 LockDemo[4394:202297] pthread times:0.636815
2016-11-05 15:27:57.559 LockDemo[4394:202297] OSSPinLock times:0.231013
2016-11-05 15:27:57.910 LockDemo[4394:202297] os_unfair_lock times:0.350615
测试2
2016-11-05 15:30:54.123 LockDemo[4454:205180] NSLock times:1.908103
2016-11-05 15:31:02.112 LockDemo[4454:205180] synthorize times:7.988547
2016-11-05 15:31:02.905 LockDemo[4454:205180] gcd times:0.792113
2016-11-05 15:31:04.372 LockDemo[4454:205180] pthread times:1.466987
2016-11-05 15:31:04.870 LockDemo[4454:205180] OSSPinLock times:0.497487
2016-11-05 15:31:05.637 LockDemo[4454:205180] os_unfair_lock times:0.767569

```
这里还测试了OSSPinLock(此类已经被os_unfair_lock所替代)。结果如下：
synthorize > NSLock > pthread > gcd > os_unfair_lock >OSSPinLock
这里：   
synthorize内部会添加异常处理，所以耗时。   
pthread_mutex底层API，处理能力不错。   
gcd系统封装的C代码效果比pthread好。

##### 4 总结
简单就介绍这么多。
##### 5 参考文档：
* http://www.liuhaihua.cn/archives/220300.html
* https://zh.wikipedia.org/zh-hans/%E9%94%81_(%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%A7%91%E5%AD%A6)
* https://en.wikipedia.org/wiki/Lock_(computer_science)
