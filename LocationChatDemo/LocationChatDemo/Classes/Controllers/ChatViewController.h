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
#import "ChatInputView.h"
#import "ServerConnection.h"

@class ChatInputView;
@class ServerConnection;

/**
* View controller that shows a table view of chat messages, with an input box to submit a message
*
*/
@interface ChatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ChatInputViewDelegate>

@property(strong) UITableView *tableView;
@property(strong) ChatInputView *chatInputView;
@property(strong) NSMutableArray *messages; // Message objects

// we need to keep the following NSLayoutConstraint objects as ivars so we can add/remove them according to the
// state of the keyboard in the view
@property(nonatomic, strong) NSArray *vertLayoutsNoKeyboard;
@property(nonatomic, strong) NSArray *vertLayoutsKeyboard;

/**
* Adds a Message to the chat
*/
- (void)addMessage:(Message *)message;

@end