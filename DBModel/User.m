//
//  User.m
//  DB_Model
//
//  Created by zyz on 16/7/10.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "User.h"

@implementation User

#pragma mark TableCreator

// 所有字段，默认返回所有数值型、文本型的属性名
+ (NSArray<NSString *> *)allKeys {
    return @[
             @"user_id",
             @"user_name",
             @"mobile",
             @"age",
             ];
}

// 字段对应的model属性
+ (NSDictionary<NSString *, NSString *> *)keyOfProperty {
    return @{
             @"user_id":@"userId",
             @"user_name":@"userName",
             @"age":@"age",
             @"mobile":@"mobile",
             };
}

// 提供主键的字段
+ (NSArray<NSString *> *)primaryKeys {
    return @[@"user_id"];
}

// 提供不可空字段
+ (NSArray<NSString *> *)notNullKeys {
    return @[
             @"user_name",
             @"mobile",
             ];
}

// 提供唯一值字段
+ (NSArray<NSString *> *)uniqueKeys {
    return @[
             @"mobile",
             ];
}

// 提供默认值字段，key为字段名，value为默认值
+ (NSDictionary<NSString *, id> *)defaultValueForKeys {
    return @{
             @"age":@(0),
             };
}

@end
