//
//  MImage.m
//  Mocktail
//
//  Created by Coffman, Ben on 4/23/13.
//  Copyright (c) 2013 Square, Inc. All rights reserved.
//

#import "MImage.h"

@implementation MImage
-(id)initWithValues:(NSString *)imageName imageURL:(NSString *)imageURL{
    if(self = [super init]){
        self.imageName = imageName;
        self.imageURL = imageURL;
    }
    
    return self;
}

@end
