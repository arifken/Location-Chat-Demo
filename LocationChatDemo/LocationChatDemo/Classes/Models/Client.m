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
#import "Client.h"
#import "CLLocation+String.h"
#import "Constants.h"


@implementation Client


+ (Client *)clientWithJSONDictionary:(NSDictionary *)dictionary {
    Client *client = [[Client alloc] init];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:kJSONDateKey] doubleValue]];
    CLLocation *location = [CLLocation locationWithCoordinateString:[dictionary objectForKey:kJSONLocationKey] date:date];
    NSString *clientId = [dictionary objectForKey:kJSONClientIDKey];

    client.clientId = clientId;
    client.location = location;

    return client;
}


- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToClient:other];
}

- (BOOL)isEqualToClient:(Client *)client {
    if (self == client)
        return YES;
    if (client == nil)
        return NO;
    if (self.clientId != client.clientId && ![self.clientId isEqualToString:client.clientId])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.clientId hash];
}


@end