#import "NDAWeekdayPickerCell.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import <pop/POP.h>

@implementation NDAWeekdayPickerCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.weekdayLabel = [UILabel new];
  self.weekdayLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont datePickerWeekdayFontSize]];
  self.weekdayLabel.textColor = [UIColor nda_darkGrayColor];
  self.weekdayLabel.textAlignment = NSTextAlignmentCenter;

  self.weekdayWrapper = [UIView new];

  [self.weekdayWrapper addSubview:self.weekdayLabel];
  [self.contentView addSubview:self.weekdayWrapper];

  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.active = NO;
}

#pragma mark Setters

- (void)setWeekday:(NSInteger)weekday {
  _weekday = weekday;
  self.weekdayLabel.text = [self stringForWeekday:weekday];
}

- (void)setRange:(NSRange)range {
  _range = range;
  NSString *startingWeekday = [self stringForWeekday:(NSInteger)range.location];
  NSString *endingWeekday = [self stringForWeekday:(NSInteger)(range.location + range.length - 1)];
  self.weekdayLabel.text = [NSString stringWithFormat:@"%@ - %@", startingWeekday, endingWeekday];
}

- (void)setActive:(BOOL)active {
  _active = active;
  if (self.isActive) {
    self.weekdayWrapper.backgroundColor = [UIColor nda_accentColor];
    self.weekdayLabel.textColor = [UIColor whiteColor];
  } else {
    self.weekdayWrapper.backgroundColor = [UIColor whiteColor];
    self.weekdayLabel.textColor = [UIColor nda_darkGrayColor];
  }
}

#pragma mark Private

- (NSString *)stringForWeekday:(NSInteger)weekday {
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday fromDate:[NSDate date]];
  NSInteger daysToMonday = (9 - [components weekday]) % 7;
  NSDate *weekdayDate = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * (daysToMonday + weekday)];
  NSDateFormatter *formatter = [NSDateFormatter new];

  [formatter setDateFormat:@"EEE"];
  [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"ru"]];
  return [[formatter stringFromDate:weekdayDate] uppercaseString];
}

#pragma Animations

- (void)scaleAnimation {
  POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];

  scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3.f, 3.f)];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.f, 1.f)];
  scaleAnimation.springBounciness = 5.f;
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

@end
