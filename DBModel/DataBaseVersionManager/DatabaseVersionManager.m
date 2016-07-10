//
//  DBVersionManager.m
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "DatabaseVersionManager.h"

#define kMigrationTableName @"_version_migrations_"

@interface DatabaseVersionManager ()

@property (nonatomic, strong, readwrite) FMDatabase *database;

// 版本更新对象，已排序的
@property (nonatomic, strong, readwrite) NSArray<id<DBVersionMigrating>> *migrations;

// 版本更新对象，没有排序的
@property (nonatomic, strong) NSMutableArray<id<DBVersionMigrating>> *unorderedMigartions;

@end

@implementation DatabaseVersionManager

- (void)dealloc {
    if (self.autoCloseDBWhenDealloc) {
        [self.database close];
//        NSLog(@"%@ database closed", self.class);
    }
}

+ (instancetype)managerWithDBPath:(NSString *)dbPath {
    FMDatabase *database = [[FMDatabase alloc] initWithPath:dbPath];
    return [[self alloc] initWithDatabase:database];
}

+ (instancetype)managerWithDatabase:(FMDatabase *)database {
    return [[self alloc] initWithDatabase:database];
}

- (instancetype)initWithDatabase:(FMDatabase *)database {
    NSAssert(database != nil, @"%@ %@ database is nil", self.class, NSStringFromSelector(_cmd));
    if (self = [super init]) {
        self.database = database;
        self.unorderedMigartions = [NSMutableArray array];
        if (!database.goodConnection) {
            self.autoCloseDBWhenDealloc = YES;
            [database open];
        }
        [self createMigrationTableIfNeeded];
    }
    return self;
}

- (BOOL)hasMigrationTable {
    FMResultSet *rs = [self.database executeQuery:@"SELECT name FROM sqlite_master WHERE type='table' AND name=?", kMigrationTableName];
    if ([rs next]) {
        [rs close];
        return YES;
    }
    return NO;
}

- (void)createMigrationTableIfNeeded {
    if ([self hasMigrationTable]) return;
    
    BOOL success = [self.database executeUpdate:[NSString stringWithFormat:@"create table %@(version integer unique not null)", kMigrationTableName]];
    NSAssert(success, @"%@ %@ can not create %@ table", self.class, NSStringFromSelector(_cmd), kMigrationTableName);
}

- (uint64_t)lastVersion {
    uint64_t version = 0;
    FMResultSet *rs = [self.database executeQuery:[NSString stringWithFormat:@"select max(version) from %@", kMigrationTableName]];
    if ([rs next]) {
        version = [rs unsignedLongLongIntForColumnIndex:0];
    }
    [rs close];
    return version;
}

- (uint64_t)originVersion {
    uint64_t version = 0;
    FMResultSet *rs = [self.database executeQuery:[NSString stringWithFormat:@"select min(version) from %@", kMigrationTableName]];
    if ([rs next]) {
        version = [rs unsignedLongLongIntForColumnIndex:0];
    }
    [rs close];
    return version;
}

- (NSArray<NSNumber *> *)appliedVersions {
    NSMutableArray *versions = [NSMutableArray array];
    FMResultSet *rs = [self.database executeQuery:[NSString stringWithFormat:@"select version from %@", kMigrationTableName]];
    while ([rs next]) {
        uint64_t version = [rs unsignedLongLongIntForColumnIndex:0];
        [versions addObject:@(version)];
    }
    [rs close];
    return [versions sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<NSNumber *> *)pendingVersions {
    NSMutableArray *pendingVersions = [[self.migrations valueForKey:@"version"] mutableCopy];
    [pendingVersions removeObjectsInArray:self.appliedVersions];
    return [pendingVersions sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<id<DBVersionMigrating>> *)migrations {
    if (!_migrations) {
        _migrations = [self.unorderedMigartions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"version" ascending:YES]]];
    }
    return _migrations;
}

- (void)addMigrations:(NSArray<id<DBVersionMigrating>> *)migrations {
    for (id<NSObject> migration in migrations) {
        if ([migration conformsToProtocol:@protocol(DBVersionMigrating)]) {
            [self.unorderedMigartions addObject:(id<DBVersionMigrating>)migration];
        } else {
            NSLog(@"migration<%@> does not comform DBVersionMigrating protocol", migration);
        }
    }
    self.migrations = [self.unorderedMigartions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"version" ascending:YES]]];
}

- (void)addMigration:(id<DBVersionMigrating>)migration {
    NSAssert(migration != nil, @"%@ %@ migration is nil", self.class, NSStringFromSelector(_cmd));
    [self addMigrations:@[migration]];
}

- (void)updateDatabaseToVersion:(uint64_t)version finish:(void (^)(BOOL))finish {
    BOOL success = YES;
    // 待更新版本号，已排序
    NSArray *pendingVersions = self.pendingVersions;
    for (NSNumber *pendingVersionNumber in pendingVersions) {
        [self.database beginTransaction];
        
        uint64_t pendingVersion = [pendingVersionNumber unsignedLongLongValue];
        // 如果待更新版本号比目标版本号，停止更新（不需要更新）
        if (pendingVersion > version) {
            [self.database commit];
            break;
        }
        
        // 执行更新
        id<DBVersionMigrating> migration = [self migrationForVersion:pendingVersion];
        success = [migration updateDatabase:self.database];
        if (!success) { // 如果更新失败，取消本次更新(回滚)，并停止更新
            [self.database rollback];
            break;
        }
        
        // 更新版本表
        success = [self.database executeUpdate:[NSString stringWithFormat:@"insert into %@(version) values(?)", kMigrationTableName], @(migration.version)];
        if (!success) {
            [self.database rollback];
            break;
        }
        [self.database commit];
    }
    if (finish) {
        finish(success);
    }
}

- (id<DBVersionMigrating>)migrationForVersion:(uint64_t)version {
    for (id<DBVersionMigrating>migration in self.migrations) {
        if (migration.version == version) {
            return migration;
        }
    }
    return nil;
}

@end


















