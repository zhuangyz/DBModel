//
//  NSString+SQLCondition.m
//  DBModel
//
//  Created by Walker on 2017/2/10.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import "NSString+SQLCondition.h"

@implementation NSString (SQLCondition)

- (NSString *)equals:(id)value {
    return [NSString stringWithFormat:@"%@ = '%@'", self, value];
}

- (NSString *)notEquals:(id)value {
    return [NSString stringWithFormat:@"%@ != '%@'", self, value];
//    return [NSString stringWithFormat:@"%@ <> '%@'", self, value];
}

- (NSString *)greaterThan:(id)value {
    return [NSString stringWithFormat:@"%@ > '%@'", self, value];
}

- (NSString *)greaterOrEquals:(id)value {
    return [NSString stringWithFormat:@"%@ >= '%@'", self, value];
}

- (NSString *)lessThan:(id)value {
    return [NSString stringWithFormat:@"%@ < '%@'", self, value];
}

- (NSString *)lessOrEquals:(id)value {
    return [NSString stringWithFormat:@"%@ <= '%@'", self, value];
}

@end
