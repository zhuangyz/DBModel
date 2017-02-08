//
//  DBVersionMigration2.m
//  DBModel
//
//  Created by Walker on 2017/2/8.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import "DBVersionMigration2.h"
#import "FMDatabase+AlterTable.h"

@implementation DBVersionMigration2

- (uint64_t)version {
    return 2;
}

- (BOOL)updateDatabase:(FMDatabase *)database {
    return [database safeAddColumn:@"weight"
                           toTable:@"User"
                          dataType:@"REAL"
                         allowNULL:NO
                     autoIncrement:NO
                          isUnique:NO
                      defaultValue:@"0"];
}

@end
