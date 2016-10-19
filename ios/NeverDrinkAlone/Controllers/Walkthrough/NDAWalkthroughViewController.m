#import "NDAWalkthroughViewController.h"

#import "NDAOnboardingContentViewController.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"

@implementation NDAWalkthroughViewController

#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.navigationController) {
    self.navigationController.navigationBarHidden = YES;
  }
}

- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler {
  self = [super initWithContents:nil];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor nda_primaryColor];

  NDAOnboardingContentViewController *firstPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:@"Never Drink Alone" subtitleText:NSLocalizedString(@"Одно деловое знакомство в день с самыми интересными людьми в Алматы!", nil) image:[UIImage imageNamed:@"GlassIcon"] showButton:NO];

  NDAOnboardingContentViewController *secondPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:NSLocalizedString(@"Расскажите о себе", nil) subtitleText:NSLocalizedString(@"Укажите ваш университет и напишите краткую запоминающуюся биографию.", nil) image:[UIImage imageNamed:@"ProfileIcon"] showButton:NO];

  NDAOnboardingContentViewController *thirdPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:NSLocalizedString(@"Поделитесь своими предпочтениями", nil) subtitleText:NSLocalizedString(@"Добавьте ваши интересы, любимые места для встречи в Алматы и промежутки времени, когда вы свободны для встречи в течение недели.", nil) image:[UIImage imageNamed:NSLocalizedString(@"TagsIcon", nil)] showButton:NO];

  NDAOnboardingContentViewController *fourthPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:NSLocalizedString(@"Одна встреча в день", nil) subtitleText:NSLocalizedString(@"Получайте одно предложение для встречи каждые 24 часа.", nil) image:[UIImage imageNamed:@"ClockIcon"] showButton:NO];

  NDAOnboardingContentViewController *fifthPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:NSLocalizedString(@"Принимайте решения", nil) subtitleText:NSLocalizedString(@"Вы можете согласиться на встречу (+1 в карму) или отказаться от нее (-2 от кармы).", nil) image:[UIImage imageNamed:@"BellIcon"] showButton:NO];

  NDAOnboardingContentViewController *sixthPage = [[NDAOnboardingContentViewController alloc] initWithTitleText:NSLocalizedString(@"Поддерживайте свою карму", nil) subtitleText:NSLocalizedString(@"Ваша изначальная карма равна +10. Если карма достигает нуля, то отказываться от встреч уже нельзя.", nil) image:[UIImage imageNamed:@"BadgeIcon"] showButton:YES];

  self.viewControllers = @[firstPage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage];

  self.titleColor = [UIColor whiteColor];
  self.subtitleColor = [UIColor whiteColor];
  self.titleFontSize = [UIFont largeTextFontSize];
  self.subtitleFontSize = [UIFont mediumTextFontSize];
  self.continueButtonColor = [UIColor whiteColor];
  self.shouldFadeTransitions = NO;
  self.allowSkipping = NO;
  self.skipButtonText = NSLocalizedString(@"Пропустить", nil);
  self.skipHandler = completionHandler;

  return self;
}

@end
