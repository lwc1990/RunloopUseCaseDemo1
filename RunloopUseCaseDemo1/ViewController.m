//
//  ViewController.m
//  RunloopUseCaseDemo1
//
//  Created by syl on 2017/5/4.
//  Copyright © 2017年 personCompany. All rights reserved.
//

#import "ViewController.h"
@interface TestThread:NSThread
@end
@implementation TestThread
-(void)dealloc
{
    NSLog(@"%s",__func__);
}
@end
@interface ViewController ()
@property (nonatomic,strong) TestThread *subThread;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    NSLog(@"---currentRunLoop:%@",[NSRunLoop currentRunLoop]);
    NSLog(@"---mainRunLoop:%@",[NSRunLoop mainRunLoop]);
    [self testRunLoop];
}
/*
//如果按照下面的设计，不把线程放进RunLoop，在执行过线程的任务后，线程就会销毁。
-(void)testRunLoop
{
    TestThread *_testThread = [[TestThread alloc]initWithTarget:self selector:@selector(subThreadOperation) object:nil];
    _testThread.name = @"测试线程";
    [_testThread start];
}
-(void)subThreadOperation
{
    NSLog(@"%@-%@是主线程:%d",[NSThread currentThread].name,[NSThread currentThread],[[NSThread currentThread] isMainThread]);
    NSLog(@"%@:%@---子线程开始",[[NSThread currentThread] name],[NSThread currentThread]);
    [TestThread sleepForTimeInterval:3];
    NSLog(@"%@:%@---子线程结束",[[NSThread currentThread] name],[NSThread currentThread]);
}
*/
// 如果我们需要频繁的做子线程中的操作，我们就需要频繁的创建和销毁操作所在的线程，这样频繁的创建和销毁会造成大量资源的消耗，我们可以用RunLoop来保证线程不死，而让线程反复执行其中的操作即可，下面我们测试给子线程开辟RunLoop
-(void)testRunLoop
 {
     TestThread *_testThread = [[TestThread alloc]initWithTarget:self selector:@selector(startRunLoop) object:nil];
     _testThread.name = @"测试线程";
     [_testThread start];
     self.subThread = _testThread;
 
 }
//启动runLoop
-(void)startRunLoop
{
    //获取runLoop 只能通过[NSRunLoop currentRunLoop],[NSRunLoop mainRunLoop],
    //这两个方法都是在全局字典中取的，如果字典没有与之匹配的RunLoop，就会创建一个。
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    //如果注释这行代码，线程的操作就不会执行，因为没有给RunLoop添加item，RunLoop就直接进入了休眠。下面的代码就是给对应的RunLoop添加item，NSPort就对应Source，NSRunLoop经过封装后，就只添加两种item，source，Timer，保证线程不死。
    [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
    NSLog(@"---runLoop:%@",runLoop);
    NSLog(@"---runLoop 启动");
    [runLoop run];

}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self performSelector:@selector(subThreadOperation) onThread:[self subThread] withObject:nil waitUntilDone:NO];
}
-(void)subThreadOperation
{
    NSLog(@"%@-%@是主线程:%d",[NSThread currentThread].name,[NSThread currentThread],[[NSThread currentThread] isMainThread]);
    NSLog(@"%@:%@---子线程开始",[[NSThread currentThread] name],[NSThread currentThread]);
    [TestThread sleepForTimeInterval:3];
    NSLog(@"%@:%@---子线程结束",[[NSThread currentThread] name],[NSThread currentThread]);
}
/*
 有几点需要注意：
 1.获取RunLoop只能使用 [NSRunLoop currentRunLoop] 或 [NSRunLoop mainRunLoop];
 2.即使RunLoop开始运行，如果RunLoop 中的 modes 为空，或者要执行的mode里没有item，那么RunLoop会直接在当前loop中返回，并进入睡眠状态。
 3.自己创建的Thread中的任务是在kCFRunLoopDefaultMode这个mode中执行的。
 
 注意点一解释
 RunLoop官方文档中的第二段中就已经说明了，我们的应用程序并不需要自己创建RunLoop，而是要在合适的时间启动runloop。
 CF框架源码中有CFRunLoopGetCurrent(void) 和 CFRunLoopGetMain(void),查看源码可知，这两个API中，都是先从全局字典中取，如果没有与该线程对应的RunLoop，那么就会帮我们创建一个RunLoop（创建RunLoop的过程在函数_CFRunLoopGet0(pthread_t t)中）。
 
 注意点二解释
 这一点，可以将示例代码中的[runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];，可以看到注释掉后，无论我们如何点击视图，控制台都不会有任何的输出，那是因为mode 中并没有item任务。经过NSRunLoop封装后，只可以往mode中添加两类item任务：NSPort（对应的是source）、NSTimer，如果使用CFRunLoopRef,则可以使用C语言API,往mode中添加source、timer、observer。
 如果不添加 [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];，我们把runloop的信息输出，可以看到：
 
 添加port前的RunLoop
 如果我们添加上[runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];,再把RunLoop的信息输出，可以看到：
 
 添加port后的RunLoop
 注意点三解释
 怎么确认自己创建的子线程上的任务是在kCFRunLoopDefaultMode这个mode中执行的呢？
 我们只需要在执行任务的时候，打印出该RunLoop的currentMode即可。
 因为RunLoop执行任务是会在mode间切换，只执行该mode上的任务，每次切换到某个mode时，currentMode就会更新。源码请下载：CF框架源码
 CFRunLoopRun()方法中会调用CFRunLoopRunSpecific()方法，而CFRunLoopRunSpecific()方法中有这么两行关键代码：
 
 CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
 ......这中间还有好多逻辑代码
 CFRunLoopModeRef previousMode = rl->_currentMode;
 rl->_currentMode = currentMode;
 ...... 这中间也有一堆的逻辑
 rl->_currentMode = previousMode;

 
 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
@end
