//
//  BSMutableSetValueForKey.m
//  mogenerator-issue240
//
//  Created by Bryan Smith on 8/19/14.
//  Copyright (c) 2014 Bryan Smith. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BSCoreDataUtils.h"

@interface BSMutableSetValueForKey : XCTestCase

@end

@implementation BSMutableSetValueForKey

+ (void)setUp
{
    [super setUp];
    [[BSCoreDataUtils sharedLocalStore] initialize];
}

- (void)tearDown {
    [super tearDown];
    [[BSCoreDataUtils sharedLocalStore] clear];
}

- (void)testExample
{
    
}

@end
