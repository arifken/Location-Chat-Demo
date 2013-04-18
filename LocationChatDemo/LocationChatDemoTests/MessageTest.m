/*!
 * \file    MessageTest
 * \project 
 * \author  Andy Rifken 
 * \date    4/17/13.
 *
 */



#import "MessageTest.h"
#import "Message.h"
#import "Constants.h"
#import "CLLocation+String.h"
#import "Client.h"
#import "NSDate+Chat.h"


@implementation MessageTest


- (void)testJSONSerialization {
    Message *message = [[Message alloc] init];

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:CLLocationDistanceMax horizontalAccuracy:kCLLocationAccuracyBest verticalAccuracy:kCLLocationAccuracyBest timestamp:[NSDate date]];

    Client *client = [[Client alloc] init];
    client.clientId = @"SomeoneElse";
    client.location = location;

    message.action = @"msg";
    message.clientId = @"SomeClient";
    message.targetClientId = @"TargetClient";
    message.text = @"this is a chat message";
    message.date = [NSDate date];
    message.location = location;

    message.clients = @[client];

    // test serialize

    NSData *jsonData = [message jsonData];

    NSError *error = nil;
    NSDictionary *deserializedObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    STAssertNil(error, @"error was expected to be nil, but was %@", error);
    STAssertNotNil(deserializedObj, @"deserializedObj should not be nil");

    STAssertTrue([message.action isEqualToString:[deserializedObj objectForKey:kJSONActionKey]], @"\nexpected %@, \nactual   %@", message.action, kJSONActionKey);
    STAssertTrue([message.clientId isEqualToString:[deserializedObj objectForKey:kJSONClientIDKey]], @"\nexpected %@, \nactual   %@", message.clientId, [deserializedObj objectForKey:kJSONClientIDKey]);
    STAssertTrue([message.targetClientId isEqualToString:[deserializedObj objectForKey:kJSONTargetKey]], @"\nexpected %@, \nactual   %@", message.targetClientId, [deserializedObj objectForKey:kJSONTargetKey]);
    STAssertTrue([message.text isEqualToString:[deserializedObj objectForKey:kJSONMessageKey]], @"\nexpected %@, \nactual   %@", message.text, [deserializedObj objectForKey:kJSONMessageKey]);

    STAssertTrue([message.date timeIntervalSince1970] == [[deserializedObj objectForKey:kJSONDateKey] doubleValue], @"expected %d, found %d", [message.date timeIntervalSince1970], [[deserializedObj objectForKey:kJSONDateKey] doubleValue]);

    STAssertTrue([[message.location coordinatesAsString] isEqualToString:[deserializedObj objectForKey:kJSONLocationKey]], @"\nexpected %@, \nactual   %@", message.location, [deserializedObj objectForKey:kJSONLocationKey]);

}


@end