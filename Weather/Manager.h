//
//  Manager.h
//  Weather
//
//  Created by HeQingbao on 14-6-28.
//  Copyright (c) 2014年 HeQingbao. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
#import <ReactiveCocoa.h>

// 注意没有import DailyForecast类，将总是使用Condition作为天气类。
// DailyForecast的存在仅仅是帮助Mantle转化json到OC对象
#import "Condition.h"

@interface Manager : NSObject<CLLocationManagerDelegate>

// 使用instancetype代替Manager,如此子类将返回适当的类型。
+(instancetype)sharedManager;

// 这些属性将存储你的数据。
// 因为此类是个单例，这些属性在任何地方都可以被访问，将公共属性设置为只读的，因为只有Manager应该私下更改这些值
@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) Condition *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

// 这个方法开始或刷新整个位置和天气的发现过程。
- (void)findCurrentLocation;

@end
