//
//  CRUDOperationQueue.m
//  DBModel
//
//  Created by Walker on 2017/2/6.
//  Copyright © 2017年 zyz. All rights reserved.
//

#import "CRUDOperationQueue.h"

@implementation CRUDOperationQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    [super setMaxConcurrentOperationCount:1];
}

@end
