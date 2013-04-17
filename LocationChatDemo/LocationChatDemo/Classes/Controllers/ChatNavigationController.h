/*!
 * \file    NavController
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ChatConnection.h"
#import "SignInView.h"

@class CLLocationManager;
@class CLLocation;
@class Client;
@class ChatViewController;
@class SignInView;

@interface ChatNavigationController : UINavigationController <CLLocationManagerDelegate, ChatConnectionDelegate, SignInViewDelegate> {
    ChatViewController *_chatViewController;
}

@property(strong) CLLocation *currentLocation;
@property(strong) CLLocationManager *locationManager;
@property(strong) ChatConnection *connection;
@property(strong) SignInView *signInView;

- (void)showClientOnMap:(NSString *)string;
@end