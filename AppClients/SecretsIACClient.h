//
//  SecretsACClient.h
//  Secrets
//
//  Created by Paulo Andrade on 18/02/14.
//  Copyright (c) 2014 Maracujja. All rights reserved.
//

#import "IACClient.h"

extern NSString *SecretsIACParameterSearchString;
extern NSString *SecretsIACParameterTarget;
extern NSString *SecretsIACParameterOnBehalfOf;

@interface SecretsIACClient : IACClient

- (void)search:(NSString *)searchString;
- (void)search:(NSString *)searchString onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onFailure;
- (void)search:(NSString *)searchString target:(NSString *)target onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onFailure;
- (void)search:(NSString *)searchString target:(NSString *)target options:(NSDictionary *)options onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onFailure;

@end
