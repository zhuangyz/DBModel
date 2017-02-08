//
//  SQLExecutor.h
//  FMDBTest
//
//  Created by zyz on 16/7/6.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRUDOperation.h"
#import "NSString+SQLLink.h"
#import "NSString+SQLOrder.h"

#define run_block_if_exist(block, ...) block ? block(__VA_ARGS__) : nil

/**
 *  存放sql执行失败的失败信息
 *  errorCode 可能暂时没用到，全都是0
 */
@interface SQLExecuteFailModel : NSObject

@property (nonatomic, assign) NSInteger errorCode;

@property (nonnull, nonatomic, copy) NSString *errorMsg;

- (nonnull instancetype)initWithCode:(NSInteger)code msg:(nonnull NSString *)msg;

@end

typedef void(^SQLExecuteResultBlock)(BOOL success, _Nullable id result, SQLExecuteFailModel * _Nullable failModel);

/**
 *  执行sql语句的类
 *  必须用一个数据库文件地址来初始化类对象
 *  所有操作都在线程执行，执行完毕后在主线程回调
 */
@interface SQLExecutor : NSObject

// 当执行出现错误时自动回滚，默认YES
@property (nonatomic, assign) BOOL autoRollBackWhenError;

+ (nonnull instancetype)executorWithDBPath:(nonnull NSString *)path;

/**
 *  执行查询功能
 */
- (nonnull CRUDOperation *)executeQuery:(nonnull NSString *)sql
                                 finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  执行查询功能
 */
- (nonnull CRUDOperation *)executeQuery:(nonnull NSString *)sql
                   withArgumentsInArray:(nullable NSArray *)arguments
                                 finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  执行更新功能
 */
- (nonnull CRUDOperation *)executeUpdate:(nonnull NSString *)sql
                                  finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  执行更新功能
 */
- (nonnull CRUDOperation *)executeUpdate:(nonnull NSString *)sql
                 withParameterDictionary:(nullable NSDictionary *)arguments
                                  finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  执行更新功能
 */
- (nonnull CRUDOperation *)executeUpdate:(nonnull NSString *)sql
                    withArgumentsInArray:(nullable NSArray *)arguments
                                  finish:(nullable SQLExecuteResultBlock)finish;

@end

/**
 *  将增删改查的sql语句封装
 */
@interface SQLExecutor (CRUD)
#warning 下面注释掉的老方法都是插入一条数据的，目前看起来它们似乎完全没有价值，插入多条数据的那个方法完全可以代替它们，暂时先留着不删除
///**
// *  插入一条数据
// *
// *  @param table     表名
// *  @param keyValues 用一个字典来传递字段和字段值，key必须是数据库字段名！！！
// *  @param finish
// */
//- (nonnull CRUDOperation *)insertInto:(nonnull NSString *)table
//                            keyValues:(nonnull NSDictionary *)keyValues
//                               finish:(nullable SQLExecuteResultBlock)finish;
//
///**
// *  插入或更新一条数据
// *
// *  @param table     表名
// *  @param keyValues 用一个字典来传递字段和字段值，key必须是数据库字段名！！！
// *  @param finish
// */
//- (nonnull CRUDOperation *)insertOrReplaceInto:(nonnull NSString *)table
//                                     keyValues:(nonnull NSDictionary *)keyValues
//                                        finish:(nullable SQLExecuteResultBlock)finish;
//
///**
// *  插入或忽略一条数据
// *
// *  @param table     表名
// *  @param keyValues 用一个字典来传递字段和字段值，key必须是数据库字段名！！！
// *  @param finish
// */
//- (nonnull CRUDOperation *)insertOrIgnoreInto:(nonnull NSString *)table
//                                    keyValues:(nonnull NSDictionary *)keyValues
//                                       finish:(nullable SQLExecuteResultBlock)finish;

/**
 插入多条数据

 @param table       表名
 @param replace     如果其中一些数据是存在的，那么这些数据是否要替换
 @param ignore      如果其中一些数据存在，那么这些插入数据的操作是否要略过
 @param keys        表的字段
 @param keyValues   和其他方法的keyValues参数不同，这里是指多组keyValue，一条数据就是一组keyValue
 @param finish
 
 当replace==YES时，ignore的值将被忽略!!!
 */
