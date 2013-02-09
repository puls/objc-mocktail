//
//  MTMockResponse.h
//  Mocktail
//
//  Created by Kyle Van Essen on 2013-02-07.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 */
@interface MTMockResponse : NSObject

///
/// @name HTTP Fields
///

/**
 */
@property (nonatomic, copy) NSData *defaultResponseBody;

/**
 */
@property (nonatomic, copy) NSDictionary *defaultResponseHeaders;

/**
 */
@property (nonatomic, retain) NSError *HTTPError;

/**
 */
@property (nonatomic, copy) NSDictionary *HTTPHeaderFields;

/**
 */
@property (nonatomic, copy) NSString *HTTPRequestMethod;

/**
 */
@property (nonatomic, assign) NSInteger HTTPStatusCode;

///
/// @name Response Configuration
///

/**
 */
@property (nonatomic, assign) BOOL fetchesResponsesFromRealEndpoint;

/**
 */
@property (nonatomic, assign) NSTimeInterval responseLatency;

///
/// @name URL Matching
///

/**
 */
@property (nonatomic, copy) NSURL *URL;

/**
 */
@property (nonatomic, copy) NSRegularExpression *URLRegularExpression;

///
/// @name Class Methods
///

/**
 */
+ (instancetype)mockResponse;

/**
 */
+ (instancetype)mockResponseWithContentsOfURL:(NSURL *)URL;

/**
 */
+ (NSArray *)mockResponsesWithContentsOfDirectoryAtURL:(NSURL *)directoryURL;


/**
 */
+ (instancetype)mockResponseForURL:(NSURL *)URL HTTPRequestMethod:(NSString *)requestMethod;

/**
 */
+ (NSArray *)mockResponsesForURL:(NSURL *)URL HTTPRequestMethod:(NSString *)requestMethod;

/**
 */
+ (NSMutableArray *)allMockResponses;


///
/// @name Instance Methods
///

/**
 */
- (void)augmentResponseBody:(NSMutableData *)responseBody;

/**
 */
- (void)augmentResponseHeaders:(NSMutableDictionary *)responseHeaders;

/**
 */
- (BOOL)canUseWithURL:(NSURL *)URL;

@end
