/*!
 * \file    MapViewController
 * \project 
 * \author  Andy Rifken 
 * \date    4/14/13.
 *
 */



#import <Foundation/Foundation.h>

@class GMSMapView;


@interface MapViewController : UIViewController
@property(nonatomic, strong) UIToolbar *toolbar;
@property(nonatomic, strong) GMSMapView *mapView;

- (void)zoomToClientWithID:(NSString *)string;
@end