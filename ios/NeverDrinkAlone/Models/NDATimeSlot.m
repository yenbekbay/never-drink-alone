#import "NDATimeSlot.h"

#import "NDAConstants.h"

@implementation NDATimeSlot

@dynamic weekday;
@dynamic startingHour;

#pragma mark Initialization

- (instancetype)initWithWeekday:(NSNumber *)weekday startingHour:(NSNumber *)startingHour {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.weekday = weekday;
  self.startingHour = startingHour;

  return self;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  NDATimeSlot *timeSlot = (NDATimeSlot *)object;
  if ([timeSlot isDataAvailable]) {
    return [self.weekday isEqualToNumber:timeSlot.weekday] && [self.startingHour isEqualToNumber:timeSlot.startingHour];
  } else {
    return self == object;
  }
}

#pragma mark Public

- (CGSize)sizeForCell {
  return CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2 - kPreferencesObjectCellSpacing * 2, kTimeSlotCellHeight);
}

- (NSDate *)date {
  NSDate *date = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSCalendarUnit preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitDay);
  NSDateComponents *components = [calendar components:preservedComponents fromDate:date];
  NSDate *normalizedDate = [calendar dateFromComponents:components];

  NSInteger weekdayToday = [components weekday];
  NSInteger desiredWeekday = [self.weekday integerValue] + 2;

  if (desiredWeekday == 8) {
    desiredWeekday = 0;
  }
  NSInteger daysToWeekday = (7 + desiredWeekday - weekdayToday) % 7;

  return [normalizedDate dateByAddingTimeInterval:60 * 60 * 24 * daysToWeekday + 60 * 60 * [self.startingHour integerValue]];
}

#pragma mark PFSubclassing

+ (void)load {
  [self registerSubclass];
}

+ (NSString *)parseClassName {
  return @"TimeSlot";
}

@end
