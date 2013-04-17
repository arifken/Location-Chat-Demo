/*!
 * \file    ChatInputView
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
 *
 */



#import <Foundation/Foundation.h>

@protocol ChatInputViewDelegate;

@interface ChatInputView : UIView <UITextViewDelegate>

@property(weak) id <ChatInputViewDelegate> delegate;
@property(strong) UITextView *messageField;
@property(strong) UIButton *sendButton;
@end

@protocol ChatInputViewDelegate
- (void) chatInputView:(ChatInputView *)view didSendMessage:(NSString*)message;
@end