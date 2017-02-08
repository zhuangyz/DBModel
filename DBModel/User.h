//
//  User.h
//  DB_Model
//
//  Created by zyz on 16/7/10.
//  Copyright © 2016年 zyz. All rights reserved.
//

#import "BaseDBModel.h"

@interface User : BaseDBModel

@property (nonatomic, assign) NSInteger userId;

@property (nonatomic, copy) NSString *userName;

@property (nonatomic, copy) NSString *mobile;

@property (nonatomic, assign) NSInteger age;

// 可空字段
@property (nonatomic, copy) NSString *address;
// 非数据库字段相关的属性
@property (nonatomic, assign) NSInteger state;

@property (nonatomic, assign) float weight;

@end
