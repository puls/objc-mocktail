//
//  Mocktail.m
//  Mocktail
//
//  Created by Jim Puls on 2/7/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "Mocktail.h"

static NSString * const MocktailFileExtension = @".tail";

@interface MocktailResponse : NSObject

@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) NSInteger bodyOffset;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;

@end


@implementation MocktailResponse
@end


@implementation Mocktail

static NSMutableArray *mockReponses = nil;

#pragma mark - Mocktail

+ (void)startWithContentsOfDirectoryAtURL:(NSURL *)url;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLProtocol registerClass:[self class]];
        mockReponses = [NSMutableArray array];
    });
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:0 error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", url, error);
        return;
    }
    for (NSURL *fileURL in fileURLs) {
        NSRange fileExtenstionLocation = [[fileURL absoluteString] rangeOfString:MocktailFileExtension];
        if (fileExtenstionLocation.location != [[fileURL absoluteString] length] - [MocktailFileExtension length]) {
            continue;
        }

        NSStringEncoding originalEncoding;
        NSString *contentsOfFile = [NSString stringWithContentsOfURL:fileURL usedEncoding:&originalEncoding error:&error];
        if (error) {
            NSLog(@"Error opening %@: %@", fileURL, error);
        }
        NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
        NSString *headerMatter = nil;
        [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
        NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
        MocktailResponse *response = [MocktailResponse new];
        response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
        response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
        response.statusCode = [lines[2] integerValue];
        response.headers = @{@"Content-type":lines[3]};
        response.fileURL = fileURL;
        response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
        @synchronized(mockReponses) {
            [mockReponses addObject:response];
        }
    }
}

+ (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method;
{
    NSString *absoluteURL = [url absoluteString];
    @synchronized(mockReponses) {
        for (MocktailResponse *response in mockReponses) {
            if ([response.absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
                if ([response.methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
                    return response;
                }
            }
        }
    }
    return nil;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return !![self mockResponseForURL:request.URL method:request.HTTPMethod];
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
    MocktailResponse *response = [[self class] mockResponseForURL:self.request.URL method:self.request.HTTPMethod];
    NSData *body = [NSData dataWithContentsOfURL:response.fileURL];
    body = [body subdataWithRange:NSMakeRange(response.bodyOffset, body.length - response.bodyOffset)];
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:response.statusCode HTTPVersion:@"1.1" headerFields:response.headers];
    [self.client URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [self.client URLProtocol:self didLoadData:body];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading;
{
    // Mocktail "loads" requests and sends back data synchronously, so there's no point at which a request has started but hasn't finished. An implementation of this method would be meaningless.
}

@end
