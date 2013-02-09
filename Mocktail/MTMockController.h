//
//  MTMockController.h
//  Mocktail
//
//  Created by Kyle Van Essen on 2013-02-07.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTMockController : NSObject

@property (nonatomic, assign, readonly, getter=isMockingNetworkResponses) BOOL mockingNetworkResponses;

- (void)startMockingNetworkResponses;
- (void)stopMockingNetworkResponses;

@end
