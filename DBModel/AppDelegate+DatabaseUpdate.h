//
//  AppDelegate+DatabaseUpdate.h
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "AppDelegate.h"

// 建议数据库版本更新写到AppDelegate的分类里，容易管理一些，像这个分类这样
// 例外，建议更早的执行更新
@interface AppDelegate (DatabaseUpdate)

- (void)updateDatabaseIfNeeded;

@end



