
#import <UIKit/UIKit.h>

@interface TGAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) NSString *authorizationToken;

+ (instancetype)shared;

@end
