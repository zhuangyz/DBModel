//
//  NSString+SQLCondition.h
//  DBModel
//
//  Created by Walker on 2017/2/10.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>

// 创建简单的条件语句
// 使用方法：
//  [@"id" equals:@(10)]
//  或 [@"name" equals:@"walker"]
// 注意不要带引号!!!!!!!
@interface NSString (SQLCondition)

- (NSString *)equals:(id)value;
- (NSString *)notEquals:(id)value;
- (NSString *)greaterThan:(id)value;
- (NSString *)greaterOrEquals:(id)value;
- (NSString *)lessThan:(id)value;
- (NSString *)lessOrEquals:(id)value;

@end
