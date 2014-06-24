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
#import "Mocktail_Private.h"
#import "MocktailResponse.h"
#import "MocktailURLProtocol.h"


static NSString * const MocktailFileExtension = @".tail";


@interface Mocktail ()

@property (nonatomic, strong) NSMutableDictionary *mutablePlaceholderValues;
@property (nonatomic, strong) NSMutableSet *mutableMockResponses;
@property (nonatomic, strong) NSURLSessionConfiguration *configuration;

@end


@implementation Mocktail

static NSMutableSet *_allMocktails;

+ (NSMutableSet *)allMocktails;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _allMocktails = [NSMutableSet new];
    });
    
    return _allMocktails;
}

+ (instancetype)startWithContentsOfDirectoryAtURL:(NSURL *)url configuration:(NSURLSessionConfiguration *)inConfiguration
{
    Mocktail *mocktail = [self new];
    [mocktail registerContentsOfDirectoryAtURL:url];
    [mocktail setConfiguration:inConfiguration];
    [mocktail start];
    return mocktail;
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

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey
{
    @synchronized (_mutablePlaceholderValues) {
        [_mutablePlaceholderValues setObject:object forKey:aKey];
    }
}

- (id)objectForKeyedSubscript:(id<NSCopying>)aKey;
{
    NSString *value;
    @synchronized (_mutablePlaceholderValues) {
        value = [[_mutablePlaceholderValues objectForKey:aKey] copy];
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

+ (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method;
{
    NSAssert(url && method, @"Expected a valid URL and method.");

    MocktailResponse *matchingResponse = nil;
    NSUInteger matchingRegexLength = 0;

    NSString *absoluteURL = [url absoluteString];
    for (Mocktail *mocktail in [Mocktail allMocktails]) {
        for (MocktailResponse *response in mocktail.mockResponses) {
            if ([response.absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
                if ([response.methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
                    if (response.absoluteURLRegex.pattern.length > matchingRegexLength) {
                        matchingResponse = response;
                        matchingRegexLength = response.absoluteURLRegex.pattern.length;
                    }
                }
            }
        }
    }
    
    return matchingResponse;
}

- (void)start;
{
    NSAssert([NSThread isMainThread], @"Please start and stop Mocktail from the main thread");
    NSAssert(![[Mocktail allMocktails] containsObject:self], @"Tried to start Mocktail twice");
    
    
    if (_configuration == nil) {
        if ([Mocktail allMocktails].count == 0) {
            NSAssert([NSURLProtocol registerClass:[MocktailURLProtocol class]], @"Unsuccessful Class Registration");
        }
    }
    if (_configuration != nil){
        if ([Mocktail allMocktails].count == 0) {
            _configuration.protocolClasses = @[[MocktailURLProtocol class]];
        }
    }
    
    [[Mocktail allMocktails] addObject:self];
}

- (void)stop;
{
    NSAssert([NSThread isMainThread], @"Please start and stop Mocktail from the main thread");
    NSAssert([[Mocktail allMocktails] containsObject:self], @"Tried to stop unstarted Mocktail");
    
    [[Mocktail allMocktails] removeObject:self];
    if ([Mocktail allMocktails].count == 0) {
        [NSURLProtocol unregisterClass:[MocktailURLProtocol class]];
    }
}

#pragma mark - Parsing files

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

-(void)setConfiguration:(NSURLSessionConfiguration *)inConfiguration{
    _configuration = inConfiguration;
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
    response.mocktail = self;
    response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    response.statusCode = [lines[2] integerValue];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(3, lines.count - 3)]) {
        NSArray* parts = [line componentsSeparatedByString:@":"];
        [headers setObject:[[parts lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                    forKey:[parts firstObject]];
    }
    response.headers = headers;
    response.fileURL = url;
    response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    
    @synchronized (_mutableMockResponses) {
        [_mutableMockResponses addObject:response];
    }
}

@end
