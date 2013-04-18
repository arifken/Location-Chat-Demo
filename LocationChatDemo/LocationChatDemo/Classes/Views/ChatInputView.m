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

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ChatInputView.h"


@implementation ChatInputView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        //---------------------------------------- View setup ------------------------------------------------------

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

        //---------------------------------------- Layout ------------------------------------------------------

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

/**
* Calculate the height needed to accomodate all the text in the text field, plus margin. The parent view will use
* this to determine the size of this input view
*/
- (CGSize)intrinsicContentSize {
    CGFloat width = self.frame.size.width;

    [self.messageField layoutIfNeeded];
    CGFloat fldHeight = self.messageField.contentSize.height;
    CGFloat btnHeight = [self.sendButton intrinsicContentSize].height;


    return CGSizeMake(width, (fldHeight > btnHeight) ? fldHeight : btnHeight);
}

#pragma mark -
#pragma mark Events
//============================================================================================================

- (void)didTapSend:(id)didTapSend {
    [self.delegate chatInputView:self didSendMessage:self.messageField.text];
    self.messageField.text = nil;
    [self invalidateIntrinsicContentSize];
    [self layoutIfNeeded];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self invalidateIntrinsicContentSize];
}




@end