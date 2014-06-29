//
//  Condition.m
//  Weather
//
//  Created by HeQingbao on 14-6-28.
//  Copyright (c) 2014年 HeQingbao. All rights reserved.
//

/* 简化的JSON数据
 {
    "dt": 1384279857,
    "id": 5391959,
    "main": {
        "humidity": 69,
        "pressure": 1025,
        "temp": 62.29,
        "temp_max": 69.01,
        "temp_min": 57.2
    },
    "name": "San Francisco",
    "weather": [
        {
            "description": "haze",
            "icon": "50d",
            "id": 721,
            "main": "Haze"
        }
    ]
 }
 */

#import "Condition.h"

@implementation Condition

+ (NSDictionary *)imageMap
{
    static NSDictionary *_imageMap = nil;
    if (!_imageMap) {
        _imageMap = @{
                      @"01d" : @"weather-clear",
                      @"02d" : @"weather-few",
                      @"03d" : @"weather-few",
                      @"04d" : @"weather-broken",
                      @"09d" : @"weather-shower",
                      @"10d" : @"weather-rain",
                      @"11d" : @"weather-tstorm",
                      @"13d" : @"weather-snow",
                      @"50d" : @"weather-mist",
                      @"01n" : @"weather-moon",
                      @"02n" : @"weather-few-night",
                      @"03n" : @"weather-few-night",
                      @"04n" : @"weather-broken",
                      @"09n" : @"weather-shower",
                      @"10n" : @"weather-rain-night",
                      @"11n" : @"weather-tstorm",
                      @"13n" : @"weather-snow",
                      @"50n" : @"weather-mist",
                      };
    }
    return _imageMap;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"date": @"dt",
             @"locationName": @"name",
             @"humidity": @"main.humidity",
             @"temperature": @"main.temp",
             @"tempHigh": @"main.temp_max",
             @"tempLow": @"main.temp_min",
             @"sunrise": @"sys.sunrise",
             @"sunset": @"sys.sunset",
             @"conditionDescription": @"weather.description",
             @"condition": @"weather.main",
             @"icon": @"weather.icon",
             @"windBearing": @"wind.deg",
             @"windSpeed": @"wind.speed"
             };
}

// ******************* NSString 转 NSDate *******************
// JSON数据里面存放的dt是Unix time 的 NSInteger类型，而我们需要把它转成NSDate类型，所以需要借助于NSValueTransformer
// 语法：
// 1.类方法
// 2.方法名字以property名字开头，以JSONTransformer结尾
+ (NSValueTransformer *)dateJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        // 把字符串转成NSDate
        return [NSDate dateWithTimeIntervalSince1970:str.floatValue];
    } reverseBlock:^id(NSDate *date) {
        // 把NSDate转成字符串
        return [NSString stringWithFormat:@"%f", [date timeIntervalSince1970]];
    }];
}

+ (NSValueTransformer *)sunriseJSONTransformer
{
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)sunsetJSONTransformer
{
    return [self dateJSONTransformer];
}

// ******************* NSArray 转 NSDate *******************
// JSON里面的weather标签里面是一个数组，我们只想要数组里面的某个字符串，所以需要把NSArray转NSString
+ (NSValueTransformer *)conditionDescriptionJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSArray *array) {
        return [array firstObject];
    } reverseBlock:^id(NSString *str) {
        return @[str];
    }];
}

+ (NSValueTransformer *)conditionJSONTransformer
{
    return [self conditionDescriptionJSONTransformer];
}

+ (NSValueTransformer *)iconJSONTransformer
{
    return [self conditionDescriptionJSONTransformer];
}

// OpenWeatherAPI使用 米/秒 为单位来表示风速，这里把它转在 英里/小时
#define MPS_TO_MPH 2.23694f

+ (NSValueTransformer *)windSpeedJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSNumber *num) {
        return @(num.floatValue * MPS_TO_MPH);
    } reverseBlock:^id(NSNumber *speed) {
        return @(speed.floatValue / MPS_TO_MPH);
    }];
}

- (NSString *)imageName
{
    return [Condition imageMap][self.icon];
}

@end
