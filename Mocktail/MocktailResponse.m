//
//  MocktailResponse.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "MocktailResponse.h"

@interface MocktailResponse()

@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) NSInteger bodyOffset;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;

@end

NSString *const kMocktailResponseErrorDomain = @"MocktailResponseError";
static NSUInteger const kNumLinesRequired = 4;

@implementation MocktailResponse

- (instancetype)initWithFileAtURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    self = [super init];
    if (self) {
        NSError *fileError;
        NSStringEncoding originalEncoding;
        NSString *contentsOfFile = [NSString stringWithContentsOfURL:url usedEncoding:&originalEncoding error:&fileError];
        if (fileError) {
            *error = [[NSError alloc] initWithDomain:kMocktailResponseErrorDomain
                                                code:MocktailResponseErrorOpeningFile
                                            userInfo:@{@"fileError": fileError}];
            return nil;
        }

        NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
        NSString *headerMatter = nil;
        [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
        NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
        if ([lines count] < kNumLinesRequired) {
            *error = [[NSError alloc] initWithDomain:kMocktailResponseErrorDomain
                                                code:MocktailResponseErrorNumberOfLines
                                            userInfo:@{@"lines": lines}];
            return nil;
        }

        _methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
        _absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
        _statusCode = [lines[2] integerValue];
        NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(3, lines.count - 3)]) {
            NSArray* parts = [line componentsSeparatedByString:@":"];
            headers[[parts firstObject]] = [[parts lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        _headers = headers;
        _fileURL = url;
        _bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    }

    return self;
}

+ (MocktailResponse *)mocktailResponseForFileAtURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    NSAssert(url, @"Expected valid URL.");

    return [[MocktailResponse alloc] initWithFileAtURL:url error:error];
}

@end
