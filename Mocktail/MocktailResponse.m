//
//  MocktailResponse.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <Foundation/Foundation.h>
#import "MocktailResponse.h"

NSString * const MocktailFileExtension = @"tail";

@interface MocktailResponse ()
@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) NSUInteger bodyOffset;
@end

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

- (NSData *)bodyWithValues:(NSDictionary *)values;
{
    NSData *body = [NSData dataWithContentsOfURL:self.fileURL];
    body = [body subdataWithRange:NSMakeRange(self.bodyOffset, body.length - self.bodyOffset)];

    // Replace placeholders with values. We transform the body data into a string for easier search and replace.
    if ([values count] > 0) {
        NSMutableString *bodyString = [[NSMutableString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        BOOL didReplace = NO;
        for (NSString *placeholder in values) {
            NSString *value = [values objectForKey:placeholder];
            NSString *placeholderFormat = [NSString stringWithFormat:@"{{ %@ }}", placeholder];

            if ([bodyString replaceOccurrencesOfString:placeholderFormat withString:value options:NSLiteralSearch range:NSMakeRange(0, [bodyString length])] > 0) {
                didReplace = YES;
            }
        }

        if (didReplace) {
            body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        }
    } else if ([self.headers[@"Content-Type"] hasSuffix:@";base64"]) {
        NSString *type = self.headers[@"Content-Type"];
        NSString *newType = [type substringWithRange:NSMakeRange(0, type.length - 7)];
        self.headers = @{@"Content-Type":newType};
        body = [self dataByDecodingBase64Data:body];
    }
    return body;
}

- (NSData *)body;
{
    return [self bodyWithValues:nil];
}

- (NSData *)dataByDecodingBase64Data:(NSData *)encodedData;
{
    if (!encodedData) {
        return nil;
    }
    if (!encodedData.length) {
        return [NSData data];
    }

    static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    static char *decodingTable = NULL;
    if (!decodingTable) {
        @synchronized([self class]) {
            if (!decodingTable) {
                decodingTable = malloc(256);
                if (!decodingTable) {
                    return nil;
                }

                memset(decodingTable, CHAR_MAX, 256);
                for (char i = 0; i < 64; i++) {
                    decodingTable[(short)encodingTable[i]] = i;
                }
            }
        }
    }

    const char *characters = [encodedData bytes];
    if (!characters) {
        return nil;
    }

    char *bytes = malloc(((encodedData.length + 3) / 4) * 3);
    if (!bytes) {
        return nil;
    }

    NSUInteger length = 0;
    NSUInteger characterIndex = 0;

    while (YES) {
        char buffer[4];
        short bufferLength;

        for (bufferLength = 0; bufferLength < 4 && characterIndex < encodedData.length; characterIndex++) {
            if (characters[characterIndex] == '\0') {
                break;
            }
            if (isblank(characters[characterIndex]) || characters[characterIndex] == '=' || characters[characterIndex] == '\n' || characters[characterIndex] == '\r') {
                continue;
            }

            // Illegal character!
            buffer[bufferLength] = decodingTable[(short)characters[characterIndex]];
            if (buffer[bufferLength++] == CHAR_MAX) {
                free(bytes);
                [[NSException exceptionWithName:@"InvalidBase64Characters" reason:@"Invalid characters in base64 string" userInfo:nil] raise];

                return nil;
            }
        }

        if (bufferLength == 0) {
            break;
        }
        if (bufferLength == 1) {
            // At least two characters are needed to produce one byte!
            free(bytes);
            [[NSException exceptionWithName:@"InvalidBase64Length" reason:@"Invalid base64 string length" userInfo:nil] raise];
            return nil;
        }

        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2) {
            bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
        }
        if (bufferLength > 3) {
            bytes[length++] = (buffer[2] << 6) | buffer[3];
        }
    }

    realloc(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

@end
