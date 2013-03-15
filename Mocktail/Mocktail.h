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

/** Stops the Mocktail instance from responding to requests.
 */
- (void)stop;

/** Additional latency to add before sending back mock responses. Useful for simulating a bad network, or at least for simulating real-world performance.
 
 Default value is 0.0.
 */
@property (nonatomic, assign) NSTimeInterval networkDelay;

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
