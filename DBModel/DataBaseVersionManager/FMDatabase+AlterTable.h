//
//  FMDatabase+AlterTable.h
//  DBModel
//
//  Created by Walker on 2017/2/8.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import "FMDatabase.h"

// 添加字段等操作
@interface FMDatabase (AlterTable)

- (BOOL)safeAddColumn:(nonnull NSString *)columnName
              toTable:(nonnull NSString *)table
             dataType:(nonnull NSString *)type
            allowNULL:(BOOL)allowNull
        autoIncrement:(BOOL)autoIncrement
             isUnique:(BOOL)isUnique
         defaultValue:(nullable NSString *)defaultValue;

@end
