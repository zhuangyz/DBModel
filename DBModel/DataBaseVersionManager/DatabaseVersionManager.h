//
//  DBVersionManager.h
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

// 版本更新
// 仿照FMDBMigrationManager实现
// https://github.com/layerhq/FMDBMigrationManager

// 暂时作为独立的模块，所有更新操作都在主线程执行，
// 如果和SQLExecutor一起用，需要考虑调用顺序的问题，避免同时操作数据库，
// （建议在AppDelegate中的-application:didFinishLaunchingWithOptions:方法里尽早调用更新方法），
// 后面考虑要不要把SQLExecutor引用进来，提高安全性。

#import <Foundation/Foundation.h>
#import "FMDB.h"

@protocol DBVersionMigrating;

@interface DatabaseVersionManager : NSObject

+ (instancetype)managerWithDBPath:(NSString *)dbPath;

+ (instancetype)managerWithDatabase:(FMDatabase *)database;

@property (nonatomic, readonly) FMDatabase *database;

// 对象销毁时是否自动关闭database，默认yes
@property (nonatomic, assign) BOOL autoCloseDBWhenDealloc;

// 当前最新的版本
@property (nonatomic, readonly) uint64_t lastVersion;

// 最初的版本
@property (nonatomic, readonly) uint64_t originVersion;

// 已更新的版本
@property (nonatomic, readonly) NSArray<NSNumber *> *appliedVersions;

// 未更新的版本
@property (nonatomic, readonly) NSArray<NSNumber *> *pendingVersions;

// 所有的版本更新
@property (nonatomic, readonly) NSArray<id<DBVersionMigrating>> *migrations;

- (void)addMigration:(id<DBVersionMigrating>)migration;

- (void)addMigrations:(NSArray<id<DBVersionMigrating>> *)migrations;

// 将数据库更新至version版本（在主线程上调用该方法）
- (void)updateDatabaseToVersion:(uint64_t)version finish:(void(^)(BOOL success))finish;

@end

// 版本更新协议
// 每个版本更新都要实现该协议
@protocol DBVersionMigrating <NSObject>

@optional
// 版本描述
@property (nonatomic, readonly) NSString *versionDescription;

@required
// 本次更新的版本号
@property (nonatomic, readonly) uint64_t version;

// 更新操作，返回结果为更新是否成功
- (BOOL)updateDatabase:(FMDatabase *)database;

@end

















