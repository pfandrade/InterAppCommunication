//
//  IACManager.m
//  IACSample
//
//  Created by Antonio Cabezuelo Vivo on 09/02/13.
//  Copyright (c) 2013 Antonio Cabezuelo Vivo. All rights reserved.
//

#import "IACManager.h"
#import "IACDelegate.h"
#import "IACClient.h"
#import "IACRequest.h"


#if !__has_feature(objc_arc)
#error InterAppComutication must be built with ARC.
// You can turn on ARC for only InterAppComutication files by adding -fobjc-arc to the build phase for each of its files.
#endif


NSString * const IACErrorDomain       = @"com.iac.manager.error";
NSString * const IACClientErrorDomain = @"com.iac.client.error";

// x-callback-url strings
static NSString * const kXCUPrefix        = @"x-";
static NSString * const kXCUHost          = @"x-callback-url";
static NSString * const kXCUSource        = @"x-source";
static NSString * const kXCUSuccess       = @"x-success";
static NSString * const kXCUError         = @"x-error";
static NSString * const kXCUCancel        = @"x-cancel";
static NSString * const kXCUErrorCode     = @"error-Code";
static NSString * const kXCUErrorMessage  = @"errorMessage";

// IAC strings
static NSString * const kIACPrefix       = @"IAC";
static NSString * const kIACResponse     = @"IACRequestResponse";
static NSString * const kIACRequest      = @"IACRequestID";
static NSString * const kIACResponseType = @"IACResponseType";
static NSString * const kIACErrorDomain  = @"errorDomain";

typedef NS_ENUM(NSUInteger, IACResponseType) {
    IACResponseTypeSuccess,
    IACResponseTypeFailure,
    IACResponseTypeCancel
};


@implementation IACManager {
    NSMutableDictionary *sessions;
    NSMutableDictionary *actions;
}

+ (IACManager*)sharedManager {
    static IACManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        sessions = [NSMutableDictionary dictionary];
        actions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)handleOpenURL:(NSURL*)url {
    // An app can respond to multiple url schemes and the app can use different IACManagers for each one
    // so we test if the url is handled by this manager
    if (![url.scheme isEqualToString:self.callbackURLScheme]) {
        return NO;
    }
    
    // If the url is an x-callback-url compatible url we handle it
    if ([url.host isEqualToString:kXCUHost]) {
        NSString     *action     = [[url pathComponents] count] > 1 ? [url pathComponents][1] : @"";
        NSDictionary *parameters = [self paramsFromURL:url];

        NSDictionary *actionParamters = [self removeProtocolParamsFromDictionary:parameters];
        
        
        // Lets see if this is a response to a previous call
        if ([action isEqualToString:kIACResponse]) {
            NSString *requestID = parameters[kIACRequest];
            
            IACRequest *request = sessions[requestID];
            if (request) {
                IACResponseType responseType = [parameters[kIACResponseType] intValue];
            
                switch (responseType) {
                    case IACResponseTypeSuccess:
                        if (request.successCalback) {
                            request.successCalback(actionParamters);
                        }
                        break;
                        
                    case IACResponseTypeFailure:
                        if (request.errorCalback) {
                            NSInteger errorCode = [request.client NSErrorCodeForXCUErrorCode:parameters[kXCUErrorCode]];
                            NSString *errorDomain = parameters[kIACErrorDomain] ? parameters[kIACErrorDomain] : IACClientErrorDomain;
                            NSError *error = [NSError errorWithDomain:errorDomain
                                                                 code:errorCode
                                                             userInfo:@{NSLocalizedDescriptionKey: parameters[kXCUErrorMessage]}];
                            
                            request.errorCalback(error);
                        }
                        break;
                        
                    case IACResponseTypeCancel:
                        if (request.successCalback) {
                            request.successCalback(nil);
                        }
                        break;
                        
                    default:
                        [sessions removeObjectForKey:requestID];
                        return NO;
                        break;
                }
            
                [sessions removeObjectForKey:requestID];
                return YES;
            }
            
            return NO;
        }
        
        // Lets see if there is somebody that handles this action
        if (actions[action] || [self.delegate supportsIACAction:action]) {
        
            IACSuccessBlock success = NULL;
            
            if ([parameters[kXCUSuccess] length] > 0 || [parameters[kXCUCancel] length] > 0) {
                success = ^(NSDictionary *returnParams, BOOL cancelled) {
                    if (cancelled) {
                        if (parameters[kXCUCancel]) {
                            [self openURL:[NSURL URLWithString:parameters[kXCUCancel]]];
                        }
                    } else if (parameters[kXCUSuccess]) {
                        NSURL *url = [self URLByAppendingParams:returnParams toURL:[NSURL URLWithString:parameters[kXCUSuccess]]];
                        [self openURL:url];
                    }
                };
            }
            
            IACFailureBlock failure = NULL;
            if ([parameters[kXCUError] length] > 0){
                failure = ^(NSError *error) {
                    if (parameters[kXCUError]) {
                        NSDictionary *errorParams = @{ kXCUErrorCode: @([error code]),
                                                       kXCUErrorMessage: [error localizedDescription],
                                                       kIACErrorDomain: [error domain]
                                                       };
                        NSURL *url = [self URLByAppendingParams:errorParams toURL:parameters[kXCUError]];
                        [self openURL:url];
                    }
                };
            }


            // Handlers take precedence over the delegate
            if (actions[action]) {
                IACActionHandlerBlock actionHandler = actions[action];
                actionHandler(actionParamters, success, failure);
                return YES;
                
            } else if ([self.delegate supportsIACAction:action]) {
                [self.delegate performIACAction:action
                                     parameters:actionParamters
                                      onSuccess:success
                                      onFailure:failure];
                
                return YES;
            }
        } else {
            if (parameters[kXCUError]) {
                NSDictionary *errorParams = @{ kXCUErrorCode: @(IACErrorNotSupportedAction),
                                               kXCUErrorMessage: [NSString stringWithFormat:NSLocalizedString(@"'%@' is not an x-callback-url action supported by %@", nil), action, [self localizedAppName]],
                                               kIACErrorDomain: IACErrorDomain
                                             };
                NSURL *url = [self URLByAppendingParams:errorParams toURL:parameters[kXCUError]];
                [self openURL:url];
                return YES;
            }
        }
    }
    
    
    return NO;
}

