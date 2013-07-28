//
//  MocktailResponse.h
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const MocktailFileExtension;

@interface MocktailResponse : NSObject

+ (instancetype)responseFromFileAtURL:(NSURL *)url;
- (BOOL)matchesURL:(NSURL *)URL method:(NSString *)method patternLength:(NSUInteger *)patternLength;

@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSData *body;
- (NSData *)bodyWithValues:(NSDictionary *)values;

@end
