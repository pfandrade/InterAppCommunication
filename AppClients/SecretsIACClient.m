//
//  SecretsACClient.m
//  Secrets
//
//  Created by Paulo Andrade on 18/02/14.
//  Copyright (c) 2014 Maracujja. All rights reserved.
//

#import "SecretsIACClient.h"

NSString *SecretsIACParameterSearchString = @"q";
NSString *SecretsIACParameterTarget = @"target";
NSString *SecretsIACParameterOnBehalfOf = @"onBehalfOf";

@implementation SecretsIACClient

- (instancetype)init {
    return [self initWithURLScheme:@"secrets"];
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
    if ([searchString length] > 0) parameters[SecretsIACParameterSearchString] = searchString;
    if ([target length] > 0) parameters[SecretsIACParameterTarget] = target;
    if (options != nil)  [parameters addEntriesFromDictionary:options];
    
    [self performAction:@"search"
             parameters:parameters
              onSuccess:onSuccess
              onFailure:onError];
}
@end
