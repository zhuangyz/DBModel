//
//  NSString+SQLOrder.m
//  FMDBTest
//
//  Created by zyz on 16/7/5.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "NSString+SQLOrder.h"

@implementation NSString (SQLOrder)

// 升序
+ (NSString *)asc:(NSString *)key {
    return [@"" asc:key];
}

- (NSString *)asc:(NSString *)key {
    NSMutableString *ascStr = [NSMutableString stringWithString:self];
    if (![self isEqualToString:@""]) {
        [ascStr appendString:@", "];
    }
    [ascStr appendFormat:@"%@ asc", key];
    return ascStr;
}

// 降序
+ (NSString *)desc:(NSString *)key {
    return [@"" desc:key];
}

- (NSString *)desc:(NSString *)key {
    NSMutableString *descStr = [NSMutableString stringWithString:self];
    if (![self isEqualToString:@""]) {
        [descStr appendString:@", "];
    }
    [descStr appendFormat:@"%@ desc", key];
    
    return descStr;
}

@end
