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


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Message : NSObject {
    NSString *_locationString;
}

@property(strong) NSString *action; // this tells the server what to do with this transmission
@property(copy) NSString *clientId; // Identifier representing a client (the sender of the message)
@property(copy) NSString *targetClientId; // Optional identifier representing a client that we are trying to communicate with
@property(copy) NSString *text; // The body of the message
@property(strong) NSDate *date; // GMT timestamp for when the message was generated
@property(strong) CLLocation *location; // (optional) current location of the client at the time the message was posted
@property(copy) NSString *reverseGeoString; // the "human readable" location, after being reverse geocoded from coords

@property(strong) NSArray *clients; // Array of Client objects used when referring to a set of users

/**
* Convenience initializer fo generating Message ojects from server responses
*/
+ (Message *)messageWithJSONObject:(NSDictionary *)dict;

/**
* Serializes the Message object into a JSON representation (UTF8)
*/
- (NSData *)jsonData;

/**
* Convenience method to return the date in a human readable format
*/
- (NSString *)dateString;


@end