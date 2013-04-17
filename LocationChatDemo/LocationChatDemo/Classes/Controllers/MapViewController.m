/*!
 * \file    MapViewController
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
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

- (void)viewDidLoad {
    [super viewDidLoad];

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


    self.view.backgroundColor = [UIColor lightGrayColor];


    self.toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *chatButton = [[UIBarButtonItem alloc] initWithTitle:@"Chat" style:UIBarButtonItemStyleBordered target:self action:@selector(chatButtonTapped:)];
    [self.view addSubview:self.toolbar];


    self.toolbar.items = @[space, chatButton];

    //CLLocation *location = [self currentLocation];

    self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:nil];
    self.mapView.myLocationEnabled = YES;
    [self.view addSubview:self.mapView];

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


- (void)chatButtonTapped:(id)chatButtonTapped {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

- (CLLocation *)currentLocation {
    ChatNavigationController *navController = (ChatNavigationController *) self.presentingViewController;
    return [navController currentLocation];
}


- (void)addClient:(Client *)client {
    GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
    options.position = client.location.coordinate;
    options.title = client.clientId;
    options.snippet = [client.location.timestamp chatTimestamp];
    [self.mapView addMarkerWithOptions:options];
    [self zoomToFitAnnotations];
}

- (void)removeClientWithID:(NSString *)string {
    id <GMSMarker> markerToRemove = [self markerForClientID:string];

    if (markerToRemove) {
        [markerToRemove remove];
        [self zoomToFitAnnotations];
    }
}

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

- (void)zoomToClientWithID:(NSString *)clientId {
    id <GMSMarker> marker = [self markerForClientID:clientId];
    if (marker) {
        GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:marker.position.latitude longitude:marker.position.longitude zoom:6];
        [self.mapView setCamera:cameraPosition];
    }
}

#pragma mark -
#pragma mark Events
//============================================================================================================


- (void)clientDidConnect:(NSNotification *)notification {
    Client *client = [[notification userInfo] objectForKey:kClientKey];

    dispatch_async(dispatch_get_main_queue(), ^{
        // add the client
        [self addClient:client];
    });
}


- (void)clientDidDisconnect:(NSNotification *)notification {
    NSString *clientId = [[notification userInfo] objectForKey:kClientIDKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        // add the client
        [self removeClientWithID:clientId];
    });
}


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