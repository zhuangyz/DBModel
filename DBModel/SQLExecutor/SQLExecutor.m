//
//  SQLExecutor.m
//  FMDBTest
//
//  Created by zyz on 16/7/6.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "SQLExecutor.h"
#import "CRUDOperationQueue.h"

#if __has_include(<FMDB.h>)
#import <FMDB.h>
#else
#import "FMDB.h"
#endif

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

@property (nonnull, nonatomic, strong) CRUDOperationQueue *executeQueue;

@property (nonnull, nonatomic, copy) NSString *dbPath;

@property (nonnull, nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation SQLExecutor

- (void)dealloc {
    NSLog(@"%@ dealloc", self.class);
    [self.executeQueue cancelAllOperations];
    [self.dbQueue close];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.autoRollBackWhenError = YES;
    }
    return self;
}

+ (instancetype)executorWithDBPath:(NSString *)path {
    NSAssert([NSThread mainThread], @"%@ +%@ 应当运行在主线程", [self class], NSStringFromSelector(_cmd));
    NSAssert(path, @"path can not nill");
    
    static NSMutableDictionary<NSString *, SQLExecutor *> *executors = nil;
    if (!executors) {
        executors = [NSMutableDictionary dictionary];
    }
    
    SQLExecutor *executor = executors[path];
    if (!executor) {
        executor = [[SQLExecutor alloc] init];
        executor.dbPath = path;
        executor.dbQueue = [[FMDatabaseQueue alloc] initWithPath:path];
        executor.executeQueue = [[CRUDOperationQueue alloc] init];
        executor.executeQueue.name = [NSString stringWithFormat:@"com.sql_executor_queue.%@", [[[NSURL alloc] initWithString:path] lastPathComponent]];
        
        executors[path] = executor;
    }
    return executor;
}

