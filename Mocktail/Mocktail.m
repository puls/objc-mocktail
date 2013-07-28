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


@interface Mocktail ()

@property (nonatomic, strong) NSMutableDictionary *mutablePlaceholderValues;
@property (nonatomic, strong) NSMutableSet *mutableMockResponses;

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

+ (instancetype)startWithContentsOfDirectoryAtURL:(NSURL *)url
{
    Mocktail *mocktail = [self new];
    [mocktail registerContentsOfDirectoryAtURL:url];
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

+ (MocktailResponse *)mockResponseForURL:(NSURL *)url method:(NSString *)method mocktail:(Mocktail **)matchingMocktail;
{
    NSAssert(url && method, @"Expected a valid URL and method.");

    MocktailResponse *matchingResponse = nil;
    NSUInteger matchingRegexLength = 0;

    for (Mocktail *mocktail in [Mocktail allMocktails]) {
        for (MocktailResponse *response in mocktail.mockResponses) {
            NSUInteger patternLength;
            if ([response matchesURL:url method:method patternLength:&patternLength] && patternLength > matchingRegexLength) {
                matchingResponse = response;
                matchingRegexLength = patternLength;
                if (matchingMocktail) {
                    *matchingMocktail = mocktail;
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
    
    if ([Mocktail allMocktails].count == 0) {
        [NSURLProtocol registerClass:[MocktailURLProtocol class]];
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
        if (![fileURL.pathExtension isEqualToString:MocktailFileExtension]) {
            continue;
        }

        [self registerFileAtURL:fileURL];
    }
}

- (void)registerFileAtURL:(NSURL *)url;
{
    MocktailResponse *response = [MocktailResponse responseFromFileAtURL:url];
    if (response) {
        @synchronized (_mutableMockResponses) {
            [_mutableMockResponses addObject:response];
        }
    }
}

@end
