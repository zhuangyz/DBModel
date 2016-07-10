//
//  NSString+SQLLink.h
//  FMDBTest
//
//  Created by zyz on 16/7/5.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SQLLink)

- (NSString *)and:(NSString *)anotherCondition;

- (NSString *)or:(NSString *)anotherCondition;

@end
