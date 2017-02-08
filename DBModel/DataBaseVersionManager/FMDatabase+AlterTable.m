//
//  FMDatabase+AlterTable.m
//  DBModel
//
//  Created by Walker on 2017/2/8.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import "FMDatabase+AlterTable.h"

@implementation FMDatabase (AlterTable)

- (BOOL)safeAddColumn:(NSString *)columnName
              toTable:(NSString *)table
             dataType:(NSString *)type
            allowNULL:(BOOL)allowNull
        autoIncrement:(BOOL)autoIncrement
             isUnique:(BOOL)isUnique
         defaultValue:(NSString *)defaultValue {
    
    FMResultSet *rs = [self executeQuery:[NSString stringWithFormat:@"select * from %@ limit 1;", table]];
    int columnCount = [rs columnCount];
    for (int i = 0; i < columnCount; i++) {
        NSString *existCol = [rs columnNameForIndex:i];
        if ([existCol isEqualToString:columnName]) {
            [rs close];
            return YES;
        }
    }
    [rs close];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"ALTER TABLE %@ ADD %@ %@", table, columnName, type];
    if (allowNull) {
        [sql appendString:@" NOT NULL"];
    }
    if (autoIncrement) {
        [sql appendString:@" AUTOINCREMENT"];
    }
    if (isUnique) {
        [sql appendString:@" UNIQUE"];
    }
    if (defaultValue && defaultValue.length > 0) {
        [sql appendFormat:@" DEFAULT %@", defaultValue];
    }
    [sql appendString:@";"];
    NSLog(@"%@", sql);
    
    return [self executeUpdate:sql];
}

@end
