@protocol NDAEditBiographyViewControllerDelegate <NSObject>
@required
- (void)didFinishEditingBiographyWithText:(NSString *)text;
@end

@interface NDAEditBiographyViewController : UIViewController

#pragma mark Properties

@property (weak, nonatomic) id<NDAEditBiographyViewControllerDelegate> delegate;

#pragma mark Methods

+ (CGSize)viewSize;

@end
