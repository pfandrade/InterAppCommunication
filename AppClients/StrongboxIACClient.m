//
//  SecretsACClient.m
//  Secrets
//
//  Created by Paulo Andrade on 18/02/14.
//  Copyright (c) 2014 Maracujja. All rights reserved.
//

#import "StrongboxIACClient.h"

NSString *StrongboxIACParameterSearchString = @"q";
NSString *StrongboxIACParameterTarget = @"target";
NSString *StrongboxIACParameterOnBehalfOf = @"onBehalfOf";

@implementation StrongboxIACClient

- (instancetype)init {
    return [self initWithURLScheme:@"strongbox"];
}

- (void)search:(NSString *)searchString
{
    [self search:searchString onSuccess:NULL onFailure:NULL];
}

- (void)search:(NSString *)searchString onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onError
{
    [self search:searchString target:nil onSuccess:onSuccess onFailure:onError];
}

- (void)search:(NSString *)searchString target:(NSString *)target onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onError
{
    [self search:searchString target:target options:nil onSuccess:onSuccess onFailure:onError];
}

- (void)search:(NSString *)searchString target:(NSString *)target options:(NSDictionary *)options onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onError
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([searchString length] > 0) parameters[StrongboxIACParameterSearchString] = searchString;
    if ([target length] > 0) parameters[StrongboxIACParameterTarget] = target;
    if (options != nil)  [parameters addEntriesFromDictionary:options];
    
    [self performAction:@"search"
             parameters:parameters
              onSuccess:onSuccess
              onFailure:onError];
}
@end
