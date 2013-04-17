/*!
 * \file    CLLocation(String)
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import "CLLocation+String.h"


@implementation CLLocation (String)

+ (CLLocation *)locationWithCoordinateString:(NSString *)str date:(NSDate *)date {
    NSArray *comps = [str componentsSeparatedByString:@","];

    double latitude = [[[comps objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] doubleValue];
    double longitude = [[[comps objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] doubleValue];


    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                                    altitude:CLLocationDistanceMax horizontalAccuracy:kCLLocationAccuracyBest verticalAccuracy:kCLLocationAccuracyBest timestamp:date];
    return loc;
}

- (NSString *)coordinatesAsString {
    return [NSString stringWithFormat:@"%f,%f", self.coordinate.latitude, self.coordinate.longitude];
}

@end