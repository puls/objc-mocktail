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
    return !![Mocktail mockResponseForURL:request.URL method:request.HTTPMethod];
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
    
    MocktailResponse *response = [Mocktail mockResponseForURL:self.request.URL method:self.request.HTTPMethod];
    Mocktail *mocktail = response.mocktail;
    NSAssert(response, @"Expected valid mock response");
    NSData *body = [NSData dataWithContentsOfURL:response.fileURL];
    body = [body subdataWithRange:NSMakeRange(response.bodyOffset, body.length - response.bodyOffset)];
    
    // Replace placeholders with values. We transform the body data into a string for easier search and replace.
    NSDictionary *placeholderValues = mocktail.placeholderValues;
    if ([placeholderValues count] > 0) {
        NSMutableString *bodyString = [[NSMutableString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        BOOL didReplace = NO;
        for (NSString *placeholder in placeholderValues) {
            NSString *value = [placeholderValues objectForKey:placeholder];
            NSString *placeholderFormat = [NSString stringWithFormat:@"{{ %@ }}", placeholder];
            
            if ([bodyString replaceOccurrencesOfString:placeholderFormat withString:value options:NSLiteralSearch range:NSMakeRange(0, [bodyString length])] > 0) {
                didReplace = YES;
            }
        }
        
        if (didReplace) {
            body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
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
