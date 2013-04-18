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
    message.date = [NSDate dateWithTimeIntervalSince1970:100];
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

    NSDate *deserializedDate = [NSDate dateWithTimeIntervalSince1970:[[deserializedObj objectForKey:kJSONDateKey] doubleValue]];
    STAssertTrue([message.date compare:deserializedDate] == NSOrderedSame, @"expected %@, found %@",message.date, deserializedDate);
//    NSComparisonResult difference = [message.date compare:deserializedDate];
//    NSLog(@"difference = %ld", difference);

    STAssertTrue([[message.location coordinatesAsString] isEqualToString:[deserializedObj objectForKey:kJSONLocationKey]], @"\nexpected %@, \nactual   %@", message.location, [deserializedObj objectForKey:kJSONLocationKey]);

    // test to ensure nil fields do not throw serialization exception
    message.action = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");
    message.action = @"msg";

    message.clientId = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    message.targetClientId = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    message.text = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    message.date = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    message.location = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    message.clients = nil;
    jsonData = [message jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");
}

- (void) testJSONDeserialization {
    NSString *jsonString = @"{\"action\":\"msg\",\"msg\":\"This is a message\",\"location\":\"12.43,33.45\"}";
    NSError *error = nil;
    NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    STAssertNil(error, @"error was expected to be nil, but was %@", error);
    STAssertNotNil(jsonObj, @"jsonObj should not be nil");

    Message *message = [Message messageWithJSONObject:jsonObj];
    STAssertTrue([@"msg" isEqualToString:message.action], @"\nexpected %@, \nactual   %@", @"msg", message.action);
    STAssertTrue([@"This is a message" isEqualToString:message.text], @"\nexpected %@, \nactual   %@", @"This is a message", message.text);
    STAssertTrue([@"12.430000,33.450000" isEqualToString:[message.location coordinatesAsString]], @"\nexpected %@, \nactual   %@", @"12.43,33.45", [message.location coordinatesAsString]);
}

@end