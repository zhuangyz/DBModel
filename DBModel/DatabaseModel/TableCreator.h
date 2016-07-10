//
//  TableCreator.h
//  FMDBTest
//
//  Created by zyz on 16/7/4.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableFieldFeatures.h"

// 还要考虑方法是否需要共有
@protocol TableCreator <TableFieldFeatures>

// 自定义建表语句，可以用来直接编写比较复杂的建表语句
+ (NSString *)customCreateTableSQL;

// 格式化建表语句
+ (NSString *)easyCreateTableSQL;

// 表名
+ (NSString *)tableName;

@end

















