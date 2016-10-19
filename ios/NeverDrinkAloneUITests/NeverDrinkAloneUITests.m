#import <Parse/Parse.h>
#import <XCTest/XCTest.h>

static NSString * const kTestAccountUsername = @"mrsloth";
static NSString * const kTestAccountPassword = @"mrsloth";

@interface NeverDrinkAloneUITests : XCTestCase

@end

@implementation NeverDrinkAloneUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    XCUIApplication *app = [XCUIApplication new];
    app.launchArguments = @[@"USE_TEST_ACCOUNT"];
    [app launch];
}

- (void)tearDown {
    [PFUser logOutInBackground];
    [super tearDown];
}

- (void)testDashboard {
    XCUIApplication *app = [XCUIApplication new];
    [app.buttons[@"Log In Button"] tap];
    XCUIElement *emailTextField = app.textFields[@"Email Text Field"];
    [emailTextField tap];
    [emailTextField typeText:kTestAccountUsername];
    XCUIElement *passwordTextField = app.secureTextFields[@"Password Text Field"];
    [passwordTextField tap];
    [passwordTextField typeText:kTestAccountPassword];
    [app.buttons[@"Action Button"] tap];
    
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:exists evaluatedWithObject:app.buttons[@"Meeting Card"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
