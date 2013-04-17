/*!
 * \file    Client
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>

@class CLLocation;


@interface Client : NSObject
@property(copy) NSString *clientId;
@property(strong) CLLocation *location;

+ (Client *)clientWithJSONDictionary:(NSDictionary *)dictionary;
@end