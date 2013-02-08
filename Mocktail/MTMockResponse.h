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

/**
 */
@property (nonatomic, assign) NSInteger errorCode;

/**
 */
@property (nonatomic, assign) NSTimeInterval latency;

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


///
/// @name Instance Methods
///

/**
 */
- (NSData *)augmentedResponseData:(NSData *)response;

@end
