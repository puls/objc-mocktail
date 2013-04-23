//
//  MocktailURLProtocol.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "MocktailURLProtocol.h"
#import "Mocktail_Private.h"
#import "MocktailResponse.h"


@interface MocktailURLProtocol ()

@property BOOL canceled;

@end


@implementation MocktailURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return !![Mocktail mockResponseForURL:request.URL method:request.HTTPMethod];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;
{
    return NO;
}

- (void)startLoading;
{
    NSLog(@"mocking %@ %@", self.request.URL, self.request.HTTPMethod);
    
    MocktailResponse *response = [Mocktail mockResponseForURL:self.request.URL method:self.request.HTTPMethod];
    Mocktail *mocktail = response.mocktail;
    NSAssert(response, @"Expected valid mock response");
    __block NSData *body = [NSData dataWithContentsOfURL:response.fileURL];
    body = [body subdataWithRange:NSMakeRange(response.bodyOffset, body.length - response.bodyOffset)];
    
    // Replace placeholders with values. We transform the body data into a string for easier search and replace.
    NSDictionary *placeholderValues = mocktail.placeholderValues;
    NSMutableString *bodyString = [[NSMutableString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    
    NSRange emptyRange = [bodyString rangeOfString:@"{{"];
    
    if (emptyRange.location != NSNotFound)
    {
        if ([placeholderValues count] > 0) {
            NSMutableString *bodyString = [[NSMutableString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            __block BOOL didReplace = NO;
            [placeholderValues enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
                if ([key isEqualToString:@"image"]) {
                    NSError *error;
                    body = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:obj ofType:nil] options:NSDataReadingUncached error:&error];
                    
                    if (!body) {
                        NSLog(@"Data Error: %@", error);
                    }
                } else {
                    NSString *placeholderFormat = [NSString stringWithFormat:@"{{ %@ }}", key];
                    
                    if ([bodyString replaceOccurrencesOfString:placeholderFormat withString:obj options:NSLiteralSearch range:NSMakeRange(0, [bodyString length])] > 0) {
                        didReplace = YES;
                    }
                }
            }];
            
            if (didReplace) {
                body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
            }
        } else if ([response.headers[@"Content-Type"] hasSuffix:@";base64"]) {
            NSString *type = response.headers[@"Content-Type"];
            NSString *newType = [type substringWithRange:NSMakeRange(0, type.length - 7)];
            response.headers = @{@"Content-Type":newType};
            body = [self dataByDecodingBase64Data:body];
        }
    }
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:response.statusCode HTTPVersion:@"1.1" headerFields:response.headers];
    [self.client URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    
    dispatch_block_t sendResponse = ^{
        if (!self.canceled) {
            [self.client URLProtocol:self didLoadData:body];
            [self.client URLProtocolDidFinishLoading:self];
        }
    };
    if (mocktail.networkDelay == 0.0) {
        sendResponse();
    } else {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, mocktail.networkDelay * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), sendResponse);
    }
}

- (void)stopLoading;
{
    self.canceled = YES;
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
                for (NSInteger i = 0; i < 64; i++) {
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
