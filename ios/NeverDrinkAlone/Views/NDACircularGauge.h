@interface NDACircularGauge : UIView

/**
 * Represents the displayed progress value. Set it to update the progress indicator.
 * Pass a float number between 0.0 and 1.0.
 */
@property (nonatomic) CGFloat value;
/**
 * The color which is used to draw the progress indicator. Use UIAppearance to
 * style according your needs.
 */
@property (nonatomic) UIColor *color;
/**
 * The stroke width ratio is used to calculate the circle thickness regarding the
 * actual size of the progress indicator view. When setting this, strokeWidth is
 * ignored.
 */
@property (nonatomic) CGFloat strokeWidthRatio;
/**
 * If you'd like to specify the stroke thickness of the progress indicator circle
 * explicitly, use the strokeWidth property. When setting this, strokeWidthRatio
 * is ignored.
 */
@property (nonatomic) CGFloat strokeWidth;

@end
