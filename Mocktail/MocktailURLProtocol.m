//
//  MocktailURLProtocol.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "MocktailURLProtocol.h"
#import "Mocktail_Private.h"
#import "MocktailResponse.h"


@interface MocktailURLProtocol ()

@property BOOL canceled;

@end


@implementation MocktailURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return !![Mocktail mockResponseForURL:request.URL method:request.HTTPMethod mocktail:NULL];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;
{
    return NO;
}

- (void)startLoading;
{
    NSLog(@"mocking %@ %@", self.request.URL, self.request.HTTPMethod);

    Mocktail *mocktail;
    MocktailResponse *response = [Mocktail mockResponseForURL:self.request.URL method:self.request.HTTPMethod mocktail:&mocktail];
    NSAssert(response, @"Expected valid mock response");
    NSData *body = [response bodyWithValues:mocktail.placeholderValues];

    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:response.statusCode HTTPVersion:@"1.1" headerFields:response.headers];
    [self.client URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    
    dispatch_block_t sendResponse = ^{
        if (!self.canceled) {
            [self.client URLProtocol:self didLoadData:body];
            [self.client URLProtocolDidFinishLoading:self];
        }
    };
    if (mocktail.networkDelay == 0.0) {
        sendResponse();
    } else {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, mocktail.networkDelay * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), sendResponse);
    }
}

- (void)stopLoading;
{
    self.canceled = YES;
}


@end
