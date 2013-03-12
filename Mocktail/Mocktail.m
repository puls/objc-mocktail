//
//  Mocktail.m
//  Mocktail
//
//  Created by Jim Puls on 2/7/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "Mocktail.h"
#import "MocktailResponse.h"
#import "MocktailURLProtocol.h"


static NSString * const MocktailFileExtension = @".tail";


@interface Mocktail ()

@property (nonatomic, strong) NSMutableDictionary *mutablePlaceholderValues;
@property (nonatomic, strong) NSMutableSet *mutableMockResponses;

@end


@implementation Mocktail

#pragma mark - Mocktail

+ (instancetype)sharedMocktail;
{
    static Mocktail *sharedMocktail;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMocktail = [[Mocktail alloc] init];
    });
    return sharedMocktail;
}

- (id)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _mutableMockResponses = [[NSMutableSet alloc] init];
    _mutablePlaceholderValues = [[NSMutableDictionary alloc] init];
    _networkDelay = 0.0;
    
    return self;
}

#pragma mark - Accessors/Mutators

- (NSDictionary *)placeholderValues;
{
    NSDictionary *placeholderValues;
    @synchronized (_mutablePlaceholderValues) {
        placeholderValues = [self.mutablePlaceholderValues copy];
    }
    return placeholderValues;
}

- (void)setValue:(NSString *)value forPlaceholder:(NSString *)placeholder;
{
    @synchronized (_mutablePlaceholderValues) {
        [_mutablePlaceholderValues setObject:value forKey:placeholder];
    }
}

- (NSString *)valueForPlaceholder:(NSString *)placeholder;
{
    NSString *value;
    @synchronized (_mutablePlaceholderValues) {
        value = [[_mutablePlaceholderValues objectForKey:placeholder] copy];
    }
    return value;
}

- (NSSet *)mockResponses;
{
    NSSet *mockResponses;
    @synchronized (_mutableMockResponses) {
        mockResponses = [_mutableMockResponses copy];
    }
    return mockResponses;
}

- (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method;
{
    NSAssert(url && method, @"Expected a valid URL and method.");
    
    NSString *absoluteURL = [url absoluteString];
    for (MocktailResponse *response in self.mockResponses) {
        if ([response.absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
            if ([response.methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
                return response;
            }
        }
    }
    
    return nil;
}

- (void)start;
{
    if (self.started) {
        return;
    }
    
    [NSURLProtocol registerClass:[MocktailURLProtocol class]];
    self.started = YES;
}

- (void)stop;
{
    if (!self.started) {
        return;
    }
    
    [NSURLProtocol unregisterClass:[MocktailURLProtocol class]];
    self.started = NO;
}

#pragma mark - Actions

- (void)registerContentsOfDirectoryAtURL:(NSURL *)url;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:0 error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", url, error);
        return;
    }
    
    for (NSURL *fileURL in fileURLs) {
        if (![[fileURL absoluteString] hasSuffix:MocktailFileExtension]) {
            continue;
        }

        [self registerFileAtURL:fileURL];
    }
}

- (void)registerFileAtURL:(NSURL *)url;
{
    NSAssert(url, @"Expected valid URL.");
    
    NSError *error;
    NSStringEncoding originalEncoding;
    NSString *contentsOfFile = [NSString stringWithContentsOfURL:url usedEncoding:&originalEncoding error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", url, error);
        return;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
    NSString *headerMatter = nil;
    [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
    NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
    if ([lines count] < 4) {
        NSLog(@"Invalid amount of lines: %u", (unsigned)[lines count]);
        return;
    }
    
    MocktailResponse *response = [MocktailResponse new];
    response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    response.statusCode = [lines[2] integerValue];
    response.headers = @{@"Content-type":lines[3]};
    response.fileURL = url;
    response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    
    @synchronized (_mutableMockResponses) {
        [_mutableMockResponses addObject:response];
    }
}

#pragma mark - Deprecated Methods

+ (void)startWithContentsOfDirectoryAtURL:(NSURL *)url
{
    Mocktail *mocktail = [self sharedMocktail];
    [mocktail registerContentsOfDirectoryAtURL:url];
    [mocktail start];
}

@end
