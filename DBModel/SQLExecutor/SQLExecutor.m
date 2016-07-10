//
//  SQLExecutor.m
//  FMDBTest
//
//  Created by zyz on 16/7/6.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "SQLExecutor.h"
#import <FMDB.h>

@implementation SQLExecuteFailModel

- (instancetype)initWithCode:(NSInteger)code msg:(NSString *)msg {
    if (self = [super init]) {
        self.errorCode = code;
        self.errorMsg = msg;
    }
    return self;
}

@end

@interface SQLExecutor ()

@property (nonnull, nonatomic, strong) dispatch_queue_t executeQueue;

@property (nonnull, nonatomic, copy) NSString *dbPath;

@property (nonnull, nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation SQLExecutor

- (void)dealloc {
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.autoRollBackWhenError = YES;
    }
    return self;
}

+ (instancetype)executorWithDBPath:(NSString *)path {
    NSAssert(path, @"path can not nill");
    SQLExecutor *executor = [[SQLExecutor alloc] init];
    executor.executeQueue = dispatch_queue_create("com.sql_executor_queue", DISPATCH_QUEUE_SERIAL);
    executor.dbPath = path;
    executor.dbQueue = [[FMDatabaseQueue alloc] initWithPath:path];
    
    return executor;
}

- (void)executeQuery:(nonnull NSString *)sql
              finish:(nullable SQLExecuteResultBlock)finish {
    
    [self executeQuery:sql withArgumentsInArray:nil finish:finish];
}

- (void)executeQuery:(nonnull NSString *)sql
withArgumentsInArray:(nullable NSArray *)arguments
              finish:(nullable SQLExecuteResultBlock)finish {
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_async(self.executeQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableArray *result = [NSMutableArray array];
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:arguments];
            
            // 执行错误
            if (!rs) {
                SQLExecuteFailModel *failModel;
                if ([db hadError]) {
                    failModel = [[SQLExecuteFailModel alloc] initWithCode:[db lastErrorCode] msg:[db lastErrorMessage]];
                }
                // 回归主线程下回调finish block
                dispatch_async(dispatch_get_main_queue(), ^{
                    run_block_if_exist(finish, NO, nil, failModel);
                });
                return ;
            }
            
            while ([rs next]) {
                [result addObject:[rs resultDictionary]];
            }
            
            // 回归主线程下回调finish block
            dispatch_async(dispatch_get_main_queue(), ^{
                run_block_if_exist(finish, YES, result, nil);
            });
        }];
    });
}

- (void)executeUpdate:(nonnull NSString *)sql
               finish:(nullable SQLExecuteResultBlock)finish {

    [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:nil finish:finish];
}

- (void)executeUpdate:(nonnull NSString *)sql
withParameterDictionary:(nullable NSDictionary *)arguments
               finish:(nullable SQLExecuteResultBlock)finish {
    
    [self executeUpdate:sql withParameterDictionary:arguments orWithArgumentsInArray:nil finish:finish];
}

- (void)executeUpdate:(nonnull NSString *)sql
 withArgumentsInArray:(nullable NSArray *)arguments
               finish:(nullable SQLExecuteResultBlock)finish {
    
    [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:arguments finish:finish];
}

- (void)executeUpdate:(nonnull NSString *)sql
withParameterDictionary:(nullable NSDictionary *)params
orWithArgumentsInArray:(nullable NSArray *)arguments
               finish:(nullable SQLExecuteResultBlock)finish {
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_async(self.executeQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL success = NO;
            
            if (params) {
                success = [db executeUpdate:sql withParameterDictionary:params];
            } else if (arguments) {
                success = [db executeUpdate:sql withArgumentsInArray:arguments];
            } else {
                success = [db executeUpdate:sql];
            }
            
            if (!success) {
                SQLExecuteFailModel *failModel;
                if ([db hadError]) {
                    failModel = [[SQLExecuteFailModel alloc] initWithCode:[db lastErrorCode] msg:[db lastErrorMessage]];
                }
                
                // 回归主线程下回调finish block
                dispatch_async(dispatch_get_main_queue(), ^{
                    run_block_if_exist(finish, success, nil, failModel);
                });
                
                if (self.autoRollBackWhenError) {
                    *rollback = YES;
                }
                return ;
            }
            
            // 回归主线程下回调finish block
            dispatch_async(dispatch_get_main_queue(), ^{
                run_block_if_exist(finish, success, nil, nil);
            });
        }];
    });
}

@end

@implementation SQLExecutor (CRUD)

- (void)insertInto:(NSString *)table
         keyValues:(NSDictionary *)keyValues
            finish:(SQLExecuteResultBlock)finish {
    [self insertInto:table isReplace:NO isIgnore:NO keyValues:keyValues finish:finish];
}

- (void)insertOrReplaceInto:(NSString *)table
                  keyValues:(NSDictionary *)keyValues
                     finish:(SQLExecuteResultBlock)finish {
    [self insertInto:table isReplace:YES isIgnore:NO keyValues:keyValues finish:finish];
}

- (void)insertOrIgnoreInto:(NSString *)table
                 keyValues:(NSDictionary *)keyValues
                    finish:(SQLExecuteResultBlock)finish {
    [self insertInto:table isReplace:NO isIgnore:YES keyValues:keyValues finish:finish];
}

