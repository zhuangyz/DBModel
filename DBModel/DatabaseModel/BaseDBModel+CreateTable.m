//
//  BaseDBModel+CreateTable.m
//  FMDBTest
//
//  Created by zyz on 16/7/4.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel+CreateTable.h"
@implementation BaseDBModel (CreateTable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (NSString *)customCreateTableSQL {
    return nil;
}

+ (NSString *)easyCreateTableSQL {
    NSString *createSQLFormat = @"CREATE TABLE IF NOT EXISTS %@(%@);";
    NSString *tableName = [[self class] tableName];
    
    NSArray *keys = [[self class] allKeys];
    NSDictionary *keysType = [[self class] keysType];
    NSArray *primaryKeys = [[self class] primaryKeys];
    NSArray *autoIncrementKeys = [[self class] autoIncrementKeys];
    NSArray *notNullKeys = [[self class] notNullKeys];
    NSArray *uniqueKeys = [[self class] uniqueKeys];
    NSDictionary *defaultValueForKeys = [[self class] defaultValueForKeys];
    
    //字段属性字典，key-value -> id-id integer not null
    NSMutableDictionary *keysFeatures = [NSMutableDictionary dictionary];
    // 先用字段-字段来初始化这个字段属性字典
    for (NSString *key in keys) {
        [keysFeatures setObject:key forKey:key];
    }
    
    // 添加字段类型
    for (NSString *key in keysType.allKeys) {
        NSString *type = keysType[key];
        if (keysFeatures[key]) {
            [keysFeatures setObject:[NSString stringWithFormat:@"%@ %@", keysFeatures[key], type] forKey:key];
        }
    }
    
    // 添加自增字段
    for (NSString *key in autoIncrementKeys) {
        if (keysFeatures[key]) {
            // 在sqlite中，当某个字段为整型，并且是主键时，它将自动创建为自增，这时不能再为该字段声明为自增!!!
            if ([[keysType[key] uppercaseString] isEqualToString:@"INTEGER"] &&
                [primaryKeys containsObject:key]) {
                continue;
            }
            [keysFeatures setObject:[NSString stringWithFormat:@"%@ %@", keysFeatures[key], @"AUTOINCREMENT"] forKey:key];
        }
    }
    
    // 添加不可空字段
    for (NSString *key in notNullKeys) {
        if (keysFeatures[key]) {
            [keysFeatures setObject:[NSString stringWithFormat:@"%@ %@", keysFeatures[key], @"NOT NULL"] forKey:key];
        }
    }
    
    // 添加唯一值字段
    for (NSString *key in uniqueKeys) {
        if (keysFeatures[key]) {
            [keysFeatures setObject:[NSString stringWithFormat:@"%@ %@", keysFeatures[key], @"UNIQUE"] forKey:key];
        }
    }
    
    // 设置默认值
    for (NSString *key in defaultValueForKeys.allKeys) {
        if (keysFeatures[key]) {
            [keysFeatures setObject:[NSString stringWithFormat:@"%@ DEFAULT %@", keysFeatures[key], defaultValueForKeys[key]] forKey:key];
        }
    }
    
    // 去除无效的主键key
    NSMutableArray *validPrimaryKeys = [NSMutableArray arrayWithArray:primaryKeys];
    for (NSString *key in validPrimaryKeys) {
        if (!keysFeatures[key]) {
            [validPrimaryKeys removeObject:key];
        }
    }
    // 设置主键的sql子语句
    NSString *primaryKeysStr = @"";
    if (validPrimaryKeys.count > 0) {
        primaryKeysStr = [NSString stringWithFormat:@"PRIMARY KEY (%@)", [validPrimaryKeys componentsJoinedByString:@","]];
    }
    
    // 将设置后的字段属性拼接起来
    NSString *keysFeaturesStr = [keysFeatures.allValues componentsJoinedByString:@", "];
    
    // 生成最终的建表sql语句，这里需要将设置主键的语句和字段属性语句拼接起来
    NSString *createTableSQL = [NSString stringWithFormat:createSQLFormat, tableName, [NSString stringWithFormat:@"%@, %@", keysFeaturesStr, primaryKeysStr]];
    
    return createTableSQL;
}

+ (NSString *)tableName {
    return NSStringFromClass([self class]);
}

// 所有字段，默认返回所有数值型、文本型的属性名
+ (NSArray<NSString *> *)allKeys {
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:[self class]];
    NSMutableArray *properties = [NSMutableArray array];
    
    // 只提取数值型、文本型的属性
    for (NSString *property in classInfo.propertyInfos.allKeys) {
        YYClassPropertyInfo *propertyInfo = classInfo.propertyInfos[property];
        NSString *type = getSQLiteFieldType(propertyInfo);
        if (![type isEqualToString:@""]) {
            [properties addObject:property];
        }
    }
    
//    if (classInfo.superCls != [BaseDBModel class] && [classInfo.superCls isSubclassOfClass:[BaseDBModel class]]) {
//        [properties addObjectsFromArray:[classInfo.superCls addKeys]];
//    }
    
    return properties;
}

