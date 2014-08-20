//
//  BSCoreDataUtils.m
//  mogenerator-issue240
//
//  Created by Bryan Smith on 8/19/14.
//  Copyright (c) 2014 Bryan Smith. All rights reserved.
//

#import "BSCoreDataUtils.h"

@interface BSCoreDataUtils()

@property (nonatomic, strong) NSManagedObjectModel *mom;

@end

@implementation BSCoreDataUtils

+ (instancetype)sharedLocalStore {
    static BSCoreDataUtils *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[BSCoreDataUtils alloc] init];
    });
    
    return singleton;
}

- (void) initialize {
    
    //
    // MOM
    //
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"mogenerator_issue240"
                                              withExtension:@"momd"];
    NSAssert(modelURL, @"Didn't find model");
    
    self.mom =
    [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSAssert(self.mom, @"Didn't create mom");
    
    //
    // PSC
    //
    NSPersistentStoreCoordinator *psc =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.mom];
    NSAssert(psc, @"Didn't create psc");
    
    //
    // PS
    //
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager URLsForDirectory:NSDocumentDirectory
                                            inDomains:NSUserDomainMask];
    
    NSURL *storeUrl = [contents lastObject];
    NSAssert(storeUrl, @"Failed to find directory");
    storeUrl = [storeUrl URLByAppendingPathComponent:@"MogeneratorIssue240.sqlite"];
    
    // tabula rasa each run
    [[NSFileManager defaultManager] removeItemAtPath:[storeUrl path] error:nil];
    
    NSError *error;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:storeUrl
                                                       options:nil
                                                         error:&error];
    NSAssert(store, @"Error: %@", error);
    
    //
    // MOC
    //
    self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.moc setPersistentStoreCoordinator:psc];
}

- (void) clear {
    
    for (NSEntityDescription *entity in self.mom.entities) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        
        NSArray *items = [self.moc executeFetchRequest:fetchRequest error:nil];
        for (NSManagedObject *mo in items) {
            [self.moc deleteObject:mo];
        }
    }
    
    NSError *error;
    const BOOL saved = [self.moc save:&error];
    NSAssert(saved, @"Error: %@", error);
}


@end
