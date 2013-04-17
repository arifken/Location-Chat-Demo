/*!
 * \file    SignInView
 * \project 
 * \author  Andy Rifken 
 * \date    4/15/13.
 *
 */



#import <Foundation/Foundation.h>

@protocol SignInViewDelegate;

@interface SignInView : UIView <UITextFieldDelegate>

@property(nonatomic, strong) UITextField *clientIdField;
@property(nonatomic, strong) UILabel *promptLabel;
@property(nonatomic, strong) UIButton *signInButton;
@property(weak) id <SignInViewDelegate> delegate;

@end

@protocol SignInViewDelegate
- (void)signInView:(SignInView *)signInView didLoginWithClientID:(NSString *)clientID;
@end