/*!
 * \file    ClientsViewController
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>
#import "ClientTableViewCell.h"


@interface ClientsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ClientTableViewCellDelegate>
@property(strong, readonly) NSArray *clients;
@property(strong) UITableView *tableView;
@property(strong) UIToolbar *toolbar;
@end