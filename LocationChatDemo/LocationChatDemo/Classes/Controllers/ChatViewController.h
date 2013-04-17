/*!
 * \file    ChatViewController
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
 *
 */



#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ChatInputView.h"
#import "ChatConnection.h"

@class ChatInputView;
@class ChatConnection;

@interface ChatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ChatInputViewDelegate>

@property(strong) UITableView *tableView;
@property(strong) ChatInputView *chatInputView;
@property(strong) NSMutableArray *messages; // ChatMessage objects

@property(nonatomic, strong) NSArray *vertLayoutsNoKeyboard;
@property(nonatomic, strong) NSArray *vertLayoutsKeyboard;

- (void)addMessage:(ChatMessage *)message;
@end