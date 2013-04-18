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
#import "ServerConnection.h"
#import "GCDAsyncSocket.h"
#import "CLLocation+String.h"
#import "Client.h"
#import "Message.h"
#import "Constants.h"

NSString const *ACTION_CONNECTED = @"con"; // someone connected to the server (could also be self)
NSString const *ACTION_DISCONNECTED = @"dis"; // someone disconnected
NSString const *ACTION_MESSAGE = @"msg"; // a chat message was submitted
NSString const *ACTION_LOCATION_REQUEST = @"loc_req"; // someone is requesting our current location
NSString const *ACTION_LOCATION_RESPONSE = @"loc_res"; // someone is broadcasting their location
NSString const *ACTION_HEARTBEAT = @"hb"; // the server is checking to make sure we are still connected

static const float kDefaultTimeout = -1.0; // set no timeout period for the socket (the server will manage timeouts)

@implementation ServerConnection

#pragma mark -
#pragma mark Ctor
//============================================================================================================


- (id)init {
    self = [super init];
    if (self) {
        self.socket = [[GCDAsyncSocket alloc] init];
        self.socket.delegate = self;
        self.socket.delegateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        _connectedClients = [[NSMutableArray alloc] init];
    }

    return self;
}


#pragma mark -
#pragma mark Actions
//============================================================================================================

/**
* Open the socket connection to the server. We get an event when we are connected successfully, and we use that event
* to register with the server (using our client ID)
*/
- (void)connect {
    NSError *error = nil;
    [self.socket connectToHost:(NSString *) kServerHost onPort:3000 error:&error];
    if (error) {
        NSLog(@"***Error connecting to host! %@", error);
    }
}


/**
* send the FIN signal to disconnect from the server. We get an event upon disconnect, where we clear out the current
* connection state
*/
- (void)disconnect {
    [self.socket disconnect];
}


/**
* Send a message to the server.
*
* This method serializes the Message object and writes it to the socket
*
*/
- (void)send:(Message *)message {
    if (self.socket.isConnected) {
        [self.socket writeData:[message jsonData] withTimeout:kDefaultTimeout tag:0];
    }
}


- (void)sendLocation:(CLLocation *)location {
    if (self.socket.isConnected && location) {
//        NSDictionary *data = @{
//                @"action" : ACTION_LOCATION_RESPONSE,
//                @"location" : [location coordinatesAsString]
//        };
        Message *message = [[Message alloc] init];
        message.action = (NSString *) ACTION_LOCATION_RESPONSE;
        message.location = location;

//        NSError *error = nil;
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        NSData *jsonData = [message jsonData];

//        if (jsonData) {
        [self.socket writeData:jsonData withTimeout:kDefaultTimeout tag:0];
//        } else {
//            NSLog(@"***JSON Error=%@", error);
//        }
    }
}


- (void)requestLocationForClientWithID:(NSString *)clientId {
    if ([self.socket isConnected] && clientId) {
//        NSDictionary *data = @{
//                @"action" : ACTION_LOCATION_REQUEST,
//                @"target" : clientId
//        };

        Message *message = [[Message alloc] init];
        message.action = (NSString *) ACTION_LOCATION_REQUEST;
        message.targetClientId = clientId;


        NSData *jsonData = [message jsonData];
//        NSError *error = nil;
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];


//        if (jsonData) {
        [self.socket writeData:jsonData withTimeout:kDefaultTimeout tag:0];
//        } else {
//            NSLog(@"***JSON Error=%@", error);
//        }
    }
}


