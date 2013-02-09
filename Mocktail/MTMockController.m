//
//  MTMockController.m
//  Mocktail
//
//  Created by Kyle Van Essen on 2013-02-07.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import "MTMockController.h"
#import "MTMockResponse.h"
#import "MTMockResponseHandler.h"
#import "MTMockURLProtocol.h"


@interface MTMockController ()

@property (nonatomic, assign, readwrite, getter=isMockingNetworkResponses) BOOL mockingNetworkResponses;

@end


@implementation MTMockController

#pragma mark - Public Methods

- (void)startMockingNetworkResponses;
{
    if (self.mockingNetworkResponses) {
        return;
    }

    self.mockingNetworkResponses = YES;

    [NSURLProtocol registerClass:[MTMockURLProtocol class]];
}

- (void)stopMockingNetworkResponses;
{
    if (!self.mockingNetworkResponses) {
        return;
    }

    self.mockingNetworkResponses = NO;

    [NSURLProtocol unregisterClass:[MTMockURLProtocol class]];
}

@end
