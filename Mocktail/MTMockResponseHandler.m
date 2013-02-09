//
//  MTMockResponseHandler.m
//  Mocktail
//
//  Created by Kyle Van Essen on 2/9/13.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import "MTMockResponseHandler.h"
#import "MTMockResponse.h"
#import "MTMockURLProtocol.h"


@interface MTMockResponseHandler () <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, retain, readwrite) MTMockResponse *mockResponse;
@property (nonatomic, retain, readwrite) MTMockURLProtocol *mockURLProtocol;

@property (nonatomic, retain) NSURLConnection *URLConnection;

@property (nonatomic, retain) NSMutableData *URLConnectionResponseData;
@property (nonatomic, retain) NSError *URLConnectionError;
@property (nonatomic, retain) NSHTTPURLResponse *URLConnectionResponse;

- (void)_performFinishLoading;

@end


@implementation MTMockResponseHandler

#pragma mark - Class Methods

+ (instancetype)responseHandlerWithMockResponse:(MTMockResponse *)mockResponse mockURLProtocol:(MTMockURLProtocol *)mockURLProtocol;
{
    if (!mockResponse || !mockURLProtocol) {
        return nil;
    }

    MTMockResponseHandler *handler = [[self alloc] init];
    handler.mockResponse = mockResponse;
    handler.mockURLProtocol = mockURLProtocol;

    return handler;
}

#pragma mark - Initialization

- (id)init;
{
    self = [super init];

    if (!self) {
        return nil;
    }

    _URLConnectionResponseData = [[NSMutableData alloc] init];

    return self;
}

#pragma mark - Public Methods

- (void)startLoadingMockResponse;
{
    if (self.mockResponse.fetchesResponsesFromRealEndpoint) {
        self.URLConnection = [NSURLConnection connectionWithRequest:self.mockURLProtocol.request delegate:self];

        [self.URLConnection start];
    } else {
        self.URLConnectionError = self.mockResponse.HTTPError;
        self.URLConnectionResponseData = [NSMutableData dataWithData:self.mockResponse.defaultResponseBody];

        NSURL *URL = self.mockURLProtocol.request.URL;
        NSInteger statusCode = (self.mockResponse.HTTPError ? self.mockResponse.HTTPError.code : self.mockResponse.HTTPStatusCode);
        
        self.URLConnectionResponse = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:self.mockResponse.defaultResponseHeaders];

        [self performSelector:@selector(_performFinishLoading) withObject:nil afterDelay:self.mockResponse.responseLatency];
    }
}

- (void)stopLoadingMockResponse;
{
    [self.URLConnection cancel];
    
    self.URLConnection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    self.URLConnectionError = error;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
{
    return YES;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
{
    self.URLConnectionResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    [self.URLConnectionResponseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    [self _performFinishLoading];
}

#pragma mark - Private Methods

- (void)_augmentData;
{
    [self.mockResponse augmentResponseBody:self.URLConnectionResponseData];

    NSMutableDictionary *augmentedResponseHeaders = [NSMutableDictionary dictionaryWithDictionary:self.URLConnectionResponse.allHeaderFields];
    [self.mockResponse augmentResponseHeaders:augmentedResponseHeaders];

    NSURL *URL = self.URLConnectionResponse.URL;
    NSInteger statusCode = self.URLConnectionResponse.statusCode;
    self.URLConnectionResponse = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:augmentedResponseHeaders];
}

- (void)_performFinishLoading;
{
    [self _augmentData];

    if (self.URLConnectionError) {
        [self.mockURLProtocol.client URLProtocol:self.mockURLProtocol didFailWithError:self.URLConnectionError];
    } else {
        [self.mockURLProtocol.client URLProtocol:self.mockURLProtocol didReceiveResponse:self.URLConnectionResponse cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
        [self.mockURLProtocol.client URLProtocol:self.mockURLProtocol didLoadData:self.URLConnectionResponseData];
    }

    [self.mockURLProtocol.client URLProtocolDidFinishLoading:self.mockURLProtocol];
}

@end
