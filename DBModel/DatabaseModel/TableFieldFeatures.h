//
//  TableFieldFeatures.h
//  FMDBTest
//
//  Created by zyz on 16/7/6.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TableFieldFeatures <NSObject>

// 所有字段
+ (NSArray<NSString *> *)allKeys;

// 字段对应的model属性
+ (NSDictionary<NSString *, NSString *> *)keyOfProperty;

// 字段类型
+ (NSDictionary<NSString *, NSString *> *)keysType;

// 提供主键的字段
+ (NSArray<NSString *> *)primaryKeys;

// 提供自增的字段
+ (NSArray<NSString *> *)autoIncrementKeys;

// 提供不可空字段
+ (NSArray<NSString *> *)notNullKeys;

// 提供唯一值字段
+ (NSArray<NSString *> *)uniqueKeys;

// 提供默认值字段，key为字段名，value为默认值
+ (NSDictionary<NSString *, id> *)defaultValueForKeys;

@end
