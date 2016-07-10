//
//  DBModelTests.m
//  DBModelTests
//
//  Created by zyz on 16/7/11.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "User.h"
#import "SQLExecutor.h"
#import "DatabaseVersionManager.h"
#import "DatabaseConstants.h"
#import "DBVersionMigration1.h"

#define WAIT do {\
[self expectationForNotification:@"Test" object:nil handler:nil];\
[self waitForExpectationsWithTimeout:20 handler:nil];\
} while (0)

#define NOTIFY \
[[NSNotificationCenter defaultCenter]postNotificationName:@"Test" object:nil]

@interface DBModelTests : XCTestCase

@end

// 只能一个一个测试，不能一次性测全部！！
@implementation DBModelTests

- (void)setUp {
    [super setUp];
    
    NSLog(@"数据库地址 %@", kDatabasePath);
    
    DatabaseVersionManager *manager = [DatabaseVersionManager managerWithDBPath:kDatabasePath];
    [manager addMigrations:[self allMigrations]];
    [manager updateDatabaseToVersion:1 finish:^(BOOL success) {
        if (success) {
            NSLog(@"数据库创建/更新成功");
        }
    }];
}

- (NSArray<BaseDBVersionMigration *> *)allMigrations {
    return @[
             [DBVersionMigration1 new],
             ];
}

#pragma mark 更新模块
- (void)testUserDeleteSomeone {
    [User findWhere:@"user_name='user_name3'" finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [User delete:models finish:^(SQLExecuteFailModel *failModel) {
                if (failModel) {
                    NSLog(@"删除失败 %@", failModel.errorMsg);
                }
                NOTIFY;
            }];
            
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
            NOTIFY;
        }
    }];
    WAIT;
}

- (void)testUserDeleteAll {
    [User deleteAll:^(SQLExecuteFailModel *failModel) {
        if (failModel) {
            NSLog(@"删除失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserInsert {
    NSMutableArray *users = [NSMutableArray array];
    for (NSInteger i = 0; i < 100; i++) {
        User *user = [[User alloc] init];
        user.userId = i;
        user.userName = [NSString stringWithFormat:@"user_name%ld", i];
        user.mobile = [NSString stringWithFormat:@"%ld", 13632200000 + i];
        user.age = (i % 80) + 1;
        [users addObject:user];
    }
    [User save:users finish:^(SQLExecuteFailModel *failModel) {
        if (!failModel) {
            NSLog(@"插入/更新成功");
        } else {
            NSLog(@"插入/更新失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserUpdate {
    [User findWhere:@"age<=10" limit:10 finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            for (NSInteger i = 0; i < models.count; i++) {
                User *user = models[i];
                user.mobile = [NSString stringWithFormat:@"%ld", 13560046600 + i];
                user.userName = [NSString stringWithFormat:@"name_%ld", i];
            }
            [User save:models finish:^(SQLExecuteFailModel *failModel) {
                if (!failModel) {
                    NSLog(@"更新成功");
                } else {
                    NSLog(@"更新失败 %@", failModel.errorMsg);
                }
                NOTIFY;
            }];
            
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
            NOTIFY;
        }
    }];
    WAIT;
}

#pragma mark 查询模块
- (void)testUserFindAll {
    [User findAll:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindAllWithOrder {
    [User findAllWithOrder:[NSString desc:@"user_id"] finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindWithCondition {
    [User findWhere:[@"user_id=3" or:@"age=20"] finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindWithConditionAndOrder {
    [User findWhere:[@"user_id=3" or:@"age=20"] order:[NSString desc:@"user_id"] finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindWithLimit {
    [User findWhere:@"age<80" limit:5 finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindWithLimitAndOffset {
    [User findWhere:@"age<80" offset:20 limit:5 finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

// 测试最多参数的那个查询
- (void)testUserFindWithAllArgs {
    [User findWhere:@"age<80" order:[NSString desc:@"age"] offset:10 limit:10 finish:^(NSArray *models, SQLExecuteFailModel *failModel) {
        if (!failModel) {
            [self printUsers:models];
        } else {
            NSLog(@"查找失败 %@", failModel.errorMsg);
        }
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindCount {
    [User count:^(NSInteger count) {
        NSLog(@"总共%ld个user", count);
        NOTIFY;
    }];
    WAIT;
}

- (void)testUserFindCountWithCondition {
    [User countWhere:@"age<40" finish:^(NSInteger count) {
        NSLog(@"小于40岁的user有%ld个", count);
        NOTIFY;
    }];
    WAIT;
}

- (void)printUsers:(NSArray<User *> *)users {
    for (User *user in users) {
        [self printUser:user];
    }
}

- (void)printUser:(User *)user {
    NSLog(@"\nuser_id:%ld\nuser_name:%@\nmobile:%@\nage:%ld", user.userId, user.userName, user.mobile, user.age);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
