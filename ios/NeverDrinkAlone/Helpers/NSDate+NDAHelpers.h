@interface NSDate (NDAHelpers)

- (NSInteger)daysFromToday;
- (NSString *)weekdayString;
- (NSString *)dayString;
- (NSString *)dateString;
- (NSString *)fullDate;
- (NSString *)birthdayDate;
- (NSInteger)ageFromDate;
- (NSTimeInterval)timeLeftToDate;
- (NSString *)formattedTimeLeftToDate;
+ (NSInteger)currentHour;
+ (instancetype)dateForHour:(NSInteger)hour;
- (NSString *)messageString;
+ (instancetype)dateFromMessageString:(NSString *)messageString;
- (NSString *)timeAgo;

@end
