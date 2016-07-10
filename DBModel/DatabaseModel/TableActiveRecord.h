//
//  TableActiveRecord.h
//  FMDBTest
//
//  Created by zyz on 16/7/7.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLExecutor.h"

// 更新操作完成的block，参数failModel仅在执行出错时不为空
typedef void(^UpdateFinishBlock)(SQLExecuteFailModel *failModel);

// 查询操作完成的block，参数models不为空，但可能为空数组，参数failModel仅在执行出错时不为空
typedef void(^QueryFinishBlock)(NSArray *models, SQLExecuteFailModel *failModel);

// 声明model增删改查操作方法的
@protocol TableActiveRecord <NSObject>

// 创建或更新 NSArray<BaseDBModel *> *
+ (void)save:(NSArray *)models
      finish:(UpdateFinishBlock)finish;

// 删除models NSArray<BaseDBModel *> *
+ (void)delete:(NSArray *)models
        finish:(UpdateFinishBlock)finish;

// 清空表
+ (void)deleteAll:(UpdateFinishBlock)finish;

/**
 *  查询
 */
+ (void)findAll:(QueryFinishBlock)finish;

+ (void)findAllWithOrder:(NSString *)order
                  finish:(QueryFinishBlock)finish;

+ (void)findWhere:(NSString *)condition
           finish:(QueryFinishBlock)finish;

+ (void)findWhere:(NSString *)condition
            order:(NSString *)order
           finish:(QueryFinishBlock)finish;

+ (void)findWhere:(NSString *)condition
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish;

+ (void)findWhere:(NSString *)condition
           offset:(NSInteger)offset
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish;

+ (void)findWhere:(NSString *)condition
            order:(NSString *)order
           offset:(NSInteger)offset
            limit:(NSInteger)limit
           finish:(QueryFinishBlock)finish;

// 数量
+ (void)count:(void(^)(NSInteger count))finish;

+ (void)countWhere:(NSString *)condition
            finish:(void(^)(NSInteger count))finish;

@end
