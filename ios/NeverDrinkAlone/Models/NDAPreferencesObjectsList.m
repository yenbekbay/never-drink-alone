#import "NDAPreferencesObjectsList.h"

#import "NDAConstants.h"
#import "NDAInterest.h"
#import "NDAMacros.h"
#import "NDAMeetingPlace.h"

@implementation NDAPreferencesObjectsList

#pragma mark Public

- (instancetype)initWithObjects:(NSArray *)objects type:(NDAPreferencesObjectsListType)type {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.type = type;
  // Set the maximum allowed number of rows depending on the size of the device
  if (self.type == NDAPreferencesObjectsListInterests) {
    if (IS_IPHONE_6P) {
      self.maxRows = 9;
    } else if (IS_IPHONE_6) {
      self.maxRows = 8;
    } else {
      self.maxRows = 6;
    }
  } else {
    if (IS_IPHONE_6P) {
      self.maxRows = 6;
    } else if (IS_IPHONE_6) {
      self.maxRows = 5;
    } else {
      self.maxRows = 4;
    }
  }
  // Only call the setter if there are objects to avoid a potential crash
  if (objects) {
    self.all = [objects mutableCopy];
  }

  return self;
}

- (void)setAll:(NSMutableArray *)all {
  _all = all;
  self.showing = [self forDisplay];
  self.shown = [self.showing mutableCopy];
}

- (NSMutableArray *)forDisplay {
  return [self forDisplay:self.all];
}

- (void)showOthers {
  NSArray *notShownObjects = [self notShownObjects];

  self.showing = [notShownObjects mutableCopy];
  [self.shown addObjectsFromArray:notShownObjects];
}

- (void)removeAddedObjects:(NSArray *)added {
  NSMutableArray *shownObjects = [self.shown mutableCopy];

  [shownObjects removeObjectsInArray:self.showing];
  [self.all removeObjectsInArray:added];
  NSMutableArray *allObjects = [self.all mutableCopy];
  [allObjects removeObjectsInArray:shownObjects];
  self.showing = [self forDisplay:allObjects];
}

- (NSArray *)notShownObjects {
  NSMutableArray *allObjects = [self.all mutableCopy];

  [allObjects removeObjectsInArray:self.shown];
  return [self forDisplay:allObjects];
}

- (NSInteger)showingCount {
  return (NSInteger)self.showing.count;
}

- (id)showingObjectForIndexPath:(NSIndexPath *)indexPath {
  return self.showing[(NSUInteger)indexPath.row];
}

- (void)reset {
  self.all = _all;
  if (self.type == NDAPreferencesObjectsListMeetingPlaces) {
    // Calling the setter restarts the cycle
    self.all = [[self sortedByDistance:self.all] mutableCopy];
  }
}

- (void)removeObject:(PFObject *)object {
  NSPredicate *searchPredicate;

  if (self.type == NDAPreferencesObjectsListInterests) {
    // Match the name property of the NDAInterest object
    searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", [(NDAInterest *)object name]];
  } else {
    // Match both the name and the address properties of the NDAMeetingPlace object
    searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ AND address CONTAINS[cd] %@", [(NDAMeetingPlace *)object name], [(NDAMeetingPlace *)object address]];
  }
  NSArray *foundObjects = [self.all filteredArrayUsingPredicate:searchPredicate];
  if (foundObjects.count > 0) {
    // Remove the matched object (first in the array returned by the filter)
    [self.all removeObject:foundObjects[0]];
  }
}

- (void)addObject:(PFObject *)object {
  [self.all addObject:object];
}

#pragma mark Private

- (NSMutableArray *)forDisplay:(NSArray *)objects {
  NSMutableArray *choppedObjects = [NSMutableArray new];
  NSUInteger rows = 0;
  CGFloat currentRowWidth = 0;
  // Total width of the row in the collection view containing the objects
  CGFloat limit = CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2;

  if (self.type == NDAPreferencesObjectsListInterests) {
    for (PFObject *object in objects) {
      // Calculate the potential number of rows the objects would create
      CGFloat objectWidth = [(NDAInterest *)object sizeForCell].width + kPreferencesObjectCellSpacing;
      if (currentRowWidth == 0 || currentRowWidth + objectWidth > limit) {
        rows++;
        currentRowWidth = 10 + objectWidth;
        // Break the loop if the maximum allowed number of rows is reached
        if (rows <= self.maxRows) {
          [choppedObjects addObject:object];
        } else {
          break;
        }
      } else {
        currentRowWidth += objectWidth;
        [choppedObjects addObject:object];
      }
    }
  } else {
    // Since NDAMeetingPlaceCells take up one entire row in the collection view,
    // there is no need to calculate the number of rows -- it is the same as the number of objects
    for (NSUInteger i = 0; i < objects.count; i++) {
      if (i < self.maxRows) {
        [choppedObjects addObject:objects[i]];
      } else {
        break;
      }
    }
  }
  return choppedObjects;
}

- (NSArray *)sortedByDistance:(NSArray *)objects {
  return [objects sortedArrayUsingComparator:^(NDAMeetingPlace *i1, NDAMeetingPlace *i2) {
    CLLocationDistance distance1 = i1.distance;
    CLLocationDistance distance2 = i2.distance;
    if (distance1 < distance2) {
      return NSOrderedAscending;
    } else if (distance1 > distance2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

@end
