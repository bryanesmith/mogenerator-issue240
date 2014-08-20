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

static NSString *const sampleName = @"Lycurgus Mihovil";

//
// Create stack once
//
+ (void)setUp
{
    [super setUp];
    
    BSCoreDataUtils *utils = [BSCoreDataUtils sharedLocalStore];
    [utils initialize];
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
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(child);
    
    NSError *error;
    BOOL saved = [utils.moc save:&error];
    XCTAssert(saved, @"Error: %@", error);
    
    // Refault parent so children relationship refaulted.
    [utils.moc refreshObject:parent mergeChanges:NO];
    
    XCTAssert([parent isFault]);
    XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    // KVO #1: "Relationship 'children' fault on managed object"
    NSMutableSet *children = [parent mutableSetValueForKey:@"children"];
    
    XCTAssertEqual(1, counter.count); // KVO
    
    XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
    
    /// KVO #2: "Relationship 'children' on managed object"
    [children addObject:child];
    
    XCTAssertEqual(2, counter.count); // KVO
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
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(child);
    
    NSError *error;
    BOOL saved = [utils.moc save:&error];
    XCTAssert(saved, @"Error: %@", error);
    
    // Refault parent so children relationship refaulted.
    [utils.moc refreshObject:parent mergeChanges:NO];
    
    XCTAssert([parent isFault]);
    XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    // KVO #1: "Relationship 'children' fault on managed object"
    NSMutableSet *children;
    {
        NSSet *_children = [parent primitiveValueForKey:@"children"];
        XCTAssertEqual(1, counter.count); // KVO
        
        XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
        children = [_children mutableCopy];
        XCTAssertFalse([parent hasFaultForRelationshipNamed:@"children"]);
    }
    
    XCTAssertEqual(1, counter.count);  // No additional KVO
    
    // No KVO #2
    [children addObject:child];
    [parent setPrimitiveValue:children forKey:@"children"];
    
    XCTAssertEqual(1, counter.count);  // No additional KVO
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
    
    NSManagedObject *child =
    [NSEntityDescription insertNewObjectForEntityForName:@"Child"
                                  inManagedObjectContext:utils.moc];
    
    XCTAssertNotNil(child);
    
    NSError *error;
    BOOL saved = [utils.moc save:&error];
    XCTAssert(saved, @"Error: %@", error);
    
    // Refault parent so children relationship refaulted.
    [utils.moc refreshObject:parent mergeChanges:NO];
    
    XCTAssert([parent isFault]);
    XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
    
    BSManagedObjectKVOCounter *counter =
    [[BSManagedObjectKVOCounter alloc] initWithManagedObject:parent
                                                     keyPath:@"children"];
    
    XCTAssertEqual(0, counter.count);
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Interesting part
    
    // KVO #1: "Relationship 'children' fault on managed object"
    NSMutableSet *children;
    {
        NSSet *_children = [parent primitiveValueForKey:@"children"];
        XCTAssertEqual(1, counter.count); // KVO
        
        XCTAssert([parent hasFaultForRelationshipNamed:@"children"]);
        children = [_children mutableCopy];
        XCTAssertFalse([parent hasFaultForRelationshipNamed:@"children"]);
    }
    
    [children addObject:child];
    
    XCTAssertEqual(1, counter.count);
    
    // KVO #2: "Relationship 'children' on managed object"
    [parent willChangeValueForKey:@"children"];
    [parent setPrimitiveValue:children forKey:@"children"];
    [parent didChangeValueForKey:@"children"];
    
    XCTAssertEqual(2, counter.count); // KVO
    XCTAssertEqual(1, [[parent valueForKey:@"children"] count]);
    XCTAssertNotNil([child valueForKey:@"parent"], @"KVO assisted inverse relationship");
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

@end
