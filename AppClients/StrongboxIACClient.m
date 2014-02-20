//
//  StrongboxACClient.m
//  Strongbox
//
//  Created by Paulo Andrade on 18/02/14.
//  Copyright (c) 2014 Maracujja. All rights reserved.
//

#import "StrongboxIACClient.h"

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
    [self performAction:@"search" parameters:@{@"q":searchString?:@""}
              onSuccess:onSuccess onFailure:onError];
}

@end
