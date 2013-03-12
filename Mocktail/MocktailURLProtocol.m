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
#import "Mocktail.h"
#import "MocktailResponse.h"


@implementation MocktailURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return !![[Mocktail sharedMocktail] mockResponseForURL:request.URL method:request.HTTPMethod];
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
    
    MocktailResponse *response = [[Mocktail sharedMocktail] mockResponseForURL:self.request.URL method:self.request.HTTPMethod];
    NSAssert(response, @"Expected valid mock response");
    NSData *body = [NSData dataWithContentsOfURL:response.fileURL];
    body = [body subdataWithRange:NSMakeRange(response.bodyOffset, body.length - response.bodyOffset)];
    
    // Replace placeholders with values. We transform the body data into a string for easier search and replace.
    NSDictionary *placeholderValues = [Mocktail sharedMocktail].placeholderValues;
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
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, [Mocktail sharedMocktail].networkDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.client URLProtocol:self didLoadData:body];
        [self.client URLProtocolDidFinishLoading:self];
    });
}

- (void)stopLoading;
{
    // Mocktail "loads" requests and sends back data synchronously, so there's no point at which a request has started but hasn't finished. An implementation of this method would be meaningless.
}

@end
