//
//  NSString+SQLOrder.h
//  FMDBTest
//
//  Created by zyz on 16/7/5.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SQLOrder)

// 升序
+ (NSString *)asc:(NSString *)key;

- (NSString *)asc:(NSString *)key;

// 降序
+ (NSString *)desc:(NSString *)key;

- (NSString *)desc:(NSString *)key;

@end
