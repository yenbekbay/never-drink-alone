#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(6);
captureLocalizedScreenshot("0-DashboardView");
window.scrollViews()[0].scrollViews()[0].buttons()["Meeting Card"].tap();
target.delay(1);
captureLocalizedScreenshot("1-MeetingView");
app.navigationBar().buttons()[0].tap();
app.navigationBar().buttons()["CogIcon"].tap();
target.delay(1);
captureLocalizedScreenshot("2-SettingsView");
window.scrollViews()[0].tableViews()[0].cells()[0].tap();
window.scrollViews()[0].collectionViews()[0].cells()[1].tap();
captureLocalizedScreenshot("3-InterestsView");
