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

#import "MapViewController.h"
#import "ChatNavigationController.h"
#import "Client.h"
#import "NSDate+Chat.h"
#import "Constants.h"
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@implementation MapViewController


#pragma mark -
#pragma mark Lifecycle
//============================================================================================================

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    //---------------------------------------- Configure observers ------------------------------------------------------

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidConnect:)
                                                 name:(NSString *) kClientDidConnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidDisconnect:)
                                                 name:(NSString *) kClientDidDisconnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidUpdateLocation:)
                                                 name:(NSString *) kClientDidDUpdateLocationNotification
                                               object:nil];


    //---------------------------------------- View Setup ------------------------------------------------------

    self.view.backgroundColor = [UIColor whiteColor];


    self.toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *chatButton = [[UIBarButtonItem alloc] initWithTitle:@"Chat" style:UIBarButtonItemStyleBordered target:self action:@selector(chatButtonTapped:)];
    self.toolbar.items = @[space, chatButton];
    [self.view addSubview:self.toolbar];


    self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:nil];
    self.mapView.myLocationEnabled = YES;
    [self.view addSubview:self.mapView];


    //---------------------------------------- Auto Layout ------------------------------------------------------

    UIView *toolbar = self.toolbar;
    UIView *mapView = self.mapView;

    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    mapView.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[toolbar][mapView(>=0)]|"
                                                                                   options:0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(toolbar, mapView)]];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[toolbar]|"
                                                                                   options:0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(toolbar)]];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[mapView]|"
                                                                                   options:0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(mapView)]];

    [self.view addConstraints:layoutConstraints];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *clients = [self clients];
    [self.mapView clear];


    for (Client *client in clients) {
        if (client.location) {
            GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
            options.position = client.location.coordinate;
            options.title = client.clientId;
            options.snippet = [client.location.timestamp chatTimestamp];
            [self.mapView addMarkerWithOptions:options];
        }
    }

    [self zoomToFitAnnotations];

}

#pragma mark -
#pragma mark Actions
//============================================================================================================

/**
* Updates the camera position of within the map such that all the annotations (connected users' pins) are visible
*/
- (void)zoomToFitAnnotations {
    CLLocationCoordinate2D minPoint;
    CLLocationCoordinate2D maxPoint;

    BOOL first = YES;
    for (id <GMSMarker> marker in [self.mapView markers]) {
        if (first) {
            minPoint = marker.position;
            maxPoint = marker.position;
            first = NO;
        }


        // check min points
        if (marker.position.latitude < minPoint.latitude) {
            minPoint.latitude = marker.position.latitude;
        }

        if (marker.position.longitude < minPoint.longitude) {
            minPoint.longitude = marker.position.longitude;
        }


        // check max points
        if (marker.position.latitude > maxPoint.latitude) {
            maxPoint.latitude = marker.position.latitude;
        }

        if (marker.position.longitude > maxPoint.longitude) {
            maxPoint.longitude = marker.position.longitude;
        }
    }

    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(
            minPoint.latitude + ((maxPoint.latitude - minPoint.latitude) * 0.5),
            minPoint.longitude + ((maxPoint.longitude - minPoint.longitude) * 0.5)
    );

    GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:center.latitude longitude:center.longitude zoom:6];

    [self.mapView setCamera:cameraPosition];
}


/**
* Updates the camera position by focusing on the pin for a given client ID. If the client cannot be found on the map,
* this method does nothing
*/
- (void)zoomToClientWithID:(NSString *)clientId {
    id <GMSMarker> marker = [self markerForClientID:clientId];
    if (marker) {
        GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:marker.position.latitude longitude:marker.position.longitude zoom:6];
        [self.mapView setCamera:cameraPosition];
    }
}


#pragma mark -
#pragma mark Accessors/Mutators
//============================================================================================================


- (CLLocation *)currentLocation {
    ChatNavigationController *navController = (ChatNavigationController *) self.presentingViewController;
    return [navController currentLocation];
}

/**
* Adds a marker to the map for a given Client
*/
- (void)addClient:(Client *)client {
    GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
    options.position = client.location.coordinate;
    options.title = client.clientId;
    options.snippet = [client.location.timestamp chatTimestamp];
    [self.mapView addMarkerWithOptions:options];
    [self zoomToFitAnnotations];
}

/**
* Removes the marker for a given client
 */
- (void)removeClientWithID:(NSString *)string {
    id <GMSMarker> markerToRemove = [self markerForClientID:string];

    if (markerToRemove) {
        [markerToRemove remove];
        [self zoomToFitAnnotations];
    }
}

/**
* Convenience method to map a client to its marker on the map
*/
- (id <GMSMarker>)markerForClientID:(NSString *)clientId {
    id <GMSMarker> markerToRemove = nil;
    for (id <GMSMarker> marker in [self.mapView markers]) {
        if ([marker.title isEqualToString:clientId]) {
            markerToRemove = marker;
            break;
        }
    }
    return markerToRemove;
}


#pragma mark -
#pragma mark Events
//============================================================================================================

/**
* The user would like to return to the chat window
*/
- (void)chatButtonTapped:(id)chatButtonTapped {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}


/**
* A new client has connected to the server, so add their pin to the map
*/
- (void)clientDidConnect:(NSNotification *)notification {
    Client *client = [[notification userInfo] objectForKey:kClientKey];

    dispatch_async(dispatch_get_main_queue(), ^{
        // add the client
        [self addClient:client];
    });
}


/**
* A client has disconnected from the server, so remove their pin from the map
*/
- (void)clientDidDisconnect:(NSNotification *)notification {
    NSString *clientId = [[notification userInfo] objectForKey:kClientIDKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        // add the client
        [self removeClientWithID:clientId];
    });
}


/**
* A client has reported an updated location, so update their position on the map
*/
- (void)clientDidUpdateLocation:(id)notification {
    Client *client = [[notification userInfo] objectForKey:kClientKey];

    dispatch_async(dispatch_get_main_queue(), ^{
        id <GMSMarker> marker = [self markerForClientID:client.clientId];
        [marker setPosition:client.location.coordinate];
    });
}



#pragma mark -
#pragma mark Helpers
//============================================================================================================

- (ChatNavigationController *)navController {
    return (ChatNavigationController *) self.presentingViewController;
}

- (NSArray *)clients {
    return [[[self navController] connection] connectedClients];
}


@end