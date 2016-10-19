#import "NSDate+NDAHelpers.h"

@implementation NSDate (NDAHelpers)

#pragma mark Public

- (NSInteger)daysFromToday {
  NSDate *fromDate;
  NSDate *toDate;
  NSCalendar *calendar = [NSCalendar currentCalendar];

  [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:nil forDate:[NSDate date]];
  [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:nil forDate:self];

  NSDateComponents *difference = [calendar components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
  return [difference day];
}

- (NSString *)weekdayString {
  return [[self stringFromTemplate:@"EEE"] uppercaseString];
}

- (NSString *)dayString {
  return [self stringFromTemplate:@"d"];
}

- (NSString *)dateString {
  return [self stringFromTemplate:@"MMMMd"];
}

- (NSString *)fullDate {
  return [NSString stringWithFormat:@"%@ (%@)", [self dateString], [self stringFromTemplate:@"EEEE"]];
}

- (NSString *)birthdayDate {
  return [self stringFromTemplate:@"d MMMM, yyyy"];
}

+ (instancetype)dateForHour:(NSInteger)hour {
  NSDate *date = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSCalendarUnit preservedComponents = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *components = [calendar components:preservedComponents fromDate:date];
  NSDate *dateForHour = [[calendar dateFromComponents:components] dateByAddingTimeInterval:60 * 60 * hour];
  NSInteger currentHour = [[calendar components:NSCalendarUnitHour fromDate:date] hour];

  if (currentHour >= hour) {
    dateForHour = [dateForHour dateByAddingTimeInterval:60 * 60 * 24];
  }
  return dateForHour;
}

- (NSInteger)ageFromDate {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:self toDate:[NSDate date] options:0];
  return [components year];
}

- (NSTimeInterval)timeLeftToDate {
  return [self timeIntervalSinceDate:[NSDate date]];
}

- (NSString *)formattedTimeLeftToDate {
  NSInteger time = (NSInteger)[self timeLeftToDate];
  NSInteger seconds = time % 60;
  NSInteger minutes = (time / 60) % 60;
  NSInteger hours = time / 3600;
  return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

+ (NSInteger)currentHour {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]];
  return [components hour];
}

- (NSString *)messageString {
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  return [formatter stringFromDate:self];
}

+ (instancetype)dateFromMessageString:(NSString *)messageString {
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  return [formatter dateFromString:messageString];
}

- (NSString *)timeAgo {
  NSDate *now = [NSDate date];
  NSInteger deltaSeconds = (NSInteger)fabs([self timeIntervalSinceDate:now]);
  NSInteger deltaMinutes = deltaSeconds / 60;
  NSInteger minutes;

  if (deltaSeconds < 5) {
    return NSLocalizedString(@"Только что", nil);
  } else if (deltaSeconds < 60) {
    return [NSString stringWithFormat:@"%@ %@ %@", @(deltaSeconds), [self getNumEnding:deltaSeconds endings:@[NSLocalizedString(@"секунду", nil), NSLocalizedString(@"секунды", nil), NSLocalizedString(@"секунд", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaSeconds < 120) {
    return NSLocalizedString(@"Минуту назад", nil);
  } else if (deltaMinutes < 60) {
    return [NSString stringWithFormat:@"%@ %@ %@", @(deltaMinutes), [self getNumEnding:deltaMinutes endings:@[NSLocalizedString(@"минуту", nil), NSLocalizedString(@"минуты", nil), NSLocalizedString(@"минут", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaMinutes < 120) {
    return NSLocalizedString(@"Час назад", nil);
  } else if (deltaMinutes < (24 * 60)) {
    minutes = (NSInteger)floor(deltaMinutes / 60);
    return [NSString stringWithFormat:@"%@ %@ %@", @(minutes), [self getNumEnding:minutes endings:@[NSLocalizedString(@"час", nil), NSLocalizedString(@"часа", nil), NSLocalizedString(@"часов", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaMinutes < (24 * 60 * 2)) {
    return NSLocalizedString(@"Вчера", nil);
  } else if (deltaMinutes < (24 * 60 * 7)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24));
    return [NSString stringWithFormat:@"%@ %@ %@", @(minutes), [self getNumEnding:minutes endings:@[NSLocalizedString(@"день", nil), NSLocalizedString(@"дня", nil), NSLocalizedString(@"дней", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaMinutes < (24 * 60 * 14)) {
    return NSLocalizedString(@"Неделю назад", nil);
  } else if (deltaMinutes < (24 * 60 * 31)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 7));
    return [NSString stringWithFormat:@"%@ %@ %@", @(minutes), [self getNumEnding:minutes endings:@[NSLocalizedString(@"неделю", nil), NSLocalizedString(@"недели", nil), NSLocalizedString(@"недель", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaMinutes < (24 * 60 * 61)) {
    return NSLocalizedString(@"Месяц назад", nil);
  } else if (deltaMinutes < (24 * 60 * 365.25)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 30));
    return [NSString stringWithFormat:@"%@ %@ %@", @(minutes), [self getNumEnding:minutes endings:@[NSLocalizedString(@"месяц", nil), NSLocalizedString(@"месяца", nil), NSLocalizedString(@"месяцев", nil)]], NSLocalizedString(@"назад", nil)];
  } else if (deltaMinutes < (24 * 60 * 731)) {
    return NSLocalizedString(@"Год назад", nil);
  } else {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 365));
    return [NSString stringWithFormat:@"%@ %@ %@", @(minutes), [self getNumEnding:minutes endings:@[NSLocalizedString(@"год", nil), NSLocalizedString(@"года", nil), NSLocalizedString(@"лет", nil)]], NSLocalizedString(@"назад", nil)];
  }
}

#pragma mark Helpers

- (NSString *)getNumEnding:(NSInteger)number endings:(NSArray *)endings {
  NSString *ending;
  number = number % 100;
  if (number >= 11 && number <= 19) {
    ending = endings[2];
  } else {
    switch (number % 10) {
      case 1:
        ending = endings[0];
        break;
      case 2:
        ending = endings[1];
        break;
      case 3:
        ending = endings[1];
        break;
      case 4:
        ending = endings[1];
        break;
      default:
        ending = endings[2];
        break;
    }
  }
  return ending;
}

- (NSString *)stringFromTemplate:(NSString *)template {
  NSLocale *ruLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
  NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:ruLocale];
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.locale = ruLocale;
  formatter.dateFormat = dateFormat;
  return [formatter stringFromDate:self];
}

@end
