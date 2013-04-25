//
//  MImage.h
//  Mocktail
//
//  Created by Coffman, Ben on 4/23/13.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MImage : NSObject

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imageURL;

-(id)initWithValues:(NSString *)imageName imageURL:(NSString *)imageURL;

@end
