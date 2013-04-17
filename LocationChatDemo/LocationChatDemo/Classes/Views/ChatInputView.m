/*!
 * \file    ChatInputView
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
 *
 */



#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ChatInputView.h"


@implementation ChatInputView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.messageField = [[UITextView alloc] init];
        self.messageField.layer.borderColor = [[UIColor blackColor] CGColor];
        self.messageField.layer.borderWidth = 1.0f;
        self.messageField.font = [UIFont systemFontOfSize:15];
        self.messageField.editable = YES;
        self.messageField.delegate = self;
        self.messageField.showsVerticalScrollIndicator = NO;
        self.messageField.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.messageField];

        self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [self.sendButton addTarget:self action:@selector(didTapSend:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.sendButton];


        UIView *fld = self.messageField;
        UIView *btn = self.sendButton;

        fld.translatesAutoresizingMaskIntoConstraints = NO;
        btn.translatesAutoresizingMaskIntoConstraints = NO;

        NSDictionary *metrics = @{
                @"margin" : [NSNumber numberWithFloat:4.0]
        };

        NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[fld][btn(50)]|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(fld, btn)]];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[fld]|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(fld)]];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn(==fld)]-(>=0)-|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(fld,btn)]];

        [self addConstraints:layoutConstraints];


    }

    return self;
}

- (void)didTapSend:(id)didTapSend {
    [self.delegate chatInputView:self didSendMessage:self.messageField.text];
    self.messageField.text = nil;
}

- (CGSize)intrinsicContentSize {
    CGFloat width = self.frame.size.width;

    [self.messageField layoutIfNeeded];
    CGFloat fldHeight = self.messageField.contentSize.height;
    CGFloat btnHeight = [self.sendButton intrinsicContentSize].height;


    return CGSizeMake(width, (fldHeight > btnHeight) ? fldHeight : btnHeight);
}

- (void)textViewDidChange:(UITextView *)textView {
    [self invalidateIntrinsicContentSize];
}




@end