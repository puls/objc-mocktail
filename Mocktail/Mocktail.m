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
#import <UIKit/UIKit.h>


static NSString *const MocktailFileExtension = @".tail";
static NSString *const MocktailPasteboardName = @"Mocktail Query String";


@interface Mocktail ()

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;
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
    return [self startWithContentsOfDirectoryAtURL:url configuration:nil];
}

+ (instancetype)startWithContentsOfDirectoryAtURL:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration;
{
    Mocktail *mocktail = [self new];
    [mocktail registerContentsOfDirectoryAtURL:url];
    mocktail.configuration = configuration;
    [mocktail start];
    return mocktail;
}

+ (instancetype)startWithFileAtURL:(NSURL *)url
{
    return [self startWithFilesAtURLs:@[url]];
}

+ (instancetype)startWithFilesAtURLs:(NSArray *)urlArray
{
    Mocktail *mocktail = [self new];
    for (NSURL *url in urlArray) {
        if ([url isKindOfClass:[NSURL class]]) {
            [mocktail registerFileAtURL:url];
        }
    }
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

    for (Mocktail *mocktail in [Mocktail allMocktails]) {
        NSMutableString *absoluteURL = [[url absoluteString] mutableCopy];
        BOOL hasQuery = url.query != nil;
        if (mocktail.additionalQueryParameters) {
            [absoluteURL appendString:hasQuery ? @"&" : @"?"];
            for (NSString *key in mocktail.additionalQueryParameters) {
                [absoluteURL appendFormat:@"%@=%@&", key, mocktail.additionalQueryParameters[key]];
            }
            hasQuery = YES;
        }
        NSString *pasteboardExtras = [[UIPasteboard pasteboardWithName:MocktailPasteboardName create:NO] string];
        if (pasteboardExtras.length > 0) {
            [absoluteURL appendString:hasQuery ? @"&" : @"?"];
            [absoluteURL appendString:pasteboardExtras];
            hasQuery = YES;
        }

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

    if ([Mocktail allMocktails].count == 0) {
        if (self.configuration) {
            NSArray *classes = [[NSArray arrayWithObject:[MocktailURLProtocol class]] arrayByAddingObjectsFromArray:self.configuration.protocolClasses];
            self.configuration.protocolClasses = classes;
        } else {
            NSAssert([NSURLProtocol registerClass:[MocktailURLProtocol class]], @"Unsuccessful Class Registration");
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
        if (self.configuration) {
            NSMutableArray *newClasses = [self.configuration.protocolClasses mutableCopy];
            [newClasses removeObject:[MocktailURLProtocol class]];
            self.configuration.protocolClasses = newClasses;
        } else {
            [NSURLProtocol unregisterClass:[MocktailURLProtocol class]];
        }
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

- (void)registerFileAtURL:(NSURL *)url;
{
    MocktailResponse *response = [MocktailResponse mocktailResponseForFileAtURL:url];

    @synchronized (_mutableMockResponses) {
        if (response) {
            response.mocktail = self;
            [_mutableMockResponses addObject:response];
        }
    }
}

@end
