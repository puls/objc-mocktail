//
//  Mocktail.h
//  Mocktail
//
//  Created by Jim Puls on 2/7/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>


/** The `Mocktail` class sets up an `NSURLProtocol` to send back mock responses for any and all of the HTTP requests in your app. See https://github.com/square/objc-mocktail for more information.
 */
@interface Mocktail : NSObject

/** @name Configuration */

/** Creates and starts a new Mocktail instance, reading in all of the `.tail` files in a directory.

 @param url Directory URL on filesystem where `.tail` files may be found
 */
+ (instancetype)startWithContentsOfDirectoryAtURL:(NSURL *)url;

/** Creates and starts a new Mocktail instance, reading a single `.tail` file at a url.

 @param url URL to a file on the filesystem. Must be a `.tail` file.

 @return an instantiated Mocktail instance.
 */
+ (instancetype)startWithFileAtURL:(NSURL *)url;

/** Creates and starts a new Mocktail instance, reading in the `.tail` files at the URLs passed.

 @param urlArray An array of NSURLs pointing to `.tail` files. Items that are not NSURLs or don't point to a `.tail` file will be ignored.

 @return an instantiated Mocktail instance.
 */
+ (instancetype)startWithFilesAtURLs:(NSArray *)urlArray;

/** Creates and starts a new Mocktail instance, reading in all of the `.tail` files in a directory and configuring an NSURLSession.

 @param url Directory URL on filesystem where `.tail` files may be found
 @param configuration `NSURLSessionConfiguration` for the session that will return mock responses. Pass `nil` if you're using `NSURLConnection` instead of `NSURLSession`.
 */
+ (instancetype)startWithContentsOfDirectoryAtURL:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration;

/** Stops the Mocktail instance from responding to requests.
 */
- (void)stop;

/** Clears all mocktails from the internal collection, effectively resetting Mocktail to it's initial state.
 */
+ (void)clearMocktails;

/** Additional latency to add before sending back mock responses. Useful for simulating a bad network, or at least for simulating real-world performance.

 Default value is 0.0.
 */
@property (nonatomic, assign) NSTimeInterval networkDelay;

/** Additional parameters to add on to the URL to match. Can be useful for having a second request return a different response than the first.
 */
@property (nonatomic, copy) NSDictionary *additionalQueryParameters;

/** Throw an exception if no mock responses matches the request
 */
@property (nonatomic, assign) BOOL throwExceptionIfNoResponseMatches;

/** @name Placeholder Support */

/** Returns the placeholder value for a given key

 @param aKey The key to replace in `.tail` files
 */
- (NSString *)objectForKeyedSubscript:(NSString *)aKey;

/** Sets the placeholder value for a given key

 @param object The placeholder value, probably a string.
 @param aKey The key to replace in `.tail` files
 */
- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)aKey;

@end
