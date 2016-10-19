#import "NDAInterest.h"

#import "NDAConstants.h"
#import "NSString+NDAHelpers.h"
#import "UIFont+NDASizes.h"

@implementation NDAInterest

@dynamic name;
@dynamic similarInterests;

- (instancetype)initWithName:(NSString *)name similarInterests:(NSArray *)similarInterests {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.name = name;
  self.similarInterests = similarInterests;

  return self;
}

- (CGSize)sizeForCell {
  CGSize nameSize = [self.name sizeWithFont:[UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]] width:CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2 - kInterestCellPadding.left - kCellIconSpacing - kInterestCellCheckIconSize.width - kInterestCellPadding.right];

  return CGSizeMake(kInterestCellPadding.left + nameSize.width + kCellIconSpacing + kInterestCellCheckIconSize.width + kInterestCellPadding.right, kInterestCellPadding.top + nameSize.height + kInterestCellPadding.bottom);
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  NDAInterest *interest = (NDAInterest *)object;
  if ([interest isDataAvailable]) {
    return [self.name isEqualToString:interest.name];
  } else {
    return self == object;
  }
}

#pragma mark PFSubclassing

+ (void)load {
  [self registerSubclass];
}

+ (NSString *)parseClassName {
  return @"Interest";
}

@end
