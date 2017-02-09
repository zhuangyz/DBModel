//
//  BaseDBModel.m
//  FMDBTest
//
//  Created by zyz on 16/7/4.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel.h"
#import "BaseDBModel+CreateTable.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation BaseDBModel

+ (NSString *)databasePath {
    return kDatabasePath;
}

+ (SQLExecutor *)executor {
    // 在-executorWithDBPath:里，每个path产生的是同一个SQLExecutor对象（根据path保存对象）
    return [SQLExecutor executorWithDBPath:[[self class] databasePath]];
}

@end
#pragma clang diagnostic pop




















