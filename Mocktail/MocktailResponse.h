//
//  MocktailResponse.h
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>

extern NSString *const kMocktailResponseErrorDomain;
extern NSString *const kFileErrorUserDataKey;
extern NSString *const kNumberOfLinesErrorUserDataKey;

typedef NS_ENUM(NSInteger, MockTailResponseError) {
    MocktailResponseErrorOpeningFile,
    MocktailResponseErrorNumberOfLines
};

@class Mocktail;

@interface MocktailResponse : NSObject

@property (nonatomic, strong, readonly) NSRegularExpression *methodRegex;
@property (nonatomic, strong, readonly) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSInteger bodyOffset;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, weak) Mocktail *mocktail;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFileAtURL:(NSURL *)fileURL error:(NSError **)error NS_DESIGNATED_INITIALIZER;

+ (MocktailResponse *)mocktailResponseForFileAtURL:(NSURL *)url error:(NSError **)error;

@end
