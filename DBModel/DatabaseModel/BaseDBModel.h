//
//  BaseDBModel.h
//  FMDBTest
//
//  Created by zyz on 16/7/4.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLExecutor.h"
#import "TableCreator.h"
#import "TableActiveRecord.h"
#import "DatabaseConstants.h"

@interface BaseDBModel : NSObject <TableFieldFeatures, TableCreator, TableActiveRecord>

+ (SQLExecutor *)executor;

// 返回该model的表所属的数据库
+ (NSString *)databasePath;

@end
