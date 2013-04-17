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

#import "ClientTableViewCell.h"


@implementation ClientTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.mapButton setBackgroundImage:[UIImage imageNamed:@"07-map-marker"] forState:UIControlStateNormal];
        [self.mapButton addTarget:self action:@selector(mapButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.mapButton];

        self.locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.locationButton setBackgroundImage:[UIImage imageNamed:@"74-location"] forState:UIControlStateNormal];
        [self.locationButton addTarget:self action:@selector(locationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.locationButton];

        UIView *mapButton = self.mapButton;
        UIView *locButton = self.locationButton;
        UIView *textLabel = self.textLabel;
        UIView *detailTextLabel = self.detailTextLabel;

        mapButton.translatesAutoresizingMaskIntoConstraints = NO;
        locButton.translatesAutoresizingMaskIntoConstraints = NO;
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;


        NSDictionary *metrics = @{
                @"margin" : [NSNumber numberWithFloat:4.0],
                @"margin2" : [NSNumber numberWithFloat:12.0]
        };

        NSMutableArray *layoutConstraints = [[NSMutableArray alloc] init];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[mapButton]-(margin2)-[locButton]-(margin)-|"
                                                                                       options:NSLayoutFormatAlignAllCenterY
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(mapButton, locButton)]];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(margin)-[textLabel(>=0)]-(>=margin)-[mapButton]"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(textLabel,mapButton)]];
        [layoutConstraints addObject:[NSLayoutConstraint constraintWithItem:detailTextLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:textLabel attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];

        [layoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel(>=0)][detailTextLabel]|"
                                                                                       options:NSLayoutFormatAlignAllLeft
                                                                                       metrics:metrics
                                                                                         views:NSDictionaryOfVariableBindings(textLabel, detailTextLabel)]];


        [layoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.mapButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];


        [self.contentView addConstraints:layoutConstraints];


    }

    return self;
}

- (void)locationButtonTapped:(id)locationButtonTapped {
    [self.delegate cellDidTapLocationButton:self];
}

- (void)mapButtonTapped:(id)mapButtonTapped {
    [self.delegate cellDidTapMapButton:self];
}


@end


