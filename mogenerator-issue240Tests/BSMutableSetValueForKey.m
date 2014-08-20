//
//  BSMutableSetValueForKey.m
//  mogenerator-issue240
//
//  Created by Bryan Smith on 8/19/14.
//  Copyright (c) 2014 Bryan Smith. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BSCoreDataUtils.h"

#pragma mark - BSManagedObjectObserver

/**
 Observes an object and key path, and counts observations.
 */
@interface BSManagedObjectKVOCounter : NSObject

@property(nonatomic, strong) NSManagedObject *managedObject;

- (id)initWithManagedObject:(NSManagedObject *)managedObject
                    keyPath:(NSString *) keyPath;

@property (nonatomic) NSInteger count;

@property (nonatomic, strong) NSString *keyPath;

@end

@implementation BSManagedObjectKVOCounter

- (id)initWithManagedObject:(NSManagedObject *)managedObject
                    keyPath:(NSString *) keyPath {
    
    self = [super init];
    
    if (self) {
        
        [managedObject addObserver:self
                        forKeyPath:keyPath
                           options:NSKeyValueObservingOptionNew
                           context:nil];
        
        self.managedObject = managedObject;
        self.keyPath = keyPath;
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    NSLog(@"DEBUG: keyPath = %@", keyPath);
    
    if ([keyPath isEqualToString:self.keyPath]) {
        self.count++;
    }
}

- (void) dealloc {
    @try {
        [self.managedObject removeObserver:self
                                forKeyPath:self.keyPath];
    } @catch (NSException * __unused exception) {}
}

@end

#pragma mark - BSMutableSetValueForKey

@interface BSMutableSetValueForKey : XCTestCase

@end

@implementation BSMutableSetValueForKey

//
// Create stack once
//
+ (void)setUp
{
    [super setUp];
    [[BSCoreDataUtils sharedLocalStore] initialize];
}

//
// Clear out store after each test
//
- (void)tearDown {
    [super tearDown];
    [[BSCoreDataUtils sharedLocalStore] clear];
}

/**
 Show -mutableSetValueForKey handles KVO automatically.
 */
- (void)testMutableSetValueForKey
{
    BSCoreDataUtils *utils = [BSCoreDataUtils sharedLocalStore];
    
    NSManagedObject *parent =
    [NSEntityDescription insertNewObjectForEntityForName:@"Parent"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(parent);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    NSMutableSet *children = [parent mutableSetValueForKey:@"children"];
    [children addObject:child];
    
    XCTAssertEqual(1, counter.count, @"KVO should have fired");
    XCTAssertEqual(1, [[parent valueForKey:@"children"] count]);
    XCTAssertNotNil([child valueForKey:@"parent"], @"KVO assisted inverse relationship");
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

/**
 Show -primativeValueForKey does not handle KVO. (negative test)
 */
- (void)testPrimativeValueForKeyNoKVO
{
    BSCoreDataUtils *utils = [BSCoreDataUtils sharedLocalStore];
    
    NSManagedObject *parent =
    [NSEntityDescription insertNewObjectForEntityForName:@"Parent"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(parent);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    NSMutableSet *children;
    {
        NSSet *_children = [parent primitiveValueForKey:@"children"];
        children = [_children mutableCopy];
    }
    
    [children addObject:child];
    
    [parent setPrimitiveValue:children forKey:@"children"];
    
    XCTAssertEqual(0, counter.count, @"KVO shouldn't have fired.");
    XCTAssertEqual(1, [[parent valueForKey:@"children"] count]);
    XCTAssertNil([child valueForKey:@"parent"], @"Without KVO, no inverse");
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

/**
 Show -primativeValueForKey and manual KVO.
 */
- (void)testPrimativeValueForKeyKVO
{
    BSCoreDataUtils *utils = [BSCoreDataUtils sharedLocalStore];
    
    NSManagedObject *parent =
    [NSEntityDescription insertNewObjectForEntityForName:@"Parent"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(parent);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    NSMutableSet *children;
    {
        NSSet *_children = [parent primitiveValueForKey:@"children"];
        children = [_children mutableCopy];
    }
    
    [children addObject:child];
    
    [parent willChangeValueForKey:@"children"];
    [parent setPrimitiveValue:children forKey:@"children"];
    [parent didChangeValueForKey:@"children"];
    
    XCTAssertEqual(1, counter.count, @"KVO should have fired.");
    XCTAssertEqual(1, [[parent valueForKey:@"children"] count]);
    XCTAssertNotNil([child valueForKey:@"parent"], @"KVO assisted inverse relationship");
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

@end
