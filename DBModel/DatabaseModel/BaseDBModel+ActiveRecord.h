//
//  BaseDBModel+ActiveRecord.h
//  FMDBTest
//
//  Created by zyz on 16/7/7.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel.h"

@interface BaseDBModel (ActiveRecord)

// 根据属性值获取对应的数据库字段和字段值
- (NSDictionary *)transformToKeyValues;

@end

















