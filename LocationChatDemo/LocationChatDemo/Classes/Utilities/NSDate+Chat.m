/*!
 * \file    NSDate(Chat)
 * \project 
 * \author  Andy Rifken 
 * \date    4/15/13.
 *
 */



#import "NSDate+Chat.h"


@implementation NSDate (Chat)

- (NSString *)chatTimestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a"];
    return [dateFormatter stringFromDate:self];
}


@end