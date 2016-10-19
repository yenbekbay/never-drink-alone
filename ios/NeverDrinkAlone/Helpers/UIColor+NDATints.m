#import "UIColor+NDATints.h"

@implementation UIColor (NDATints)

#define AGEColorImplement(COLOR_NAME, RED, GREEN, BLUE)    \
  + (UIColor *)COLOR_NAME {    \
    static UIColor *COLOR_NAME ## _color;    \
    static dispatch_once_t COLOR_NAME ## _onceToken;   \
    dispatch_once(&COLOR_NAME ## _onceToken, ^{    \
      COLOR_NAME ## _color = [UIColor colorWithRed:RED green:GREEN blue:BLUE alpha:1.0];  \
    }); \
    return COLOR_NAME ## _color;  \
  }

AGEColorImplement(nda_primaryColor, 0.21f, 0.6f, 0.65f)
AGEColorImplement(nda_complementaryColor, 0.22f, 0.78f, 0.71f)
AGEColorImplement(nda_accentColor, 0.96f, 0.35f, 0.41f)
AGEColorImplement(nda_greenColor, 0.13f, 0.75f, 0.39f)
AGEColorImplement(nda_lightGrayColor, 0.95f, 0.95f, 0.95f)
AGEColorImplement(nda_darkGrayColor, 0.71f, 0.71f, 0.71f)
AGEColorImplement(nda_textColor, 0.51f, 0.51f, 0.51f)
AGEColorImplement(nda_facebookColor, 0.25f, 0.38f, 0.66f)
AGEColorImplement(nda_linkedinColor, 0, 0.47f, 0.71f)
AGEColorImplement(nda_spaceGrayColor, 0.17f, 0.19f, 0.23f);

@end
