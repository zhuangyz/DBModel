//
//  BaseDBModel+CreateTable.h
//  FMDBTest
//
//  Created by zyz on 16/7/4.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel.h"
#if __has_include(<YYClassInfo.h>)
#import <YYClassInfo.h>
#else
#import "YYClassInfo.h"
#endif

/**
 *  根据属性信息获取其在数据库中对应的类型，如果属性的类型不为数值型或字符串类型，则返回结果为@""
 *  整型:@"INTEGER"
    浮点型:@"REAL"
    文本型:@"TEXT"
    其他:@""
 */
NSString *getSQLiteFieldType(YYClassPropertyInfo *propertyInfo);
/**
 *  根据属性类型获取对应的数据库类型
 *  目前只有:
    NSString -> TEXT
    NSNumber -> INTEGER
 */
NSString *getTypeWithPropertyClazz(Class propertyClazz);

// 暂时不支持多层继承合并属性、不支持集合类属性自动转换!!!!
@interface BaseDBModel (CreateTable)

#pragma mark TableCreator
// 自定义建表语句，默认返回nil，当该方法返回结果不为nil时，优先使用该方法生成建表语句
+ (NSString *)customCreateTableSQL;

// 自动格式化建表语句
+ (NSString *)easyCreateTableSQL;

// 表名，默认为类名
+ (NSString *)tableName;

// 所有字段，默认返回所有数值型、文本型的属性名
+ (NSArray<NSString *> *)allKeys;

// 字段对应的model属性，默认allKeys对应所有属性名
+ (NSDictionary<NSString *, NSString *> *)keyOfProperty;

// 字段类型，默认根据属性类型自动判断
+ (NSDictionary<NSString *, NSString *> *)keysType;

// 提供主键的字段，默认@[]
+ (NSArray<NSString *> *)primaryKeys;

// 提供自增的字段，默认@[]
+ (NSArray<NSString *> *)autoIncrementKeys;

// 提供不可空字段，默认@[]
+ (NSArray<NSString *> *)notNullKeys;

// 提供唯一值字段，默认@[]
+ (NSArray<NSString *> *)uniqueKeys;

// 提供默认值字段，key为字段名，value为默认值，默认返回@{}
+ (NSDictionary<NSString *, id> *)defaultValueForKeys;

@end