- (nonnull CRUDOperation *)insertInto:(nonnull NSString *)table
                            isReplace:(BOOL)replace
                             isIgnore:(BOOL)ignore
                                 keys:(nonnull NSArray<NSString *> *)keys
                            keyValues:(nonnull NSArray<NSDictionary *> *)keyValues
                               finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  改
 *
 *  @param table     表名
 *  @param keyValues 用一个字典来传递字段和字段值，key必须是数据库字段名！！！
 *  @param condition 条件语句，可以通过分类NSString+SQLLink的方法来生成条件语句，例如[[@"a=1" and:@"b=2"] or:[@"c=1" and:@"d=2"]]
 *  @param finish    回调
 */
- (nonnull CRUDOperation *)update:(nonnull NSString *)table
                        keyValues:(nonnull NSDictionary *)keyValues
                            where:(nullable NSString *)condition
                           finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  删
 *
 *  @param table     表名
 *  @param condition 条件语句，可以通过分类NSString+SQLLink的方法来生成条件语句，例如[[@"a=1" and:@"b=2"] or:[@"c=1" and:@"d=2"]]
 *  @param finish    回调
 */
- (nonnull CRUDOperation *)deleteFrom:(nonnull NSString *)table
                                where:(nullable NSString *)condition
                               finish:(nullable SQLExecuteResultBlock)finish;

/**
 *  查
 *
 *  @param table     表名
 *  @param keys      要查找的字段，为nil或@[]时代表查找所有字段
 *  @param condition 条件语句，可以通过分类NSString+SQLLink的方法来生成条件语句，例如[[@"a=1" and:@"b=2"] or:[@"c=1" and:@"d=2"]]
 *  @param orders    排序语句，可以通过分类NSString+SQLOrder的方法来生成排序语句，例如[[NSString asc:@"name"] desc:@"time"]
 *  @param offset    偏移量
 *  @param limit     限制条数，为0时代表不做限制
 *  @param finish    回调
 */
- (nonnull CRUDOperation *)select:(nonnull NSString *)table
                             keys:(nullable NSArray *)keys
                            where:(nullable NSString *)condition
                          orderBy:(nullable NSString *)orders
                           offset:(NSUInteger)offset
                            limit:(NSUInteger)limit
                           finish:(nullable SQLExecuteResultBlock)finish;

@end

/**
 *  对原始的四个增删改查的调用方法进行简化，主要去除那些可空参数
 *  这里的select方法并没有写全，组合方式太多了，需要用到的时候再加上去吧
 */
@interface SQLExecutor (EasyInvoking)

- (nonnull CRUDOperation *)update:(nonnull NSString *)table
                        keyValues:(nonnull NSDictionary *)keyValues
                           finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)cleanTable:(nonnull NSString *)table
                               finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)selectAll:(nonnull NSString *)table
                              finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)selectAll:(nonnull NSString *)table
                                keys:(nullable NSArray *)keys
                              finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)selectAll:(nonnull NSString *)table
                             orderBy:(nullable NSString *)orders
                              finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)selectAll:(nonnull NSString *)table
                                keys:(nullable NSArray *)keys
                             orderBy:(nullable NSString *)orders
                              finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)select:(nonnull NSString *)table
                            where:(nullable NSString *)condition
                           finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)select:(nonnull NSString *)table
                            where:(nullable NSString *)condition
                          orderBy:(nullable NSString *)orders
                           finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)select:(nonnull NSString *)table
                             keys:(nullable NSArray *)keys
                            where:(nullable NSString *)condition
                          orderBy:(nullable NSString *)orders
                           finish:(nullable SQLExecuteResultBlock)finish;

- (nonnull CRUDOperation *)select:(nonnull NSString *)table
                            where:(nullable NSString *)condition
                          orderBy:(nullable NSString *)orders
                           offset:(NSUInteger)offset
                            limit:(NSUInteger)limit
                           finish:(nullable SQLExecuteResultBlock)finish;

@end

















