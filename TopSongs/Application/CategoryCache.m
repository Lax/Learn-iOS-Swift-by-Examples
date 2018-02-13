/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Simple LRU (least recently used) cache for Category objects to reduce fetching.
 */

#import "CategoryCache.h"
#import "Category.h"

// CacheNode is a simple object to help with tracking cached items
//
@interface CacheNode : NSObject {
    NSManagedObjectID *objectID;
    NSUInteger accessCounter;
}

@property (nonatomic, strong) NSManagedObjectID *objectID;
@property NSUInteger accessCounter;

@end


#pragma mark -

@interface CategoryCache ()

@property (nonatomic, strong, readonly) NSEntityDescription *categoryEntityDescription;
@property (nonatomic, strong, readonly) NSPredicate *categoryNamePredicateTemplate;

// Number of objects that can be cached
@property NSUInteger cacheSize;

// A dictionary holds the actual cached items
@property (nonatomic, strong) NSMutableDictionary *cache;

// Counter used to determine the least recently touched item.
@property (assign) NSUInteger accessCounter;

// Some basic metrics are tracked to help determine the optimal cache size for the problem.
@property (assign) CGFloat totalCacheHitCost;
@property (assign) CGFloat totalCacheMissCost;
@property (assign) NSUInteger cacheHitCount;
@property (assign) NSUInteger cacheMissCount;
@end


@implementation CacheNode

@synthesize objectID, accessCounter;

@end


#pragma mark -

@implementation CategoryCache

@synthesize managedObjectContext, cacheSize, cache, categoryEntityDescription, categoryNamePredicateTemplate;

- (instancetype)init {
    
    self = [super init];
    if (self != nil) {
        cacheSize = 15;
        _accessCounter = 0;
        cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.cacheHitCount > 0) NSLog(@"average cache hit cost:  %f", self.totalCacheHitCost/self.cacheHitCount);
    if (self.cacheMissCount > 0) NSLog(@"average cache miss cost: %f", self.totalCacheMissCost/self.cacheMissCount);
}

// Implement the "set" accessor rather than depending on @synthesize so that we can set up registration
// for context save notifications.
- (void)setManagedObjectContext:(NSManagedObjectContext *)aContext {
    
    if (managedObjectContext) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    }
    managedObjectContext = aContext;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
}

// When a managed object is first created, it has a temporary managed object ID. When the managed object context in which it was created is saved, the temporary ID is replaced with a permanent ID. The temporary IDs can no longer be used to retrieve valid managed objects. The cache handles the save notification by iterating through its cache nodes and removing any nodes with temporary IDs.
// While it is possible force Core Data to provide a permanent ID before an object is saved, using the method -[ NSManagedObjectContext obtainPermanentIDsForObjects:error:], this method incurrs a trip to the database, resulting in degraded performance - the very thing we are trying to avoid. 
- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    CacheNode *cacheNode = nil;
    NSMutableArray *keys = [NSMutableArray array];
    for (NSString *key in cache) {
        cacheNode = cache[key];
        if (cacheNode.objectID.temporaryID) {
            [keys addObject:key];
        }
    }
    [cache removeObjectsForKeys:keys];
}

- (NSEntityDescription *)categoryEntityDescription {
    
    if (categoryEntityDescription == nil) {
        categoryEntityDescription = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:managedObjectContext];
    }
    return categoryEntityDescription;
}

static NSString * const kCategoryNameSubstitutionVariable = @"NAME";

- (NSPredicate *)categoryNamePredicateTemplate {
    
    if (categoryNamePredicateTemplate == nil) {
        NSExpression *leftHand = [NSExpression expressionForKeyPath:@"name"];
        NSExpression *rightHand = [NSExpression expressionForVariable:kCategoryNameSubstitutionVariable];
        categoryNamePredicateTemplate = [[NSComparisonPredicate alloc] initWithLeftExpression:leftHand rightExpression:rightHand modifier:NSDirectPredicateModifier type:NSLikePredicateOperatorType options:0];   
    }
    return categoryNamePredicateTemplate;
}

// Undefine this macro to compare performance without caching.
#define USE_CACHING

- (Category *)categoryWithName:(NSString *)name {
    
    NSTimeInterval before = [NSDate timeIntervalSinceReferenceDate];
#ifdef USE_CACHING
    // Check cache.
    CacheNode *cacheNode = cache[name];
    if (cacheNode != nil) {
        // Cache hit, update access counter.
        cacheNode.accessCounter = _accessCounter++;
        Category *category = (Category *)[managedObjectContext objectWithID:cacheNode.objectID];
        _totalCacheHitCost += ([NSDate timeIntervalSinceReferenceDate] - before);
        _cacheHitCount++;
        return category;
    }
#endif
    // Cache missed, fetch from store -
    // if not found in store there is no category object for the name and we must create one.
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.categoryEntityDescription;
    NSPredicate *predicate = [self.categoryNamePredicateTemplate predicateWithSubstitutionVariables:@{kCategoryNameSubstitutionVariable: name}];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *fetchResults = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert1(fetchResults != nil, @"Unhandled error executing fetch request in import thread: %@", [error localizedDescription]);

    Category *category = nil;
    if (fetchResults.count > 0) {
        // Get category from fetch.
        category = fetchResults[0];
    } else if (fetchResults.count == 0) {
        // Category not in store, must create a new category object.
        category =
            [[Category alloc] initWithEntity:self.categoryEntityDescription
              insertIntoManagedObjectContext:managedObjectContext];
        category.name = name;
    }
#ifdef USE_CACHING
    // Add to cache.
    // First check to see if cache is full.
    if (cache.count >= cacheSize) {
        // Evict least recently used (LRU) item from cache.
        NSUInteger oldestAccessCount = UINT_MAX;
        NSString *key = nil, *keyOfOldestCacheNode = nil;
        for (key in cache) {
            CacheNode *tmpNode = cache[key];
            if (tmpNode.accessCounter < oldestAccessCount) {
                oldestAccessCount = tmpNode.accessCounter;
                keyOfOldestCacheNode = key;
            }
        }
        // Retain the cache node for reuse.
        cacheNode = cache[keyOfOldestCacheNode];
        // Remove from the cache.
        if (keyOfOldestCacheNode != nil)
            [cache removeObjectForKey:keyOfOldestCacheNode];
    } else {
        // Create a new cache node.
        cacheNode = [[CacheNode alloc] init];
    }
    cacheNode.objectID = category.objectID;
    cacheNode.accessCounter = _accessCounter++;
    cache[name] = cacheNode;
#endif
    _totalCacheMissCost += ([NSDate timeIntervalSinceReferenceDate] - before);
    _cacheMissCount++;
    return category;
}

@end
