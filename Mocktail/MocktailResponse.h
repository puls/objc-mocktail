//
//  MocktailResponse.h
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>


@class Mocktail;


@interface MocktailResponse : NSObject

@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) NSInteger bodyOffset;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, weak) Mocktail *mocktail;

@end
