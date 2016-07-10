//
//  NSString+SQLLink.m
//  FMDBTest
//
//  Created by zyz on 16/7/5.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "NSString+SQLLink.h"

@implementation NSString (SQLLink)

- (NSString *)and:(NSString *)anotherCondition {
    if (self.length == 0) {
        return [NSString stringWithFormat:@"%@", anotherCondition];
    }
    return [NSString stringWithFormat:@"(%@ and %@)", self, anotherCondition];
}

- (NSString *)or:(NSString *)anotherCondition {
    if (self.length == 0) {
        return [NSString stringWithFormat:@"%@", anotherCondition];
    }
    return [NSString stringWithFormat:@"(%@ or %@)", self, anotherCondition];
}

@end
