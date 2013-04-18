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
#import "Message.h"
#import "NSDate+Chat.h"
#import "Constants.h"
#import "Client.h"


@implementation Message

- (id)init {
    self = [super init];
    if (self) {
        self.action = @"msg"; // default to "chat message" type
    }

    return self;
}


+ (Message *)messageWithJSONObject:(NSDictionary *)dict {
    Message *ret = [[Message alloc] init];

    ret.action = [dict objectForKey:kJSONActionKey];

    ret.clientId = [dict objectForKey:kJSONClientIDKey];
    ret.text = [dict objectForKey:kJSONMessageKey];

    NSString *dateStr = [dict objectForKey:kJSONDateKey];
    if (dateStr) {
        ret.date = [NSDate dateWithTimeIntervalSince1970:[dateStr doubleValue]];
    }

    NSString *locString = [dict objectForKey:kJSONLocationKey];
    NSArray *locComps = [locString componentsSeparatedByString:@","];
    if (locComps && [locComps count] == 2) {
        ret.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([[locComps objectAtIndex:0] doubleValue], [[locComps objectAtIndex:1] doubleValue])
                                                     altitude:CLLocationDistanceMax
                                           horizontalAccuracy:kCLLocationAccuracyBest
                                             verticalAccuracy:kCLLocationAccuracyBest
                                                    timestamp:ret.date];
    }


    // parse out current clients
    NSDictionary *clientJSONObjs = [dict objectForKey:@"clients"];
    NSMutableArray *addedClients = [[NSMutableArray alloc] init];
    for (NSDictionary *aClientId in [clientJSONObjs allKeys]) {
        NSDictionary *clientDict = [clientJSONObjs objectForKey:aClientId];
        Client *newClient = [Client clientWithJSONDictionary:clientDict];
        [addedClients addObject:newClient];
    }
    ret.clients = [NSArray arrayWithArray:addedClients];

    return ret;
}


- (NSString *)reverseGeoString {
    if (!_locationString) {
        return @"Location N/A";
    }
    return _locationString;
}

- (void)setReverseGeoString:(NSString *)reverseGeoString {
    if (_locationString != reverseGeoString) {
        reverseGeoString = [reverseGeoString mutableCopy];
        _locationString = reverseGeoString;
    }
}

- (NSData *)jsonData {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.action) {
        [dict setObject:self.action forKey:kJSONActionKey];
    }
    if (self.text) {
        [dict setObject:self.text forKey:kJSONMessageKey];
    }
    if (self.clientId) {
        [dict setObject:self.clientId forKey:kJSONClientIDKey];
    }
    if (self.targetClientId) {
        [dict setObject:self.targetClientId forKey:kJSONTargetKey];
    }
    if (self.location) {
        [dict setObject:[NSString stringWithFormat:@"%f,%f", self.location.coordinate.latitude, self.location.coordinate.longitude] forKey:kJSONLocationKey];
    }
    if (self.date) {
        NSTimeInterval value = [self.date timeIntervalSince1970];
        [dict setObject:[NSNumber numberWithDouble:value] forKey:kJSONDateKey];
    }
    NSError *error1 = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error1];
    if (error1) {
        NSLog(@"***JSON Error: %@", error1);
    }
    return data;

}

- (NSString *)dateString {
    if (!self.date) {
        return @"Date N/A";
    }
    return [self.date chatTimestamp];
}

@end