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

@end
