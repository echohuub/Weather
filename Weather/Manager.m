//
//  Manager.m
//  Weather
//
//  Created by HeQingbao on 14-6-28.
//  Copyright (c) 2014年 HeQingbao. All rights reserved.
//

#import "Manager.h"
#import "Client.h"
#import <TSMessage.h>

@interface Manager ()

// 声明相同的属性和公共接口,但这次声明为读写,这样你就可以在幕后改变值。
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) Condition *currentCondition;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

// 声明一些其它私有属性用来查找位置和获取数据
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) Client *client;

@end

@implementation Manager

+ (instancetype)sharedManager
{
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (id)init
{
    if (self = [super init]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _client = [[Client alloc] init];
        
        // Manager使用ReactiveCocoa宏返回的信号观察currentLocation键。这类似于KVO但是更强大。
        [[[[RACObserve(self, currentLocation)
            // 为了继续沿着链方法,currentLocation不能为零。
            ignore:nil]
           // -flattenMap:-map:非常相似,但不是每个值的映射,大众化的值,并返回一个对象包含所有三个信号。通过这种方式,您可以考虑这三个过程作为一个工作单元。
           // 当currentLocation更新的时候，flatten和订阅所有三个信号
           flattenMap:^RACStream *(CLLocation *newLocation) {
            return [RACSignal merge:@[
                                      [self updateCurrentConditions],
                                      [self updateDailyForcast],
                                      [self updateHourForecast]
                                      ]];
               // 在主线程传递信号给用户。
        }] deliverOn:RACScheduler.mainThreadScheduler]
         subscribeError:^(NSError *error) {
             // 这不是好的做法与UI交互在您的模型,但是出于演示目的你就显示一个横幅时发生错误。
            [TSMessage showNotificationWithTitle:@"Error" subtitle:@"There was a problem fetching the latest" type:TSMessageNotificationTypeError];
        }];
    }
    return self;
}

- (void)findCurrentLocation
{
    self.isFirstUpdate = YES;
    NSLog(@"开始更新位置");
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"位置请求成功");
    // 总是忽略第一个位置更新,因为它几乎总会被缓存。
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // 一旦你有了一个位置的准确性,停止进一步的更新。
    if (location.horizontalAccuracy > 0) {
        // 设置currentLocation键触发在init方法所实现的RACObservable。
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

- (RACSignal *)updateCurrentConditions
{
    NSLog(@"updateCurrentConditions");
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(Condition *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateDailyForcast
{
    NSLog(@"updateDailyForcast");
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

- (RACSignal *)updateHourForecast
{
    NSLog(@"updateHourForecast");
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

@end
