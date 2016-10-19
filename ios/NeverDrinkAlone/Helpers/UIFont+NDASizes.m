#import "UIFont+NDASizes.h"
#import "NDAMacros.h"

@implementation UIFont (NDASizes)

+ (CGFloat)extraSmallTextFontSize {
  if (IS_IPHONE_6P) {
    return 14;
  } else if (IS_IPHONE_6) {
    return 13;
  } else {
    return 12;
  }
}

+ (CGFloat)smallTextFontSize {
  if (IS_IPHONE_6P) {
    return 16;
  } else if (IS_IPHONE_6) {
    return 15;
  } else if (IS_IPHONE_5) {
    return 14;
  } else {
    return 13;
  }
}

+ (CGFloat)mediumTextFontSize {
  if (IS_IPHONE_6P) {
    return 17;
  } else if (IS_IPHONE_6) {
    return 16;
  } else if (IS_IPHONE_5) {
    return 15;
  } else {
    return 14;
  }
}

+ (CGFloat)largeTextFontSize {
  if (IS_IPHONE_6P) {
    return 19;
  } else if (IS_IPHONE_6) {
    return 18;
  } else if (IS_IPHONE_5) {
    return 17;
  } else {
    return 16;
  }
}

+ (CGFloat)extraLargeTextFontSize {
  if (IS_IPHONE_6P) {
    return 25;
  } else if (IS_IPHONE_6) {
    return 24;
  } else if (IS_IPHONE_5) {
    return 23;
  } else {
    return 22;
  }
}

+ (CGFloat)smallButtonFontSize {
  if (IS_IPHONE_6P) {
    return 17;
  } else if (IS_IPHONE_6) {
    return 16;
  } else {
    return 15;
  }
}

+ (CGFloat)mediumButtonFontSize {
  if (IS_IPHONE_6P) {
    return 21;
  } else if (IS_IPHONE_6) {
    return 20;
  } else {
    return 19;
  }
}

+ (CGFloat)bigButtonFontSize {
  if (IS_IPHONE_6P) {
    return 27;
  } else if (IS_IPHONE_6) {
    return 26;
  } else {
    return 25;
  }
}

+ (CGFloat)datePickerWeekdayFontSize {
  return 17;
}

+ (CGFloat)datePickerNumberFontSize {
  return 22;
}

+ (CGFloat)timeSlotCellFontSize {
  return 22;
}

+ (CGFloat)authorizationButtonFontSize {
  if (IS_IPHONE_6P) {
    return 19;
  } else if (IS_IPHONE_6) {
    return 18;
  } else {
    return 17;
  }
}

+ (CGFloat)karmaFontSize {
  if (IS_IPHONE_6P) {
    return 90;
  } else if (IS_IPHONE_6) {
    return 85;
  } else {
    return 80;
  }
}

+ (CGFloat)menuButtonFontSize {
  if (IS_IPHONE_6P) {
    return 26;
  } else if (IS_IPHONE_6) {
    return 25;
  } else {
    return 24;
  }
}

+ (CGFloat)navigationBarTitleFontSize {
  return 17;
}

@end
