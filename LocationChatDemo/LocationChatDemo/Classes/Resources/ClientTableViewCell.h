/*!
 * \file    ClientTableViewCell
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>

@protocol ClientTableViewCellDelegate;


@interface ClientTableViewCell : UITableViewCell

@property(strong) UIButton *mapButton;
@property(strong) UIButton *locationButton;

@property(weak) id <ClientTableViewCellDelegate> delegate;
@end


@protocol ClientTableViewCellDelegate
-(void)cellDidTapMapButton:(ClientTableViewCell *)cell;
-(void)cellDidTapLocationButton:(ClientTableViewCell *)cell;
@end