#pragma mark 查询
- (CRUDOperation *)executeQuery:(NSString *)sql
                         finish:(SQLExecuteResultBlock)finish {
    
    return [self executeQuery:sql withParameterDictionary:nil orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeQuery:(NSString *)sql
                withParameterDictionary:(NSDictionary *)params
                                 finish:(SQLExecuteResultBlock)finish {
    
    return [self executeQuery:sql withParameterDictionary:params orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeQuery:(NSString *)sql
           withArgumentsInArray:(NSArray *)arguments
                         finish:(SQLExecuteResultBlock)finish {
    
    return [self executeQuery:sql withParameterDictionary:nil orWithArgumentsInArray:arguments finish:finish];
}

- (CRUDOperation *)executeQuery:(NSString *)sql
        withParameterDictionary:(NSDictionary *)params
         orWithArgumentsInArray:(NSArray *)arguments
                         finish:(SQLExecuteResultBlock)finish {
    
    CRUDOperation *operation = [CRUDOperation blockOperationWithBlock:^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableArray *result = [NSMutableArray array];
            FMResultSet *rs;
            if (params) {
                rs = [db executeQuery:sql withParameterDictionary:params];
            } else if (arguments) {
                rs = [db executeQuery:sql withArgumentsInArray:arguments];
            } else {
                rs = [db executeQuery:sql];
            }
            
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
    }];
    [self.executeQueue addOperation:operation];
    return operation;
}

#pragma mark 插入、更新、删除
- (CRUDOperation *)executeUpdate:(NSString *)sql
                          finish:(SQLExecuteResultBlock)finish {

    return [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeUpdate:(NSString *)sql
         withParameterDictionary:(NSDictionary *)params
                          finish:(SQLExecuteResultBlock)finish {
    
    return [self executeUpdate:sql withParameterDictionary:params orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeUpdate:(NSString *)sql
            withArgumentsInArray:(NSArray *)arguments
                          finish:(SQLExecuteResultBlock)finish {
    
    return [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:arguments finish:finish];
}

- (CRUDOperation *)executeUpdate:(NSString *)sql
         withParameterDictionary:(NSDictionary *)params
          orWithArgumentsInArray:(NSArray *)arguments
                          finish:(SQLExecuteResultBlock)finish {
    
    CRUDOperation *operation = [CRUDOperation blockOperationWithBlock:^{
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
    }];
    [self.executeQueue addOperation:operation];
    return operation;
}

@end

@implementation SQLExecutor (CRUD)

//- (CRUDOperation *)insertInto:(NSString *)table
//                    keyValues:(NSDictionary *)keyValues
//                       finish:(SQLExecuteResultBlock)finish {
//    return [self insertInto:table isReplace:NO isIgnore:NO keyValues:keyValues finish:finish];
//}
//
//- (CRUDOperation *)insertOrReplaceInto:(NSString *)table
//                             keyValues:(NSDictionary *)keyValues
//                                finish:(SQLExecuteResultBlock)finish {
//    return [self insertInto:table isReplace:YES isIgnore:NO keyValues:keyValues finish:finish];
//}
//
//- (CRUDOperation *)insertOrIgnoreInto:(NSString *)table
//                            keyValues:(NSDictionary *)keyValues
//                               finish:(SQLExecuteResultBlock)finish {
//    return [self insertInto:table isReplace:NO isIgnore:YES keyValues:keyValues finish:finish];
//}
//
//- (CRUDOperation *)insertInto:(NSString *)table
//                    isReplace:(BOOL)isReplace
//                     isIgnore:(BOOL)isIgnore
//                    keyValues:(NSDictionary *)keyValues
//                       finish:(SQLExecuteResultBlock)finish {
//    
//    NSString *sqlFormat = @"insert%@ into %@(%@) values(%@);";
//    NSArray *keys = [keyValues allKeys];
//    NSMutableArray *valuePlaceholders = [NSMutableArray array];
//    for (NSString *key in keys) {
//        [valuePlaceholders addObject:[NSString stringWithFormat:@":%@", key]];
//    }
//    
//    NSString *replaceOfIgnoreStr = @"";
//    if (isReplace) {
//        replaceOfIgnoreStr = @" or replace";
//    } else if (isIgnore) {
//        replaceOfIgnoreStr = @" or ignore";
//    }
//    
//    NSString *sql = [NSString stringWithFormat:sqlFormat, replaceOfIgnoreStr, table, [keys componentsJoinedByString:@","], [valuePlaceholders componentsJoinedByString:@","]];
////    NSLog(@"%@", sql);
//    
//    return [self executeUpdate:sql withParameterDictionary:keyValues finish:finish];
//}

- (CRUDOperation *)insertInto:(NSString *)table
                    isReplace:(BOOL)replace
                     isIgnore:(BOOL)ignore
                         keys:(NSArray<NSString *> *)keys
                    keyValues:(NSArray<NSDictionary *> *)keyValues
                       finish:(SQLExecuteResultBlock)finish {
    NSAssert(keys.count > 0, @"%@ -%@ keys不能为空", self.class, NSStringFromSelector(_cmd));
    
    NSMutableString *sql = [NSMutableString stringWithString:@"insert "];
    if (replace) {
        [sql appendString:@"or replace "];
    } else if (ignore) {
        [sql appendString:@"or ignore "];
    }
    [sql appendString:[NSString stringWithFormat:@"into %@(%@) values", table, [keys componentsJoinedByString:@","]]];
    
    for (NSDictionary *keyValue in keyValues) {
        NSMutableString *valueStr = [[NSMutableString alloc] initWithString:@"("];
        for (NSString *key in keys) {
            if (keyValue[key]) {
                [valueStr appendFormat:@"'%@',", keyValue[key]];
            } else {
                [valueStr appendString:@"NULL,"];
            }
        }
        [valueStr replaceCharactersInRange:NSMakeRange(valueStr.length - 1, 1) withString:@"),"];
        [sql appendString:valueStr];
    }
    
    [sql replaceCharactersInRange:NSMakeRange(sql.length - 1, 1) withString:@";"];
//    NSLog(@"%@", sql);
    
    return [self executeUpdate:sql finish:finish];
}

- (CRUDOperation *)update:(NSString *)table
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
//    NSLog(@"%@", sql);
    
    return [self executeUpdate:sql withParameterDictionary:keyValues finish:finish];
}

- (CRUDOperation *)deleteFrom:(NSString *)table
                        where:(NSString *)condition
                       finish:(SQLExecuteResultBlock)finish {
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from %@", table];
    
    if (condition && condition.length > 0) {
        [sql appendFormat:@" where %@;", condition];
    }
    
//    NSLog(@"%@", sql);
    
    return [self executeUpdate:sql finish:finish];
}

- (CRUDOperation *)select:(NSString *)table
                     keys:(NSArray *)keys
                    where:(NSString *)condition
                  orderBy:(NSString *)orders
                   offset:(NSUInteger)offset
                    limit:(NSUInteger)limit
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
//    NSLog(@"%@", sql);
    
    return [self executeQuery:sql finish:finish];
}

@end

@implementation SQLExecutor (EasyInvoking)

- (CRUDOperation *)update:(NSString *)table
                keyValues:(NSDictionary *)keyValues
                   finish:(SQLExecuteResultBlock)finish {
    return [self update:table keyValues:keyValues where:nil finish:finish];
}

- (CRUDOperation *)cleanTable:(NSString *)table
                       finish:(SQLExecuteResultBlock)finish {
    return [self deleteFrom:table where:nil finish:finish];
}

- (CRUDOperation *)selectAll:(NSString *)table
                      finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(NSString *)table
                        keys:(NSArray *)keys
                      finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(NSString *)table
                     orderBy:(NSString *)orders
                      finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(NSString *)table
                        keys:(NSArray *)keys
                     orderBy:(NSString *)orders
                      finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(NSString *)table
                    where:(NSString *)condition
                   finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(NSString *)table
                    where:(NSString *)condition
                  orderBy:(NSString *)orders
                   finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(NSString *)table
                     keys:(NSArray *)keys
                    where:(NSString *)condition
                  orderBy:(NSString *)orders
                   finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(NSString *)table
                    where:(NSString *)condition
                  orderBy:(NSString *)orders
                   offset:(NSUInteger)offset
                    limit:(NSUInteger)limit
                   finish:(SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:orders offset:offset limit:limit finish:finish];
}

@end















