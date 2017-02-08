//
//  BaseDBModel+ActiveRecord.m
//  FMDBTest
//
//  Created by zyz on 16/7/7.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel+ActiveRecord.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation BaseDBModel (ActiveRecord)

- (NSDictionary *)transformToKeyValues {
    NSMutableDictionary *keyValues = [NSMutableDictionary dictionary];
    
    NSArray *allKeys = [[self class] allKeys];
    NSDictionary *keyOfProperty = [[self class] keyOfProperty];
    
    // 取出字段值
    for (NSString *key in keyOfProperty.allKeys) {
        if ([allKeys containsObject:key]) {
            NSString *property = keyOfProperty[key];
            id value = [self valueForKey:property];
            if (value) {
                [keyValues setObject:value forKey:key];
            }
        }
    }
    
    NSArray *notNullKeys = [[self class] notNullKeys];
    NSDictionary *defaultValueForKeys = [[self class] defaultValueForKeys];
    
    // 遍历所有字段，如果该字段没有值，并且该字段不可空但又没设置默认值，这里不做处理，只提示该字段不可空
    for (NSString *key in allKeys) {
        if (!keyValues[key]) {
            if ([notNullKeys containsObject:key] && !defaultValueForKeys[key]) {
                NSLog(@"%@ 字段%@不可空！！！", [self class], key);
            }
        }
    }
    
    return keyValues;
}

// 创建或更新
+ (void)save:(NSArray<BaseDBModel *> *)models
      finish:(UpdateFinishBlock)finish {
    NSAssert(models, @"%@ -%@ models can't nil", [self class], NSStringFromSelector(_cmd));
    if (models.count == 0) {
        run_block_if_exist(finish, nil);
        NSLog(@"没有数据需要插入数据库");
    }
    
    NSMutableArray *keyValues = [NSMutableArray array];
    for (BaseDBModel *model in models) {
        [keyValues addObject:[model transformToKeyValues]];
    }
    [[[self class] executor] insertInto:[[self class] tableName]
                              isReplace:YES
                               isIgnore:NO
                                   keys:[[self class] allKeys]
                              keyValues:keyValues
                                 finish:^(BOOL success, id  _Nullable result, SQLExecuteFailModel * _Nullable failModel) {
                                     run_block_if_exist(finish, failModel);
                                 }];
}

// 删除models
+ (void)delete:(NSArray<BaseDBModel *> *)models
        finish:(UpdateFinishBlock)finish {
    NSAssert(models, @"%@ -%@ models can't nil", [self class], NSStringFromSelector(_cmd));
    if (models.count == 0) {
        run_block_if_exist(finish, nil);
        NSLog(@"没有数据需要删除");
    }
    
    NSMutableArray<NSString *> *wheres = [NSMutableArray array];
    
    NSArray *primaryKeys = [[self class] primaryKeys];
    NSArray *allKeys = [[self class] allKeys];
    
    for (BaseDBModel *model in models) {
        NSDictionary *keyValues = [model transformToKeyValues];
        NSString *where = @"";
        
        if (primaryKeys.count > 0) {
            // 如果有主键，使where为主键=主键值
            for (NSString *primaryKey in primaryKeys) {
                id value = keyValues[primaryKey];
                where = [where and:[NSString stringWithFormat:@"%@=%@", primaryKey, value]];
            }
        } else {
            // 如果没有主键，使where为所有字段=它们的值
            for (NSString *key in allKeys) {
                if (keyValues[key]) {
                    where = [where and:[NSString stringWithFormat:@"%@=%@", key, keyValues[key]]];
                } else {
                    where = [where and:[NSString stringWithFormat:@"%@=NULL", key]];
                }
            }
        }
        [wheres addObject:[NSString stringWithFormat:@"(%@)", where]];
    }
    
    NSString *condition = [wheres componentsJoinedByString:@" or "];
    
    [[[self class] executor] deleteFrom:[[self class] tableName] where:condition finish:^(BOOL success, id  _Nullable result, SQLExecuteFailModel * _Nullable failModel) {
        run_block_if_exist(finish, failModel);
    }];
}

// 清空表
+ (void)deleteAll:(UpdateFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] cleanTable:table finish:^(BOOL success, id result, SQLExecuteFailModel *failModel) {
        run_block_if_exist(finish, failModel);
    }];
}

/**
 *  查询
 */
// 生成一个model，并且根据字段值，给model赋值
+ (BaseDBModel *)createModelWithKeyValues:(NSDictionary *)keyValues {
    BaseDBModel *model = [[[self class] alloc] init];
    
    NSArray *allKeys = [[self class] allKeys];
    NSDictionary *keyOfProperty = [[self class] keyOfProperty];
    
    for (NSString *key in allKeys) {
        NSString *property = keyOfProperty[key];
        if ([keyValues[key] isKindOfClass:[NSNull class]]) {
            continue;
        }
        [model setValue:keyValues[key] forKey:property];
    }
    
    return model;
}

+ (NSArray<BaseDBModel *> *)transformKeyValuesToModels:(NSArray<NSDictionary *> *)response {
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *keyValues in response) {
        BaseDBModel *model = [[self class] createModelWithKeyValues:keyValues];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

+ (void)findAll:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] selectAll:table
                                finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findAllWithOrder:(NSString *)order
                  finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] selectAll:table
                               orderBy:order
                                finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findWhere:(NSString *)condition
           finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] select:table
                              where:condition
                             finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findWhere:(NSString *)condition
            order:(NSString *)order
           finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] select:table
                              where:condition
                            orderBy:order
                             finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findWhere:(NSString *)condition
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] select:table
                              where:condition
                            orderBy:nil
                             offset:0
                              limit:limit
                             finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findWhere:(NSString *)condition
           offset:(NSInteger)offset
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] select:table
                              where:condition
                            orderBy:nil
                             offset:offset
                              limit:limit
                             finish:^(BOOL success, id result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

+ (void)findWhere:(NSString *)condition
            order:(NSString *)order
           offset:(NSInteger)offset
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish {
    NSString *table = [[self class] tableName];
    [[[self class] executor] select:table
                              where:condition
                            orderBy:order
                             offset:offset
                              limit:limit
                             finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSArray *models = [[self class] transformKeyValuesToModels:result];
        run_block_if_exist(finish, models, failModel);
    }];
}

// 数量
+ (void)count:(void(^)(NSInteger count))finish {
    NSString *table = [[self class] tableName];
    NSString *sql = [NSString stringWithFormat:@"select COUNT(*) as count from %@", table];
    [[[self class] executor] executeQuery:sql
                                   finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
        NSDictionary *keyValues = [result firstObject];
        NSInteger count = [keyValues[@"count"] integerValue];
        run_block_if_exist(finish, count);
    }];
}

+ (void)countWhere:(NSString *)condition
            finish:(void(^)(NSInteger count))finish {
    if (!condition || condition.length == 0) {
        [[self class] count:finish];
        return;
    }
    
    NSString *table = [[self class] tableName];
    NSString *sql = [NSString stringWithFormat:@"select COUNT(*) as count from %@ where %@", table, condition];
    [[[self class] executor] executeQuery:sql
                                   finish:^(BOOL success, NSArray *result, SQLExecuteFailModel *failModel) {
       NSDictionary *keyValues = [result firstObject];
       NSInteger count = [keyValues[@"count"] integerValue];
       run_block_if_exist(finish, count);
   }];
}

@end
#pragma clang diagnostic pop























