/*!
 * \file    ChatMessage
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
 *
 */



#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ChatMessage : NSObject {
    NSString *_locationString;
}

@property(copy) NSString *clientId;
@property(copy) NSString *text;
@property(strong) NSDate *date;
@property(strong) CLLocation *location;
@property(copy) NSString *locationString;

+ (ChatMessage *)messageWithJSONObject:(NSDictionary *)dict;

- (NSData *)jsonData;

- (NSString *)dateString;
@end