- (void)handleReadData:(NSData *)readData {

    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:readData options:0 error:NULL];
    if (responseObject) {

        Message *msg = [Message messageWithJSONObject:responseObject];

        if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_MESSAGE] == NSOrderedSame) {                 // Chat messages
            [self.delegate chatConnection:self didReceiveChatMessage:msg];
        }

        else if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_HEARTBEAT] == NSOrderedSame) {          // Heartbeat requests
            // reply to server with an identical heartbeat message (so that they know our connection is still alive)
            [self.socket writeData:readData withTimeout:kDefaultTimeout tag:0];
        }


        else if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_LOCATION_REQUEST] == NSOrderedSame) {    // Incoming location requests
            // someone wants to know where we are, so broadcast out the current location
            CLLocation *currentLocation = [self.delegate chatConnectionCurrentLocation:self];
            if (currentLocation) {
                [self sendLocation:currentLocation];
            }
        }

        else if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_LOCATION_RESPONSE] == NSOrderedSame) {  // location broadcast from other clients
            Message *message = [Message messageWithJSONObject:responseObject];
            [self.delegate chatConnection:self didReceiveLocation:message.location forClientID:message.clientId];
        }


        else if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_CONNECTED] == NSOrderedSame) {           // A client just connected
            // check if we connected ourselves, or if someone else connected
            if ([msg.clientId caseInsensitiveCompare:self.clientId] == NSOrderedSame) {

                // we just connected, need to update state and set connected clients
                self.connectionState = ChatConnectionStateSignedIn;
                if (msg.clients) {
                    @synchronized (_connectedClients) {
                        [_connectedClients addObjectsFromArray:msg.clients];
                    }
                }
            } else {
                NSLog(@"%@ connected", msg.clientId);

                // someone else just connected, so add them to clients and send event
                @synchronized (self) {
                    Client *newClient = [[Client alloc] init];
                    newClient.clientId = msg.clientId;
                    newClient.location = msg.location;
                    @synchronized (_connectedClients) {
                        [_connectedClients addObject:newClient];
                    }
                    [self.delegate chatConnection:self clientDidConnect:newClient];
                }
            }
        }

        else if ([msg.action caseInsensitiveCompare:(NSString *) ACTION_DISCONNECTED] == NSOrderedSame) {          // A Client just disconnected
            // someone disconnected
            NSLog(@"%@ disconnected", msg.clientId);

            @synchronized (_connectedClients) {
                Client *clientToRemove = nil;
                for (Client *client in _connectedClients) {
                    if ([client.clientId caseInsensitiveCompare:msg.clientId] == NSOrderedSame) {
                        clientToRemove = client;
                        break;
                    }
                }

                if (clientToRemove) {
                    [_connectedClients removeObject:clientToRemove];
                    [self.delegate chatConnection:self clientDidDisconnect:msg.clientId];
                }

            }
        }
    }

}

- (NSArray *)connectedClients {
    return [NSArray arrayWithArray:_connectedClients];
}



#pragma mark -
#pragma mark Events
//============================================================================================================


/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
**/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connectionState = ChatConnectionStateConnectedSigningIn;
    NSLog(@"Connected to host %@, port %i", host, port);
    [sock readDataWithTimeout:kDefaultTimeout tag:1];
    CLLocation *location = [self.delegate chatConnectionCurrentLocation:self];

    // Send a "sign in" message
    Message *message = [[Message alloc] init];
    message.clientId = self.clientId;
    message.location = location;

    NSData *data = [message jsonData];

    [sock writeData:data withTimeout:kDefaultTimeout tag:0];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
**/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self handleReadData:data];
    // start a new read, so that we are constantly "polling" for data
    [sock readDataWithTimeout:kDefaultTimeout tag:1];
}


/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
**/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.clientId = nil;
    @synchronized (_connectedClients) {
        [_connectedClients removeAllObjects];
    }
    NSLog(@"socketDidDisconnect, error = %@", err);
    [self.delegate chatConnection:self clientDidDisconnect:self.clientId];
    self.connectionState = ChatConnectionStateDisconnected;
    if (err) {
        [self.delegate chatConnnection:self didReceiveError:err];
    }
}


#pragma mark -
#pragma mark Helpers
//============================================================================================================

- (Client *)myClient {
    return [self clientForID:self.clientId];
}

- (Client *)clientForID:(NSString *)string {
    for (Client *client in self.connectedClients) {
        if ([[client clientId] caseInsensitiveCompare:string] == NSOrderedSame) {
            return client;
        }
    }
    return nil;

}
@end