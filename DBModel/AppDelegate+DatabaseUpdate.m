//
//  AppDelegate+DatabaseUpdate.m
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "AppDelegate+DatabaseUpdate.h"
#import "DatabaseVersionManager.h"
#import "DatabaseConstants.h"
#import "DBVersionMigration1.h"
#import "DBVersionMigration2.h"

@implementation AppDelegate (DatabaseUpdate)

- (void)updateDatabaseIfNeeded {
    DatabaseVersionManager *manager = [DatabaseVersionManager managerWithDBPath:kDatabasePath];
    [manager addMigrations:[self allMigrations]];
    [manager updateDatabaseToVersion:2 finish:^(BOOL success) {
        NSLog(@"更新%@", success?@"成功":@"失败");
    }];
}

- (NSArray<BaseDBVersionMigration *> *)allMigrations {
    return @[
             [[DBVersionMigration1 alloc] init],
             [[DBVersionMigration2 alloc] init],
             ];
}

@end
