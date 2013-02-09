//
//  MTMockResponseHandler.h
//  Mocktail
//
//  Created by Kyle Van Essen on 2/9/13.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MTMockResponse;
@class MTMockURLProtocol;

@interface MTMockResponseHandler : NSObject

@property (nonatomic, retain, readonly) MTMockResponse *mockResponse;
@property (nonatomic, retain, readonly) MTMockURLProtocol *mockURLProtocol;

+ (instancetype)responseHandlerWithMockResponse:(MTMockResponse *)mockResponse mockURLProtocol:(MTMockURLProtocol *)mockURLProtocol;

- (void)startLoadingMockResponse;
- (void)stopLoadingMockResponse;

@end
