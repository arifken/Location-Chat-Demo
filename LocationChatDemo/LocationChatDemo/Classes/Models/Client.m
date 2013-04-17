/*!
 * \file    Client
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <CoreLocation/CoreLocation.h>
#import "Client.h"
#import "CLLocation+String.h"


@implementation Client


+ (Client *)clientWithJSONDictionary:(NSDictionary *)dictionary {
    Client *client = [[Client alloc] init];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"date"] doubleValue]];
    CLLocation *location = [CLLocation locationWithCoordinateString:[dictionary objectForKey:@"location"] date:date];
    NSString *clientId = [dictionary objectForKey:@"cid"];

    client.clientId = clientId;
    client.location = location;

    return client;

}
@end