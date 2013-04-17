/*!
 * \file    ChatConnection
 * \project 
 * \author  Andy Rifken 
 * \date    4/13/13.
 *
 */



#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@protocol ChatConnectionDelegate;
@class ChatMessage;
@class CLLocation;
@class Client;

typedef enum {
    ChatConnectionStateDisconnected = 0,
    ChatConnectionStateConnectedSigningIn,
    ChatConnectionStateSignedIn
} ChatConnectionState;

@interface ChatConnection : NSObject {
    NSMutableArray *_connectedClients;
}

@property(copy) NSString *clientId;
@property(strong) GCDAsyncSocket *socket;
@property(weak) id <ChatConnectionDelegate> delegate;
@property ChatConnectionState connectionState;

- (NSArray *)connectedClients;

- (id)initWithClientId:(NSString *)clientId;

- (void)connect;

- (void)disconnect;

- (void)send:(ChatMessage *)message;

- (void)sendLocation:(CLLocation *)location;

- (void)requestLocationForClientWithID:(NSString *)clientId;

- (Client *)myClient;

- (Client *)clientForID:(NSString *)string;
@end

@protocol ChatConnectionDelegate

- (void)chatConnnection:(ChatConnection *)conn didReceiveError:(NSError*)error;

- (void)chatConnection:(ChatConnection *)conn didReceiveMessage:(ChatMessage *)message;

- (void)chatConnection:(ChatConnection *)conn didReceiveLocation:(CLLocation *)loc forClientID:(NSString *)clientId;

- (void)chatConnection:(ChatConnection *)conn clientDidConnect:(Client*)client;

- (void)chatConnection:(ChatConnection *)conn clientDidDisconnect:(NSString*)clientId;

- (CLLocation *)chatConnectionCurrentLocation:(ChatConnection *)conn;
@end