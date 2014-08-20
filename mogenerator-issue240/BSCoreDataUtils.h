//
//  BSCoreDataUtils.h
//  mogenerator-issue240
//
//  Created by Bryan Smith on 8/19/14.
//  Copyright (c) 2014 Bryan Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSCoreDataUtils : NSObject

/**
 Access singleton
 */
+ (instancetype)sharedLocalStore;

- (void) initialize;

- (void) clear;

@property(strong, nonatomic) NSManagedObjectContext *moc;

@end