// 字段对应的model属性，默认allKeys对应所有属性名
+ (NSDictionary<NSString *, NSString *> *)keyOfProperty {
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:[self class]];
    NSArray<NSString *> *properties = classInfo.propertyInfos.allKeys;
    
    NSMutableDictionary *keyOfProperty = [NSMutableDictionary dictionary];
    for (NSString *property in properties) {
        [keyOfProperty setObject:property forKey:property];
    }
    
    return keyOfProperty;
}

// 字段类型，默认根据属性类型自动判断
+ (NSDictionary<NSString *, NSString *> *)keysType {
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:[self class]];
    NSDictionary *keyOfProperty = [[self class] keyOfProperty];
    
    NSMutableDictionary *keysType = [NSMutableDictionary dictionary];
    for (NSString *key in keyOfProperty.allKeys) {
        NSString *property = keyOfProperty[key];
        YYClassPropertyInfo *propertyInfo = classInfo.propertyInfos[property];
        NSString *type = getSQLiteFieldType(propertyInfo);
        
        [keysType setObject:type forKey:key];
    }
    
    return keysType;
}

// 提供主键的字段，默认@[]
+ (NSArray<NSString *> *)primaryKeys {
    return @[];
}

// 提供自增的字段，默认@[]
+ (NSArray<NSString *> *)autoIncrementKeys {
    return @[];
}

// 提供不可空字段，默认@[]
+ (NSArray<NSString *> *)notNullKeys {
    return @[];
}

// 提供唯一值字段，默认@[]
+ (NSArray<NSString *> *)uniqueKeys {
    return @[];
}

// 提供默认值字段，key为字段名，value为默认值，默认返回@{}
+ (NSDictionary<NSString *, id> *)defaultValueForKeys {
    return @{};
}

@end
#pragma clang diagnostic pop

NSString *getSQLiteFieldType(YYClassPropertyInfo *propertyInfo) {
    YYEncodingType encodingType = propertyInfo.type & 0xFF;
    NSString *type = nil;
    
    switch (encodingType) {
        case YYEncodingTypeBool:
        case YYEncodingTypeInt8:
        case YYEncodingTypeInt16:
        case YYEncodingTypeInt32:
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt8:
        case YYEncodingTypeUInt16:
        case YYEncodingTypeUInt32:
        case YYEncodingTypeUInt64: {
            type = @"INTEGER";
            break;
        }
        case YYEncodingTypeFloat:
        case YYEncodingTypeDouble:
        case YYEncodingTypeLongDouble: {
            type = @"REAL";
            break;
        }
        default:
            break;
    }
    
    if (!type) {
        type = getTypeWithPropertyClazz(propertyInfo.cls);
    }
    
    if (!type) {
        type = @"";
    }
    
    return type;
}

NSString *getTypeWithPropertyClazz(Class propertyClazz) {
    if ([propertyClazz isSubclassOfClass:[NSString class]]) {
        return @"TEXT";
    }
    if ([propertyClazz isSubclassOfClass:[NSNumber class]]) {
        return @"INTEGER";
    }
    return nil;
}

/**
 *
    每个存放在sqlite数据库中（或者由这个数据库引擎操作）的值都有下面中的一个存储类：
    NULL，值是NULL
    INTEGER，值是有符号整形，根据值的大小以1,2,3,4,6或8字节存放
    REAL，值是浮点型值，以8字节IEEE浮点数存放
    TEXT，值是文本字符串，使用数据库编码（UTF-8，UTF-16BE或者UTF-16LE）存放
    BLOB，只是一个数据块，完全按照输入存放（即没有准换）
 */