- (void)sendIACRequest:(IACRequest*)request {
    
    if (![request.client isAppInstalled]) {
        if (request.errorCalback) {
            NSError *error = [NSError errorWithDomain:IACErrorDomain
                                                 code:IACErrorAppNotInstalled
                                             userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"App with scheme '%@' is not installed in this device", nil), request.client.URLScheme]}];
            request.errorCalback(error);
        }
        return;
    }
    
    
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = request.client.URLScheme;
    components.host = kXCUHost;
    components.path = [@"/" stringByAppendingString:request.action];
    
    NSURL *final_url = [components URL];
    final_url = [self URLByAppendingParams:request.parameters toURL:final_url];
    final_url = [self URLByAppendingParams:@{kXCUSource: [self localizedAppName]} toURL:final_url];
    
    if (self.callbackURLScheme) {
        components = [[NSURLComponents alloc] init];
        components.scheme = self.callbackURLScheme;
        components.host = kXCUHost;
        components.path = kIACResponse;

        NSURL *xcu = [components URL];
        xcu = [self URLByAppendingParams:@{kIACRequest:request.requestID} toURL:xcu];
        
        NSMutableDictionary *xcu_params = [NSMutableDictionary dictionary];
        
        if (request.successCalback) {
            xcu_params[kXCUSuccess] = [self URLByAppendingParams:@{kIACResponseType:@(IACResponseTypeSuccess)} toURL:xcu];
            xcu_params[kXCUCancel] = [self URLByAppendingParams:@{kIACResponseType:@(IACResponseTypeCancel)} toURL:xcu];
        }
        
        if (request.errorCalback) {
            xcu_params[kXCUError] = [self URLByAppendingParams:@{kIACResponseType:@(IACResponseTypeFailure)} toURL:xcu];
        }
        
        final_url = [self URLByAppendingParams:xcu_params toURL:final_url];
    } else if (request.successCalback || request.errorCalback) {
        NSLog(@"WARNING: If you want to support callbacks from the remote app you must define a URL Scheme for this app to listen on");
    }
        
    sessions[request.requestID] = request;
    
    [self openURL:final_url];
}


- (void)handleAction:(NSString*)action withBlock:(IACActionHandlerBlock)handler {
    actions[action] = [handler copy];
}

- (NSURL *)URLByAppendingParams:(NSDictionary *)params toURL:(NSURL *)url
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSString *queryString = urlComponents.query;
    
    NSMutableArray *paramArray = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramArray addObject:[NSString stringWithFormat:@"%@=%@", key, [self escapeURLArgument:obj]]];
    }];
    if ([queryString length] == 0) {
        queryString = [paramArray componentsJoinedByString:@"&"];
    } else {
        queryString = [queryString stringByAppendingFormat:@"&%@", [paramArray componentsJoinedByString:@"&"]];
    }
    urlComponents.query = queryString;
    return [urlComponents URL];
}

- (NSDictionary *)paramsFromURL:(NSURL *)url
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *query = components.query;

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSArray *comps = [pair componentsSeparatedByString:@"="];
        if ([comps count] == 2) {
            params[comps[0]] = [self unescapeURLArgument:comps[1]];
        }
    }];
    
    return params;
}
- (NSDictionary*)removeProtocolParamsFromDictionary:(NSDictionary*)dictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    // Removes all x-callback-url and all IAC parameters
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key hasPrefix:kXCUPrefix] && ![key hasPrefix:kIACPrefix]) {
            [result setObject:obj forKey:key];
        }
    }];
    
    // Adds x-source parameter as this is needed to inform the user
    if (dictionary[kXCUSource]) {
        result[kXCUSource] = dictionary[kXCUSource];
    }
    
    return result;
}

- (NSString*)localizedAppName {
    NSString *appname = [[NSBundle mainBundle] localizedInfoDictionary][@"CFBundleDisplayName"];
    if (!appname) {
        appname = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    }
    if (!appname) {
        appname = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }
    return appname;
}

- (void)openURL:(NSURL *)url
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] openURL:url];
#else
    [[NSWorkspace sharedWorkspace] openURL:url];
#endif
}


#pragma mark - Escaping/Unescaping URL Arguments

- (NSString *)escapeURLArgument:(NSString *)arg
{
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    CFStringRef escaped =
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (__bridge CFStringRef)arg,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *) escaped;
}

- (NSString *)unescapeURLArgument:(NSString *)arg
{
    return [arg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
