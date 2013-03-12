//
//  Mocktail.h
//  Mocktail
//
//  Created by Jim Puls on 2/7/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <Foundation/Foundation.h>


@class MocktailResponse;


@interface Mocktail : NSObject

+ (instancetype)sharedMocktail;

@property (nonatomic, assign) NSTimeInterval networkDelay;
@property (nonatomic, strong, readonly) NSDictionary *placeholderValues;
@property (nonatomic, assign, getter=isStarted) BOOL started;

- (void)start;
- (void)stop;

- (void)registerContentsOfDirectoryAtURL:(NSURL *)url;
- (void)registerFileAtURL:(NSURL *)url;

- (void)setValue:(NSString *)value forPlaceholder:(NSString *)placeholder;
- (NSString *)valueForPlaceholder:(NSString *)placeholder;

- (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method;


/// @name Deprecated Methods

+ (void)startWithContentsOfDirectoryAtURL:(NSURL *)url __attribute__((deprecated("Use +sharedMocktail, -registerContentsOfDirectoryAtURL: and -start instead.")));

@end
