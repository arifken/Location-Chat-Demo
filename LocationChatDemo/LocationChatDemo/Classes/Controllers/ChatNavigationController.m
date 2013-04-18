/**
* Copyright (C) 2013 Andrew Rifken
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
*/

#import <CoreLocation/CoreLocation.h>
#import "ChatNavigationController.h"
#import "Client.h"
#import "ChatViewController.h"
#import "Constants.h"
#import "Message.h"
#import "MapViewController.h"


@implementation ChatNavigationController

#pragma mark -
#pragma mark Ctor
//============================================================================================================


- (id)init {
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    self = [self initWithRootViewController:chatViewController];
    if (self) {
        _chatViewController = chatViewController;
    }

    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.connection = [[ServerConnection alloc] init];
        self.connection.delegate = self;

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }

    return self;
}


#pragma mark -
#pragma mark Lifecycle
//============================================================================================================


- (void)viewDidLoad {
    [super viewDidLoad];

    // We want to observe changes in connectionState so we know whether or not to enable/disable the UI. If the
    // socket gets disconnected, the state will change and we can automatically notify the relevant views
    [self.connection addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:NULL];

    self.signInView = [[SignInView alloc] init];
    self.signInView.delegate = self;
    self.signInView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.signInView];


    NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

    [layoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.signInView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0f
                                                               constant:0.0]];


    [layoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.signInView
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1.0f
                                                               constant:-80.0]];

    [self.view addConstraints:layoutConstraints];


    [self.locationManager startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self connectIfNeeded];
}

- (void)dealloc {
    [self.locationManager stopUpdatingLocation];
    [self.connection removeObserver:self forKeyPath:@"connectionState"];
}


#pragma mark -
#pragma mark Actions
//============================================================================================================

/**
* Connect to the chat server (so long as we are not signed in or in the process of signing in..
* There are two parts to the sign in process
*   1. Connect to the socket
*   2. Sign in by setting the socket's "client ID" (cid)
*/
- (void)connectIfNeeded {
    if (self.connection.connectionState == ChatConnectionStateDisconnected) {
        // check if we have a client ID set
        if (self.connection.clientId) {
            [self.connection connect];
        }
    }
}

/**
* Send a 'disconnect' message to the socket. We will get a callback from the ServerConnection when we have been
* successfully disconnected
*/
- (void)disconnect {
    [self.connection disconnect];
}

#pragma mark -
#pragma mark Connection Events
//============================================================================================================


- (void)chatConnection:(ServerConnection *)conn didReceiveChatMessage:(Message *)message {
    // if the message has a location, update the client's location...
    Client *client = [self.connection clientForID:message.clientId];
    if (message.location) {
        client.location = message.location;
    } else {
        message.location = client.location;
    }

    [_chatViewController addMessage:message];
}


- (void)chatConnection:(ServerConnection *)conn didReceiveLocation:(CLLocation *)loc forClientID:(NSString *)clientId {
    Client *client = [self.connection clientForID:clientId];
    if (client) {
        client.location = loc;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidDUpdateLocationNotification object:nil userInfo:@{
            kClientKey : client
    }];
}

- (CLLocation *)chatConnectionCurrentLocation:(ServerConnection *)conn {
    return self.currentLocation;
}

- (void)chatConnection:(ServerConnection *)conn clientDidConnect:(Client *)client {
    // allow the map and client view controllers to update accordingly
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidConnectNotification object:nil userInfo:@{
            kClientKey : client
    }];
}

- (void)chatConnection:(ServerConnection *)conn clientDidDisconnect:(NSString *)clientId {
    // allow the map and client view controllers to update accordingly
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidDisconnectNotification object:nil userInfo:@{
            kClientIDKey : clientId
    }];

    // if we disconnected, show sign in prompt
//    if ([clientId caseInsensitiveCompare:[self.connection clientId]] == NSOrderedSame) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.connection.clientId = nil;
//        });
//    }
}

- (void)chatConnnection:(ServerConnection *)conn didReceiveError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
    });
}


#pragma mark -
#pragma mark Other Events
//============================================================================================================


- (void)signInView:(SignInView *)signInView didLoginWithClientID:(NSString *)clientID {
    self.connection.clientId = clientID;
    [self connectIfNeeded];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.connection && [keyPath isEqualToString:@"connectionState"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.signInView.hidden = (self.connection.connectionState != ChatConnectionStateDisconnected);
        });
    }
}



#pragma mark -
#pragma mark Location delegate
//============================================================================================================

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // if first location, send it to the group
    if (!self.currentLocation) {
        [self.connection sendLocation:newLocation];
    }
    self.currentLocation = newLocation;

    // update self in clients array
    Client *me = [self.connection myClient];
    @synchronized (me) {
        me.location = newLocation;
    }

}


- (void)showClientOnMap:(NSString *)clientId {
    // ask for location update
    [self.connection requestLocationForClientWithID:clientId];

    void(^showMapController)() = [^{
        MapViewController *mapViewController = [[MapViewController alloc] init];
        mapViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:mapViewController animated:YES completion:^{
            // on complete, focus on selected client
            [mapViewController zoomToClientWithID:clientId];
        }];
    } copy];


    showMapController = [showMapController copy];

    // dismiss current modal controller, show map controller
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            showMapController();
        }];
    } else {
        showMapController();
    }


}
@end