- (void)insertInto:(NSString *)table
         isReplace:(BOOL)isReplace
          isIgnore:(BOOL)isIgnore
         keyValues:(NSDictionary *)keyValues
            finish:(SQLExecuteResultBlock)finish {
    
    NSString *sqlFormat = @"insert%@ into %@(%@) values(%@);";
    NSArray *keys = [keyValues allKeys];
    NSMutableArray *valuePlaceholders = [NSMutableArray array];
    for (NSString *key in keys) {
        [valuePlaceholders addObject:[NSString stringWithFormat:@":%@", key]];
    }
    
    NSString *replaceOfIgnoreStr = @"";
    if (isReplace) {
        replaceOfIgnoreStr = @" or replace";
    } else if (isIgnore) {
        replaceOfIgnoreStr = @" or replace";
    }
    
    NSString *sql = [NSString stringWithFormat:sqlFormat, replaceOfIgnoreStr, table, [keys componentsJoinedByString:@","], [valuePlaceholders componentsJoinedByString:@","]];
    NSLog(@"%@", sql);
    
    [self executeUpdate:sql withParameterDictionary:keyValues finish:finish];
}


- (void)update:(NSString *)table
     keyValues:(NSDictionary *)keyValues
         where:(NSString *)condition
        finish:(SQLExecuteResultBlock)finish {
    
    NSString *sqlFormat = @"update %@ set %@";
    NSArray *keys = [keyValues allKeys];
    NSMutableArray *setters = [NSMutableArray array];
    for (NSString *key in keys) {
        [setters addObject:[NSString stringWithFormat:@"%@=:%@", key, key]];
    }
    
    NSMutableString *sql = [NSMutableString stringWithFormat:sqlFormat, table, [setters componentsJoinedByString:@","]];
    
    if (condition && condition.length > 0) {
        [sql appendFormat:@" where %@", condition];
    }
    
    [sql appendString:@";"];
    NSLog(@"%@", sql);
    
    [self executeUpdate:sql withParameterDictionary:keyValues finish:finish];
}

- (void)deleteFrom:(NSString *)table
             where:(NSString *)condition
            finish:(SQLExecuteResultBlock)finish {
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from %@", table];
    
    if (condition && condition.length > 0) {
        [sql appendFormat:@" where %@;", condition];
    }
    
    NSLog(@"%@", sql);
    
    [self executeUpdate:sql finish:finish];
}

- (void)select:(NSString *)table
          keys:(NSArray *)keys
         where:(NSString *)condition
       orderBy:(NSString *)orders
        offset:(NSInteger)offset
         limit:(NSInteger)limit
        finish:(SQLExecuteResultBlock)finish {
    
    NSString *sqlFormat = @"select %@ from %@";
    NSString *keysStr = @"*";
    if (keys && keys.count > 0) {
        keysStr = [keys componentsJoinedByString:@","];
    }
    
    NSMutableString *sql = [NSMutableString stringWithFormat:sqlFormat, keysStr, table];
    
    if (condition && condition.length > 0) {
        [sql appendFormat:@" where %@", condition];
    }
    
    if (orders && orders.length > 0) {
        [sql appendFormat:@" order by %@", orders];
    }
    
    /**
     *  limit和offset的顺序不能错!!!
     */
    if (limit > 0) {
        [sql appendFormat:@" limit %ld", limit];
    }
    
    if (offset > 0) {
        [sql appendFormat:@" offset %ld", offset];
    }
    
    [sql appendString:@";"];
    NSLog(@"%@", sql);
    
    [self executeQuery:sql finish:finish];
}

@end

@implementation SQLExecutor (EasyInvoking)

- (void)update:(nonnull NSString *)table
     keyValues:(nonnull NSDictionary *)keyValues
        finish:(nullable SQLExecuteResultBlock)finish {
    [self update:table keyValues:keyValues where:nil finish:finish];
}

- (void)deleteTable:(nonnull NSString *)table
             finish:(nullable SQLExecuteResultBlock)finish {
    [self deleteFrom:table where:nil finish:finish];
}

- (void)selectAll:(nonnull NSString *)table
           finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:nil where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (void)selectAll:(nonnull NSString *)table
             keys:(nullable NSArray *)keys
           finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:keys where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (void)selectAll:(nonnull NSString *)table
          orderBy:(nullable NSString *)orders
           finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:nil where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (void)selectAll:(nonnull NSString *)table
             keys:(nullable NSArray *)keys
          orderBy:(nullable NSString *)orders
           finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:keys where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (void)select:(nonnull NSString *)table
         where:(nullable NSString *)condition
        finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:nil where:condition orderBy:nil offset:0 limit:0 finish:finish];
}

- (void)select:(nonnull NSString *)table
         where:(nullable NSString *)condition
       orderBy:(nullable NSString *)orders
        finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:nil where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (void)select:(nonnull NSString *)table
          keys:(nullable NSArray *)keys
         where:(nullable NSString *)condition
       orderBy:(nullable NSString *)orders
        finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:keys where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (void)select:(nonnull NSString *)table
         where:(nullable NSString *)condition
       orderBy:(nullable NSString *)orders
        offset:(NSInteger)offset
         limit:(NSInteger)limit
        finish:(nullable SQLExecuteResultBlock)finish {
    [self select:table keys:nil where:condition orderBy:orders offset:offset limit:limit finish:finish];
}

@end















