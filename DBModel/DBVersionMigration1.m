//
//  DBVersionMigration1.m
//  DB_Model
//
//  Created by zyz on 16/7/11.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "DBVersionMigration1.h"
#import "User.h"

@implementation DBVersionMigration1

- (uint64_t)version {
    return 1;
}

- (NSString *)versionDescription {
    return @"数据库版本1";
}

- (BOOL)updateDatabase:(FMDatabase *)database {
    NSLog(@"%@", [self versionDescription]);
    [[User alloc] init];
    return YES;
}

@end
