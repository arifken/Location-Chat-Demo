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
#import "ClientsViewController.h"
#import "ClientTableViewCell.h"
#import "Client.h"
#import "ChatNavigationController.h"
#import "Constants.h"
#import "NSDate+Chat.h"


@implementation ClientsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //---------------------------------------- Set up Observers ------------------------------------------------------

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

    //---------------------------------------- Set up Views ------------------------------------------------------

    self.toolbar = [[UIToolbar alloc] init];
    [self.view addSubview:self.toolbar];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

    self.toolbar.items = @[item, space];


    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self.view addSubview:self.tableView];


    //---------------------------------------- Auto Layout ------------------------------------------------------


    UIView *toolbar = self.toolbar;
    UIView *tableView = self.tableView;

    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;


    NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[toolbar][tableView(>=0)]|"
                                                                                   options:(NSLayoutFormatOptions) 0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(toolbar, tableView)]];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[toolbar]|"
                                                                                   options:(NSLayoutFormatOptions) 0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(toolbar)]];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                                   options:(NSLayoutFormatOptions) 0
                                                                                   metrics:nil views:NSDictionaryOfVariableBindings(tableView)]];

    [self.view addConstraints:layoutConstraints];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    for (Client *client in self.clients) {
        [self reverseGeocodeClient:client];
    }
}

- (void)dismiss:(id)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}


#pragma mark -
#pragma mark Helpers
//============================================================================================================

- (void)reverseGeocodeClient:(Client *)client {

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak ClientsViewController *bself = self;
    [geocoder reverseGeocodeLocation:client.location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks && [placemarks count] > 0 && !error) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            client.reverseGeoString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];

            if ([bself.clients containsObject:client]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[bself.clients indexOfObject:client] inSection:0];
                [bself.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }];
}


- (ChatNavigationController *)navController {
    return (ChatNavigationController *) self.presentingViewController;
}

- (NSArray *)clients {
    return [[[self navController] connection] connectedClients];
}

#pragma mark -
#pragma mark Table view
//============================================================================================================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self clients] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"Cell";

    ClientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[ClientTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }

    Client *client = [self.clients objectAtIndex:(NSUInteger) indexPath.row];

    cell.textLabel.text = client.clientId;
    CLLocation *location = client.location;
    if ([client.clientId caseInsensitiveCompare:[[[self navController] connection] clientId]] == NSOrderedSame) {
        location = [[self navController] currentLocation];
    }

    NSDate *date = client.location.timestamp;
    NSString *dateString;

    if (date) {
        dateString = [date chatTimestamp];
    } else {
        dateString = @"N/A";
    }

    NSString *locationString;
    if (client.reverseGeoString) {
        locationString = client.reverseGeoString;
    } else {
        locationString = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
    }

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ at %@", dateString, locationString];

    return cell;
}

#pragma mark -
#pragma mark Events
//============================================================================================================

- (void)clientDidDisconnect:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)clientDidConnect:(NSNotification*)notification {
    Client *client = [[notification userInfo] objectForKey:kClientKey];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self reverseGeocodeClient:client];
    });
}

- (void)clientDidUpdateLocation:(NSNotification*)notification {
    Client *client = [[notification userInfo] objectForKey:kClientKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self reverseGeocodeClient:client];
    });
}

#pragma mark -
#pragma mark Cell buttons
//============================================================================================================

- (void)cellDidTapMapButton:(ClientTableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Client *client = [self.clients objectAtIndex:(NSUInteger) indexPath.row];
    [[self navController] showClientOnMap:client.clientId];

}

- (void)cellDidTapLocationButton:(ClientTableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Client *client = [self.clients objectAtIndex:(NSUInteger) indexPath.row];
    [[[self navController] connection] requestLocationForClientWithID:client.clientId];
}


@end