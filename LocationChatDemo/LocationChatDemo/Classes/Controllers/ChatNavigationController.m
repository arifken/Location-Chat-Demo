/*!
 * \file    NavController
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <CoreLocation/CoreLocation.h>
#import "ChatNavigationController.h"
#import "Client.h"
#import "ChatViewController.h"
#import "Constants.h"
#import "ChatMessage.h"
#import "MapViewController.h"


@implementation ChatNavigationController

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
        self.connection = [[ChatConnection alloc] init];
        self.connection.delegate = self;

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

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

- (void)connectIfNeeded {
// if we aren't signed in or in the process of signing in...
    if (self.connection.connectionState == ChatConnectionStateDisconnected) {
        // check if we have a client ID set
        if (self.connection.clientId) {
            [self.connection connect];
        }
    }
}


- (void)dealloc {
    NSLog(@"dealloc");
    [self.locationManager stopUpdatingLocation];
    [self.connection removeObserver:self forKeyPath:@"connectionState"];
}

- (void)disconnect {
    [self.connection disconnect];
}

#pragma mark -
#pragma mark Clients
//============================================================================================================



#pragma mark -
#pragma mark Connection Events
//============================================================================================================


- (void)chatConnection:(ChatConnection *)conn didReceiveMessage:(ChatMessage *)message {
    // if the message has a location, update the client's location...
    Client *client = [self.connection clientForID:message.clientId];
    if (message.location) {
        client.location = message.location;
    } else {
        message.location = client.location;
    }

    [_chatViewController addMessage:message];
}


- (void)chatConnection:(ChatConnection *)conn didReceiveLocation:(CLLocation *)loc forClientID:(NSString *)clientId {
    NSLog(@"need to update location: %@ for client: %@", loc, clientId);
    Client *client = [self.connection clientForID:clientId];
    if (client) {
        client.location = loc;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidDUpdateLocationNotification object:nil userInfo:@{
            kClientKey : client
    }];
}

- (CLLocation *)chatConnectionCurrentLocation:(ChatConnection *)conn {
    return self.currentLocation;
}

- (void)chatConnection:(ChatConnection *)conn clientDidConnect:(Client *)client {
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidConnectNotification object:nil userInfo:@{
            kClientKey : client
    }];
}

- (void)chatConnection:(ChatConnection *)conn clientDidDisconnect:(NSString *)clientId {
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *) kClientDidDisconnectNotification object:nil userInfo:@{
            kClientIDKey : clientId
    }];

    // if we disconnected, show sign in prompt
    if ([clientId caseInsensitiveCompare:[self.connection clientId]] == NSOrderedSame) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connection.clientId = nil;
            [self connectIfNeeded];
        });
    }
}

- (void)chatConnnection:(ChatConnection *)conn didReceiveError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
    });
}


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

    void(^showMapController)() = ^{
        MapViewController *mapViewController = [[MapViewController alloc] init];
        mapViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:mapViewController animated:YES completion:^{
            // on complete, focus on selected client
            [mapViewController zoomToClientWithID:clientId];
        }];
    };


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