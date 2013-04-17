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
#import "ChatMessage.h"
#import "NSDate+Chat.h"


@implementation ChatMessage
+ (ChatMessage *)messageWithJSONObject:(NSDictionary *)dict {
    ChatMessage *ret = [[ChatMessage alloc] init];

    ret.clientId = [dict objectForKey:@"cid"];
    ret.text = [dict objectForKey:@"msg"];

    NSString *dateStr = [dict objectForKey:@"date"];
    if (dateStr) {
        ret.date = [NSDate dateWithTimeIntervalSince1970:[dateStr doubleValue]];
    }

    NSString *locString = [dict objectForKey:@"location"];
    NSArray *locComps = [locString componentsSeparatedByString:@","];
    if (locComps && [locComps count] == 2) {
        ret.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([[locComps objectAtIndex:0] doubleValue], [[locComps objectAtIndex:1] doubleValue])
                                                     altitude:CLLocationDistanceMax
                                           horizontalAccuracy:kCLLocationAccuracyBest
                                             verticalAccuracy:kCLLocationAccuracyBest
                                                    timestamp:ret.date];
    }
    return ret;
}

- (NSString *)locationString {
    if (!_locationString) {
        return @"Location N/A";
    }
    return _locationString;
}

- (void)setLocationString:(NSString *)locationString {
    if (_locationString != locationString) {
        locationString = [locationString mutableCopy];
        _locationString = locationString;
    }
}


- (NSData *)jsonData {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"msg" forKey:@"action"];
    if (self.text) {
        [dict setObject:self.text forKey:@"msg"];
    }
    if (self.clientId) {
        [dict setObject:self.clientId forKey:@"cid"];
    }
    if (self.location) {
        [dict setObject:[NSString stringWithFormat:@"%f,%f", self.location.coordinate.latitude, self.location.coordinate.longitude] forKey:@"location"];
    }

    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];

}

- (NSString *)dateString {
    if (!self.date) {
        return @"Date N/A";
    }
    return [self.date chatTimestamp];
}
@end