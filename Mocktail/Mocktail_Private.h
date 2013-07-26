//
//  Mocktail_Private.h
//  Mocktail
//
//  Created by Jim Puls on 3/15/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>
#import "Mocktail.h"


@class MocktailResponse;


@interface Mocktail (Private)

+ (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method mocktail:(Mocktail **)mocktail;

- (NSDictionary *)placeholderValues;

@end
