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
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testRunLoop];
}


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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
