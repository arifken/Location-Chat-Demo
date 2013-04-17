/*!
 * \file    ClientTableViewCell
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
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


