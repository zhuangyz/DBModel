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
    static SQLExecutor *executor = nil;
    static dispatch_once_t once;
    _dispatch_once(&once, ^{
        executor = [SQLExecutor executorWithDBPath:[[self class] databasePath]];
    });
    return executor;
}

@end
#pragma clang diagnostic pop




















