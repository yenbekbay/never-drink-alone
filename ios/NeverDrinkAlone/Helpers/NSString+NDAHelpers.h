@interface NSString (NDAHelpers)

- (CGSize)sizeWithFont:(UIFont *)font width:(CGFloat)width;
+ (NSString *)getNumEnding:(NSInteger)number endings:(NSArray *)endings;

@end
