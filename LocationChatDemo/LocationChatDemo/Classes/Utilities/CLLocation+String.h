/*!
 * \file    CLLocation(String)
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CLLocation (String)
+ (CLLocation *)locationWithCoordinateString:(NSString *)str date:(NSDate *)date;
- (NSString *)coordinatesAsString;

@end