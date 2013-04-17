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