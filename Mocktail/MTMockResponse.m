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

#pragma mark - Public Methods

- (NSData *)augmentedResponseData:(NSData *)response;
{
    return response;
}

@end
