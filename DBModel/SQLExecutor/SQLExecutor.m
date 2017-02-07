//
//  SQLExecutor.m
//  FMDBTest
//
//  Created by zyz on 16/7/6.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "SQLExecutor.h"
#import <FMDB.h>
#import "CRUDOperationQueue.h"

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
    SQLExecutor *executor = [[SQLExecutor alloc] init];
    executor.dbPath = path;
    NSURL *pathUrl = [NSURL URLWithString:path];
    executor.executeQueue = [[self class] getExecuteQueue:[pathUrl lastPathComponent]];
    executor.dbQueue = [[self class] getFMDBQueue:path];
    
    return executor;
}

// 每个数据库都有且仅有一个队列
+ (CRUDOperationQueue *)getExecuteQueue:(NSString *)DBFileName {
    // 每个数据库对应一个队列，并将队列保存起来，所以即使不同的SQLExecutor对象，只要数据库是同一个，就还是使用同一个
    static NSMutableDictionary<NSString *, CRUDOperationQueue *> *queues = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queues = [NSMutableDictionary dictionary];
    });
    
    CRUDOperationQueue *queue = queues[DBFileName];
    if (!queue) {
        NSString *queueLabel = [NSString stringWithFormat:@"com.sql_executor_queue.%@", DBFileName];
        queue = [[CRUDOperationQueue alloc] init];
        queue.name = queueLabel;
        
        queues[DBFileName] = queue;
    }
    return queues[DBFileName];
}

// 该方法和+getExecuteQueue:是同样的目的，只是创建的是FMDB的队列
+ (FMDatabaseQueue *)getFMDBQueue:(NSString *)DBPath {
    static NSMutableDictionary<NSString *, FMDatabaseQueue *> *queues = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queues = [NSMutableDictionary dictionary];
    });
    FMDatabaseQueue *queue = queues[DBPath];
    if (!queue) {
        queue = [[FMDatabaseQueue alloc] initWithPath:DBPath];
        queues[DBPath] = queue;
    }
    return queue;
}

/**
 * 查询
 */

- (CRUDOperation *)executeQuery:(nonnull NSString *)sql
                         finish:(nullable SQLExecuteResultBlock)finish {
    
    return [self executeQuery:sql withArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeQuery:(nonnull NSString *)sql
           withArgumentsInArray:(nullable NSArray *)arguments
                         finish:(nullable SQLExecuteResultBlock)finish {
    
    CRUDOperation *operation = [CRUDOperation blockOperationWithBlock:^{
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
    }];
    [self.executeQueue addOperation:operation];
    return operation;
}

/**
 * 插入、更新、删除
 */

- (CRUDOperation *)executeUpdate:(nonnull NSString *)sql
                          finish:(nullable SQLExecuteResultBlock)finish {

    return [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeUpdate:(nonnull NSString *)sql
         withParameterDictionary:(nullable NSDictionary *)arguments
                          finish:(nullable SQLExecuteResultBlock)finish {
    
    return [self executeUpdate:sql withParameterDictionary:arguments orWithArgumentsInArray:nil finish:finish];
}

- (CRUDOperation *)executeUpdate:(nonnull NSString *)sql
            withArgumentsInArray:(nullable NSArray *)arguments
                          finish:(nullable SQLExecuteResultBlock)finish {
    
    return [self executeUpdate:sql withParameterDictionary:nil orWithArgumentsInArray:arguments finish:finish];
}

- (CRUDOperation *)executeUpdate:(nonnull NSString *)sql
         withParameterDictionary:(nullable NSDictionary *)params
          orWithArgumentsInArray:(nullable NSArray *)arguments
                          finish:(nullable SQLExecuteResultBlock)finish {
    
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

- (CRUDOperation *)insertInto:(NSString *)table
                    keyValues:(NSDictionary *)keyValues
                       finish:(SQLExecuteResultBlock)finish {
    return [self insertInto:table isReplace:NO isIgnore:NO keyValues:keyValues finish:finish];
}

- (CRUDOperation *)insertOrReplaceInto:(NSString *)table
                             keyValues:(NSDictionary *)keyValues
                                finish:(SQLExecuteResultBlock)finish {
    return [self insertInto:table isReplace:YES isIgnore:NO keyValues:keyValues finish:finish];
}

- (CRUDOperation *)insertOrIgnoreInto:(NSString *)table
                            keyValues:(NSDictionary *)keyValues
                               finish:(SQLExecuteResultBlock)finish {
    return [self insertInto:table isReplace:NO isIgnore:YES keyValues:keyValues finish:finish];
}

- (CRUDOperation *)insertInto:(NSString *)table
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
        replaceOfIgnoreStr = @" or ignore";
    }
    
    NSString *sql = [NSString stringWithFormat:sqlFormat, replaceOfIgnoreStr, table, [keys componentsJoinedByString:@","], [valuePlaceholders componentsJoinedByString:@","]];
//    NSLog(@"%@", sql);
    
    return [self executeUpdate:sql withParameterDictionary:keyValues finish:finish];
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

- (CRUDOperation *)update:(nonnull NSString *)table
                keyValues:(nonnull NSDictionary *)keyValues
                   finish:(nullable SQLExecuteResultBlock)finish {
    return [self update:table keyValues:keyValues where:nil finish:finish];
}

- (CRUDOperation *)deleteTable:(nonnull NSString *)table
                        finish:(nullable SQLExecuteResultBlock)finish {
    return [self deleteFrom:table where:nil finish:finish];
}

- (CRUDOperation *)selectAll:(nonnull NSString *)table
                      finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(nonnull NSString *)table
                        keys:(nullable NSArray *)keys
                      finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:nil orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(nonnull NSString *)table
                     orderBy:(nullable NSString *)orders
                      finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)selectAll:(nonnull NSString *)table
                        keys:(nullable NSArray *)keys
                     orderBy:(nullable NSString *)orders
                      finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:nil orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(nonnull NSString *)table
                    where:(nullable NSString *)condition
                   finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:nil offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(nonnull NSString *)table
                    where:(nullable NSString *)condition
                  orderBy:(nullable NSString *)orders
                   finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(nonnull NSString *)table
                     keys:(nullable NSArray *)keys
                    where:(nullable NSString *)condition
                  orderBy:(nullable NSString *)orders
                   finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:keys where:condition orderBy:orders offset:0 limit:0 finish:finish];
}

- (CRUDOperation *)select:(nonnull NSString *)table
                    where:(nullable NSString *)condition
                  orderBy:(nullable NSString *)orders
                   offset:(NSUInteger)offset
                    limit:(NSUInteger)limit
                   finish:(nullable SQLExecuteResultBlock)finish {
    return [self select:table keys:nil where:condition orderBy:orders offset:offset limit:limit finish:finish];
}

@end















