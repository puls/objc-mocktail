//
//  MTMockResponse.m
//  Mocktail
//
//  Created by Kyle Van Essen on 2013-02-07.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import "MTMockResponse.h"


@interface MTMockResponse ()
@end


@implementation MTMockResponse

#pragma mark - Class Methods

+ (instancetype)mockResponse;
{
    return [[self alloc] init];
}

+ (instancetype)mockResponseWithContentsOfURL:(NSURL *)URL;
{
    return nil;
}

+ (NSArray *)mockResponsesWithContentsOfDirectoryAtURL:(NSURL *)directoryURL;
{
    return nil;
}

+ (instancetype)mockResponseForURL:(NSURL *)URL HTTPRequestMethod:(NSString *)requestMethod;
{
    NSArray *responses = [self mockResponsesForURL:URL HTTPRequestMethod:requestMethod];

    return (responses.count ? [responses objectAtIndex:0] : nil);
}

+ (NSArray *)mockResponsesForURL:(NSURL *)URL HTTPRequestMethod:(NSString *)requestMethod;
{
    NSMutableArray *responses = [NSMutableArray array];

    NSString *URLString = URL.absoluteString;

    for (MTMockResponse *response in [self allMockResponses]) {
        if ([response.URL.absoluteString isEqual:URLString]) {
            [responses addObject:response];
        } else if ([response.URLRegularExpression rangeOfFirstMatchInString:URLString options:0 range:NSMakeRange(0, URLString.length)].length > 0) {
            [responses addObject:response];
        } else if ([response canUseWithURL:URL]) {
            [responses addObject:response];
        }
    }

    return [responses copy];
}

+ (NSMutableArray *)allMockResponses;
{
    static NSMutableArray *allMockResponses = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allMockResponses = [[NSMutableArray alloc] init];
    });

    return allMockResponses;
}

#pragma mark - Public Methods

- (void)augmentResponseBody:(NSMutableData *)responseBody;
{
    // For subclasses.
}

- (void)augmentResponseHeaders:(NSMutableDictionary *)responseHeaders;
{
    // For subclasses.    
}

- (BOOL)canUseWithURL:(NSURL *)URL;
{
    return NO;
}

@end
