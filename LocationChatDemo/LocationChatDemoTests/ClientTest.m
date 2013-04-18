/*!
 * \file    ClientTest
 * \project 
 * \author  Andy Rifken 
 * \date    4/17/13.
 *
 */



#import <CoreLocation/CoreLocation.h>
#import "ClientTest.h"
#import "Client.h"
#import "Constants.h"
#import "CLLocation+String.h"


@implementation ClientTest


- (void)testJSONSerialization {
    NSString *exp_cid = @"tester";
    CLLocation *exp_loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10, 10) altitude:CLLocationDistanceMax horizontalAccuracy:kCLLocationAccuracyBest verticalAccuracy:kCLLocationAccuracyBest timestamp:[NSDate date]];

    Client *client = [[Client alloc] init];
    client.clientId = exp_cid;
    client.location = exp_loc;

    NSData *jsonData = [client jsonData];

    NSError *error1 = nil;
    NSDictionary *deserialized = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error1];
    STAssertNil(error1, @"error was expected to be nil, but was %@", error1);
    STAssertNotNil(deserialized, @"deserialized should not be nil");

    STAssertTrue([exp_cid isEqualToString:[deserialized objectForKey:kJSONClientIDKey]], @"\nexpected %@, \nactual   %@", exp_cid, [deserialized objectForKey:kJSONClientIDKey]);
    STAssertTrue([[exp_loc coordinatesAsString] isEqualToString:[deserialized objectForKey:kJSONLocationKey]], @"\nexpected %@, \nactual   %@", [exp_loc coordinatesAsString], [deserialized objectForKey:kJSONLocationKey]);


    // test to ensure nil fields do not throw serialization exception
    client.clientId = nil;
    jsonData = [client jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");

    client.clientId = exp_cid;
    client.location = nil;
    jsonData = [client jsonData];
    STAssertNotNil(jsonData, @"jsonData should not be nil");
}

- (void) testJSONDeserialization {
    NSString *jsonString = @"{\"cid\":\"tester\",\"location\":\"12.43,33.45\",\"date\":\"1366285884\"}";
    NSError *error = nil;
    NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    STAssertNil(error, @"error was expected to be nil, but was %@", error);
    STAssertNotNil(jsonObj, @"jsonObj should not be nil");

    Client *client = [Client clientWithJSONDictionary:jsonObj];
    STAssertNotNil(client, @"client should not be nil");
    STAssertTrue([@"tester" isEqualToString:client.clientId], @"\nexpected %@, \nactual   %@", @"tester", client.clientId);
    STAssertTrue([@"12.430000,33.450000" isEqualToString:[client.location coordinatesAsString]], @"\nexpected %@, \nactual   %@", @"12.430000,33.450000", [client.location coordinatesAsString]);
}


@end