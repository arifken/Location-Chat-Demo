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
#import "ChatConnection.h"
#import "GCDAsyncSocket.h"
#import "ChatMessage.h"
#import "CLLocation+String.h"
#import "Client.h"
#import "Constants.h"

NSString const *ACTION_CONNECTED = @"con";
NSString const *ACTION_DISCONNECTED = @"dis";
NSString const *ACTION_MESSAGE = @"msg";
NSString const *ACTION_LOCATION_REQUEST = @"loc_req";
NSString const *ACTION_LOCATION_RESPONSE = @"loc_res";
NSString const *ACTION_HEARTBEAT= @"hb";

static const float kDefaultTimeout = -1.0;

@implementation ChatConnection


- (id)initWithClientId:(NSString *)clientId {
    self = [self init];
    if (self) {
        self.clientId = clientId;
    }

    return self;
}

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


- (void)connect {
    NSError *error = nil;
    [self.socket connectToHost:@"localhost" onPort:3000 error:&error];
    if (error) {
        NSLog(@"***Error connexcting to host! %@", error);
    }
}


- (void)disconnect {
    [self.socket disconnect];
}


- (void)send:(ChatMessage *)message {
    if (self.socket.isConnected) {
        [self.socket writeData:[message jsonData] withTimeout:kDefaultTimeout tag:0];
    }
}

- (void)sendLocation:(CLLocation *)location {
    if (self.socket.isConnected && location) {
        NSDictionary *data = @{
                @"action" : ACTION_LOCATION_RESPONSE,
                @"location" : [location coordinatesAsString]
        };
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];

        if (jsonData) {
            [self.socket writeData:jsonData withTimeout:kDefaultTimeout tag:0];
        } else {
            NSLog(@"***JSON Error=%@", error);
        }
    }
}


- (void)requestLocationForClientWithID:(NSString *)clientId {
    if ([self.socket isConnected] && clientId) {
        NSDictionary *data = @{
                @"action" : ACTION_LOCATION_REQUEST,
                @"target" : clientId
        };
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];

        if (jsonData) {
            [self.socket writeData:jsonData withTimeout:kDefaultTimeout tag:0];
        } else {
            NSLog(@"***JSON Error=%@", error);
        }
    }
}


- (void)handleReadData:(NSData *)readData {

    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:readData options:0 error:NULL];
    if (responseObject) {
        NSString *action = [responseObject objectForKey:@"action"];
        if ([action caseInsensitiveCompare:(NSString *) ACTION_MESSAGE] == NSOrderedSame) {
            ChatMessage *message = [ChatMessage messageWithJSONObject:responseObject];
            [self.delegate chatConnection:self didReceiveMessage:message];
        }

        else if ([action caseInsensitiveCompare:(NSString*)ACTION_HEARTBEAT] == NSOrderedSame) {
            // reply to server with an identical heartbeat message
            [self.socket writeData:readData withTimeout:kDefaultTimeout tag:0];
        }

        else if ([action caseInsensitiveCompare:(NSString *) ACTION_LOCATION_REQUEST] == NSOrderedSame) {
            NSLog(@"got location request....");
            // someone wants to know where we are, so broadcast out the current location
            CLLocation *currentLocation = [self.delegate chatConnectionCurrentLocation:self];
            if (currentLocation) {
                NSLog(@"...sending back location: %@",currentLocation);
                [self sendLocation:currentLocation];
            }
        }

        else if ([action caseInsensitiveCompare:(NSString *) ACTION_LOCATION_RESPONSE] == NSOrderedSame) {
            NSLog(@"got location response...");
            NSString *locString = [responseObject objectForKey:@"location"];
            NSString *cid = [responseObject objectForKey:@"cid"];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[responseObject objectForKey:@"date"] doubleValue]];

            [self.delegate chatConnection:self didReceiveLocation:[CLLocation locationWithCoordinateString:locString date:date] forClientID:cid];
        }

        else if ([action caseInsensitiveCompare:(NSString *) ACTION_CONNECTED] == NSOrderedSame) {
            // check if we connected ourselves, or if someone else connected
            NSString *clientId = [responseObject objectForKey:@"cid"];
            if ([clientId caseInsensitiveCompare:self.clientId] == NSOrderedSame) {
                // we just connected, need to update state and set connected clients
                self.connectionState = ChatConnectionStateSignedIn;
                NSDictionary *clients = [responseObject objectForKey:@"clients"];
                NSLog(@"clients: %@", clients);

                // parse out current clients

                for (NSDictionary *aClientId in [clients allKeys]) {
                    NSDictionary *clientDict = [clients objectForKey:aClientId];
                    Client *newClient = [Client clientWithJSONDictionary:clientDict];
                    @synchronized (self) {
                        [_connectedClients addObject:newClient];
                    }
                }

            } else {
                NSLog(@"%@ connected", clientId);

                // someone else just connected, so add them to clients and send event
                @synchronized (self) {
                    Client *newClient = [[Client alloc] init];
                    newClient.clientId = clientId;
                    newClient.location = [CLLocation locationWithCoordinateString:[responseObject objectForKey:@"location"] date:[NSDate dateWithTimeIntervalSince1970:[[responseObject objectForKey:@"date"] doubleValue]]];
                    [_connectedClients addObject:newClient];
                    [self.delegate chatConnection:self clientDidConnect:newClient];
                }
            }
        }

        else if ([action caseInsensitiveCompare:(NSString *) ACTION_DISCONNECTED] == NSOrderedSame) {
            // someone disconnected
            NSString *clientId = [responseObject objectForKey:@"cid"];
            NSLog(@"%@ disconnected", clientId);

            @synchronized (self) {
                Client *clientToRemove = nil;
                for (Client *client in _connectedClients) {
                    if ([client.clientId caseInsensitiveCompare:clientId] == NSOrderedSame) {
                        clientToRemove = client;
                        break;
                    }
                }

                if (clientToRemove) {
                    [_connectedClients removeObject:clientToRemove];
                    [self.delegate chatConnection:self clientDidDisconnect:clientId];
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
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.clientId forKey:@"cid"];
    if (location) {
        NSString *locationString = [location coordinatesAsString];
        [dict setObject:locationString forKey:@"location"];
    }

    NSError *error1 = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error1];
    if (error1) {
        NSLog(@"JSON parse error: %@", error1);
    } else {
        [sock writeData:data withTimeout:kDefaultTimeout tag:0];
    }
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