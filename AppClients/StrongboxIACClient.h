//
//  StrongboxACClient.h
//  Strongbox
//
//  Created by Paulo Andrade on 18/02/14.
//  Copyright (c) 2014 Maracujja. All rights reserved.
//

#import "IACClient.h"

@interface StrongboxIACClient : IACClient

- (void)search:(NSString *)searchString;
- (void)search:(NSString *)searchString onSuccess:(void(^)(NSDictionary*))onSuccess onFailure:(void(^)(NSError*))onFailure;

@end
