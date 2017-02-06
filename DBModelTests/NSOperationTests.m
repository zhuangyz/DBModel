//
//  NSOperationTests.m
//  DBModel
//
//  Created by Walker on 2017/2/6.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import <XCTest/XCTest.h>

#define WAIT do {\
[self expectationForNotification:@"Test" object:nil handler:nil];\
[self waitForExpectationsWithTimeout:60 handler:nil];\
} while (0)

#define NOTIFY \
[[NSNotificationCenter defaultCenter] postNotificationName:@"Test" object:nil]

@interface NSOperationTests : XCTestCase

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *indexs;

@end

@implementation NSOperationTests

- (void)setUp {
    [super setUp];
    
    self.queue = [[NSOperationQueue alloc] init];
    self.indexs = [NSMutableArray array];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
    分别测试下面两个方法，并且对比输出日志，可以发现queue.maxConcurrentOperationCount不等于1时，队列可以看成是并行队列，而等于1时，队列可以看成是串行队列
 */

- (void)testConcurrent {
    self.queue.maxConcurrentOperationCount = NSIntegerMax;
    for (NSInteger i = 0; i < 1000; i++) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"%ld %@", i, [NSThread currentThread]);
            [self.indexs addObject:@(i)];
        }];
        [self.queue addOperation:operation];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10), dispatch_get_main_queue(), ^{
        for (NSInteger i = 1; i < self.indexs.count; i++) {
            if ([self.indexs[i] integerValue] < [self.indexs[i - 1] integerValue]) {
                NSLog(@"--------%@, %@", self.indexs[i - 1], self.indexs[i]);
            }
        }
        [self.indexs removeAllObjects];
        NOTIFY;
    });
    WAIT;
}

- (void)testSerial {
    self.queue.maxConcurrentOperationCount = 1;
    for (NSInteger i = 0; i < 1000; i++) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"%ld %@", i, [NSThread currentThread]);
            [self.indexs addObject:@(i)];
        }];
        [self.queue addOperation:operation];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10), dispatch_get_main_queue(), ^{
        for (NSInteger i = 1; i < self.indexs.count; i++) {
            if ([self.indexs[i] integerValue] < [self.indexs[i - 1] integerValue]) {
                NSLog(@"--------%@, %@", self.indexs[i - 1], self.indexs[i]);
            }
        }
        NOTIFY;
    });
    WAIT;
}

@end




















