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


@implementation MocktailResponse

+ (instancetype)responseFromFileAtURL:(NSURL *)url;
{
    NSAssert(url, @"Expected valid URL.");

    NSError *error = nil;
    NSStringEncoding originalEncoding;
    NSString *contentsOfFile = [NSString stringWithContentsOfURL:url usedEncoding:&originalEncoding error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", url, error);
        return nil;
    }

    NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
    NSString *headerMatter = nil;
    [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
    NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
    if ([lines count] < 4) {
        NSLog(@"Invalid amount of lines: %u", (unsigned)[lines count]);
        return nil;
    }

    MocktailResponse *response = [[self alloc] init];
    response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    response.statusCode = [lines[2] integerValue];
    response.headers = @{@"Content-Type":lines[3]};
    response.fileURL = url;
    response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    return response;
}

- (BOOL)matchesURL:(NSURL *)URL method:(NSString *)method patternLength:(NSUInteger *)patternLength;
{
    NSString *absoluteURL = [URL absoluteString];

    if ([self.absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
        if ([self.methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
            if (patternLength) {
                *patternLength = self.absoluteURLRegex.pattern.length;
            }
            return YES;
        }
    }

    return NO;
}


@end
