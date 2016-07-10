//
//  BaseDBVersionMigration.m
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBVersionMigration.h"

@implementation BaseDBVersionMigration

- (uint64_t)version {
    NSAssert(false, @"%@ should implemente %@", self.class, NSStringFromSelector(_cmd));
    return 0;
}

- (BOOL)updateDatabase:(FMDatabase *)database {
    NSLog(@"%@ should implemente %@", self.class, NSStringFromSelector(_cmd));
    return NO;
}

- (NSString *)versionDescription {
    return @"";
}

@end
