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
#import <CoreGraphics/CoreGraphics.h>
#import "ChatViewController.h"
#import "Message.h"
#import "MapViewController.h"
#import "ChatNavigationController.h"
#import "ClientsViewController.h"
#import "Constants.h"
#import "Client.h"


@implementation ChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.messages = [[NSMutableArray alloc] init];
    }

    return self;
}


#pragma mark -
#pragma mark Lifecycle
//============================================================================================================


- (void)viewDidLoad {
    [super viewDidLoad];

    // observers

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidUpdateLocation:)
                                                 name:(NSString *) kClientDidDUpdateLocationNotification
                                               object:nil];



    // view setup

    self.view.backgroundColor = [UIColor whiteColor];


    self.navigationItem.title = @"Chat";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStyleBordered target:self action:@selector(viewMapTapped:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clients" style:UIBarButtonItemStyleBordered target:self action:@selector(viewClientsTapped:)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    self.chatInputView = [[ChatInputView alloc] init];
    self.chatInputView.delegate = self;
    [self.view addSubview:self.chatInputView];


    // Layout

    NSDictionary *metrics = @{
            @"margin" : [NSNumber numberWithFloat:4.0]
    };

    UIView *tv = self.tableView;
    UIView *civ = self.chatInputView;

    tv.translatesAutoresizingMaskIntoConstraints = NO;
    civ.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tv]|"
                                                                                   options:(NSLayoutFormatOptions) 0
                                                                                   metrics:metrics
                                                                                     views:NSDictionaryOfVariableBindings(tv)]];

    [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[civ]|"
                                                                                   options:(NSLayoutFormatOptions) 0
                                                                                   metrics:metrics
                                                                                     views:NSDictionaryOfVariableBindings(civ)]];

    self.vertLayoutsNoKeyboard = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tv(>=100)]-[civ]|"
                                                                         options:(NSLayoutFormatOptions) 0
                                                                         metrics:metrics
                                                                           views:NSDictionaryOfVariableBindings(tv, civ)];

    [layoutConstraints addObjectsFromArray:self.vertLayoutsNoKeyboard];

    [self.view addConstraints:layoutConstraints];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Table View
//============================================================================================================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [self messageFont];
    }
    Message *message = [self.messages objectAtIndex:(NSUInteger) indexPath.row];

    cell.textLabel.text = [self cellTextForMessage:message];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ near %@", [message dateString], [message reverseGeoString]];
    return cell;
}

- (UIFont *)messageFont {
    return [UIFont systemFontOfSize:15];
}

- (NSString *)cellTextForMessage:(Message *)message {
    BOOL isMe = ([message.clientId isEqualToString:[self myClientID]]);

    if (isMe) {
        return message.text;
    }
    return [NSString stringWithFormat:@"(%@) %@", message.clientId, message.text];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat margin = 8.0;
    CGFloat height = margin * 2;


    NSString *messageText = [self cellTextForMessage:[self.messages objectAtIndex:indexPath.row]];
    CGFloat msgHeight = [messageText sizeWithFont:[self messageFont]
                                constrainedToSize:CGSizeMake(tableView.frame.size.width - margin * 2, 1000)
                                    lineBreakMode:NSLineBreakByWordWrapping].height;

    CGFloat detailHeight = [@"Location String" sizeWithFont:[UIFont systemFontOfSize:15]].height;

    height += (msgHeight + 4.0 + detailHeight);

    return height;
}


#pragma mark -
#pragma mark Geocoding
//============================================================================================================

- (void)reverseGeocodeMessage:(Message *)message {

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak ChatViewController *bself = self;
    [geocoder reverseGeocodeLocation:message.location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks && [placemarks count] > 0 && !error) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            message.reverseGeoString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];

            if ([bself.messages containsObject:message]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[bself.messages indexOfObject:message] inSection:0];
                [bself.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }];
}



#pragma mark -
#pragma mark Events
//============================================================================================================

- (void)chatInputView:(ChatInputView *)view didSendMessage:(NSString *)text {
    Message *message = [[Message alloc] init];
    message.text = text;
    message.clientId = [self myClientID];
    message.location = [(ChatNavigationController *) self.navigationController currentLocation];
    message.date = [NSDate date];

    NSLog(@"sending message: %@", message);
    [[(ChatNavigationController *) [self navigationController] connection] send:message];

    [self.view layoutIfNeeded];
}


- (void)viewClientsTapped:(id)viewClientsTapped {
    ClientsViewController *viewController = [[ClientsViewController alloc] init];
    [self presentViewController:viewController animated:YES completion:^{

    }];
}

- (void)viewMapTapped:(id)viewMapTapped {
    MapViewController *mapViewController = [[MapViewController alloc] init];
    mapViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:mapViewController animated:YES completion:^{

    }];
}

- (void)clientDidUpdateLocation:(NSNotification *)clientDidUpdateLocation {
    Client *client = [[clientDidUpdateLocation userInfo] objectForKey:kClientKey];
    NSLog(@"Client %@ updated location to %@", client.clientId, client.location);
}

#pragma mark -
#pragma mark keyboard
//============================================================================================================


- (void)keyboardWillShow:(NSNotification *)notification {
    UIView *tv = self.tableView;
    UIView *civ = self.chatInputView;
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    self.vertLayoutsKeyboard = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tv(>=100)]-[civ]-(keyboardHeight)-|"
                                                                       options:(NSLayoutFormatOptions) 0
                                                                       metrics:@{@"keyboardHeight" : [NSNumber numberWithFloat:keyboardHeight]}
                                                                         views:NSDictionaryOfVariableBindings(tv, civ)];
    [self.view removeConstraints:self.vertLayoutsNoKeyboard];
    [self.view addConstraints:self.vertLayoutsKeyboard];
    [UIView animateWithDuration:duration animations:^{
        [self.view invalidateIntrinsicContentSize];
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.view removeConstraints:self.vertLayoutsKeyboard];
    [self.view addConstraints:self.vertLayoutsNoKeyboard];
    [UIView animateWithDuration:duration animations:^{
        [self.view invalidateIntrinsicContentSize];
        [self.view layoutIfNeeded];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isDragging) {
        [self.chatInputView.messageField resignFirstResponder];
    }
}

#pragma mark -
#pragma mark Accessors/Mutators
//============================================================================================================


- (NSString *)myClientID {
    return [[(ChatNavigationController *) [self navigationController] connection] clientId];
}

- (void)addMessage:(Message *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messages addObject:message];
        [self reverseGeocodeMessage:message];
        [self.tableView reloadData];
    });
}


@end