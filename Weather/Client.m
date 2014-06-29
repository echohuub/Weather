//
//  Client.m
//  Weather
//
//  Created by HeQingbao on 14-6-28.
//  Copyright (c) 2014年 HeQingbao. All rights reserved.
//

#import "Client.h"
#import "Condition.h"
#import "DailyForecast.h"

#define BASE_URL @"http://api.openweathermap.org/data/2.5/"

@interface Client ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation Client

- (id)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url
{
    NSLog(@"Fetching: %@", url.absoluteString);
    
    // 返回信号。这个信号不会执行，直到它被订阅
    // 返回一个信号给其它对象或方法使用
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 通过url从网络取得数据
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Handle retrieved data
            if (!error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (!jsonError) {
                    // 没有错误，向订阅者发送序列化的array或dictionary
                    [subscriber sendNext:json];
                } else {
                    // 有错误，提醒订阅者
                    [subscriber sendError:jsonError];
                }
            } else {
                // 有错误，提醒订阅者
                [subscriber sendError:error];
            }
            // 提醒订阅者请求完成
            [subscriber sendCompleted];
        }];
        
        // 一旦有人订阅这个信号就开始网络请求
        [dataTask resume];
        
        // 创建并返回一个RACDisosable对象，当信号被销毁的时候执行一些清理操作
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"%@weather?lat=%f&lon=%f&units=metric&lang=zh", BASE_URL, coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 使用上面创建的信号，映射返回值（NSDictionary）到一个不同的值
    return [[self fetchJSONFromURL:url] map:^id(NSDictionary *json) {
        // 使用MTLJSONAdapter把json对象转换成Condition对象。根据Condition所实现的MTLJSONSerializing协议方法
        return [MTLJSONAdapter modelOfClass:[Condition class] fromJSONDictionary:json error:nil];
    }];
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"%@forecast?lat=%f&lon=%f&units=metric&cnt=12&lang=zh", BASE_URL, coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    return [[self fetchJSONFromURL:url] map:^id(NSDictionary *json) {
        // 根据json里面的list标签构建一个RACSequence对象
        // RACSequence让你在列表上面执行多个操作
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // 映射一个新的列表对象，对list中的每个对象调用map方法。返回一个新的对象列表
        return [[list map:^id(NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[Condition class] fromJSONDictionary:item error:nil];
            
            // 对RACSequence使用map将返回另外一个RACSequence，使用这个方便的方法得到一个NSArray数据
        }] array];
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"%@forecast/daily?lat=%f&lon=%f&units=metric&cnt=12&lang=zh", BASE_URL, coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    return [[self fetchJSONFromURL:url] map:^id(NSDictionary *json) {
        RACSequence *list = [json[@"list"] rac_sequence];
        
        return [[list map:^id(NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[DailyForecast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}

@end
