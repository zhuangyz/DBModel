//
//  DatabaseConstants.h
//  FMDBTest
//
//  Created by zyz on 16/6/28.
//  Copyright © 2016年 zyz. All rights reserved.
//

#ifndef DatabaseConstants_h
#define DatabaseConstants_h

#define kDatabaseName @"database"
#define kDatabasePath \
    [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", kDatabaseName]]

#endif /* DatabaseConstants_h */
