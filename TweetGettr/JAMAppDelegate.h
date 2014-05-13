
#import <UIKit/UIKit.h>

@interface JAMAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) NSString *authorizationToken;

+ (instancetype)shared;

@end
