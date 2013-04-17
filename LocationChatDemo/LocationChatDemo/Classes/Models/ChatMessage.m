/*!
 * \file    ChatMessage
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
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