//
//  MTMockURLProtocol.m
//  Mocktail
//
//  Created by Kyle Van Essen on 2/9/13.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import "MTMockURLProtocol.h"
#import "MTMockResponse.h"
#import "MTMockResponseHandler.h"


@interface MTMockURLProtocol ()

@property (nonatomic, retain) MTMockResponseHandler *responseHandler;

@end


@implementation MTMockURLProtocol

#pragma mark - NSURLProtocol Class Methods

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return ([MTMockResponse mockResponseForURL:request.URL HTTPRequestMethod:request.HTTPMethod] != nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;
{
    return NO;
}

#pragma mark - NSURLProtocol Instance Methods

- (void)startLoading;
{
    MTMockResponse *response = [MTMockResponse mockResponseForURL:self.request.URL HTTPRequestMethod:self.request.HTTPMethod];

    self.responseHandler = [MTMockResponseHandler responseHandlerWithMockResponse:response mockURLProtocol:self];

    [self.responseHandler startLoadingMockResponse];
}

- (void)stopLoading;
{
    [self.responseHandler stopLoadingMockResponse];
    
    self.responseHandler = nil;
}

@end
