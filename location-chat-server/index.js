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

var net = require('net')
// imports
    , util = require('util')
    , Client = require('./client')
    , Constants = require('./constants')

// functions
    , heartbeat
    , startCheckingHeartbeats
    , startSendingHeartbeats
    , cleanup
    , getTimestamp
    , removeClientWithId

// globals
    , connCount = 0
    , connectionHeartbeats = {}
    , connections = {}
    , clients = {}
    , server;


server = net.createServer(function (conn) {

    console.log("\033[90m New connection. \033[39m");
    conn.setEncoding('utf8');
    connCount++;
    var cid;

    conn.on('close', function () {
        console.log(cid, " disconnected.");
        var aMsg = {};
        aMsg[Constants.key.ACTION] = Constants.action.DISCONNECT;
        broadcast(aMsg, false);
        connCount--;
        removeClientWithId(cid);
    });

    conn.on('data', function (data) {

        var message;

        try {
            message = JSON.parse(data);
        } catch (e) {
            console.log("***JSON Error: " + e);
            message = null;
        }

        // if the message was not in a valid JSON format, we log an error and return to waiting for incoming requests
        if (!message) {
            return;
        }


        // We need to check if this client's ID is set. If it is not, we need them to do that before they can
        // do any other type of interacting with the server.
        if (cid) {

            var theClient = clients[cid];

            if (message[Constants.key.ACTION] == Constants.action.LOCATION_BROADCAST) {   //----- A client is broadcasting their updated location
                console.log("\033[31m broadcasting location for cid " + cid + " \033[39m");
                if (message[Constants.key.LOCATION] && theClient) {
                    // Update the location we have stored in memory for this client
                    theClient[Constants.key.LOCATION] = message[Constants.key.LOCATION];
                }
                // Alert the rest of the "chat room" that this user has updated their location
                broadcast(message, true);
            }

            else if (message[Constants.key.ACTION] == Constants.action.MESSAGE) {    // -------------- A client is sending a message to the group
                console.log("\033[31m ", cid, ">", message, "\033[39m");
                // Update the location we have stored in memory for this client
                if (message[Constants.key.LOCATION] && theClient) {
                    theClient[Constants.key.LOCATION] = message[Constants.key.LOCATION];
                }
                // Broadcast this chat message to all connected users
                broadcast(message, true);
            }

            else if (message[Constants.key.ACTION] == Constants.action.LOCATION_REQUEST) {  // A client is requesting the location of another user
                var target = message[Constants.key.TARGET]; // this is the Client ID of the user whose location is being requested
                if (target) {
                    // get the socket for the user with this client ID
                    var client = connections[target];
                    if (client) {
                        console.log(util.format("sending location request to %s", target));
                        // ask this user for their updated location...
                        var aMsg = {};
                        aMsg[Constants.key.ACTION] = Constants.action.LOCATION_REQUEST;
                        client.write(JSON.stringify(aMsg));
                    }
                }
            }

            else if (message[Constants.key.ACTION] == Constants.action.HEARTBEAT) { // ------ A client is reporting that they are still connected
                // Save the current time as the last time we heard from this user (reset the connection timeout)
                connectionHeartbeats[cid] = getTimestamp();
            }

        } else {

            // cid (client ID) not set, so parse "login"
            cid = message[Constants.key.CLIENT_ID];
            if (connections[cid]) {
                return console.log("\031[31m Someone already signed in as", cid, "\031[39m");
            }

            // initial sign in:
            console.log("\033[30m Signed in as ", cid, "\033[39m");
            connections[cid] = conn;

            // create a new client
            clients[cid] = new Client(cid, message[Constants.key.LOCATION], getTimestamp());

            // notify self that we connected, pass along clients of connected connections
            var connectMsg = {};
            connectMsg[Constants.key.ACTION] = Constants.action.CONNECT;
            connectMsg[Constants.key.CLIENT_ID] = cid;
            connectMsg[Constants.key.CLIENTS] = clients;

            var buffer = JSON.stringify(connectMsg);
            conn.write(buffer);

            // set the first heartbeat
            connectionHeartbeats[cid] = getTimestamp();

            // notify everyone else that we connected
            var broadcastData = {};
            broadcastData[Constants.key.ACTION] = Constants.action.CONNECT;
            broadcastData[Constants.key.CLIENT_ID] = cid;
            broadcastData[Constants.key.DATE] = getTimestamp();

            if (message[Constants.key.LOCATION]) {
                broadcastData[Constants.key.LOCATION] = message[Constants.key.LOCATION];
            }
            broadcast(broadcastData, false);
        }
    });


    /**
     * Sends a message to all connected clients.
     *
     * @param msg Object    that contains fields such as client ID (cid), location, action, date, etc...
     * @param includeSelf   boolean that decides whether or not to dispatch the message back to the sender as well as
     *                      other connected clients
     */
    function broadcast(msg, includeSelf) {
        if (msg) {
            msg[Constants.key.DATE] = getTimestamp();
            msg[Constants.key.CLIENT_ID] = cid;
            for (var i in connections) {
                var client = connections[i];
                var send = true;
                if (client == conn) {
                    send = includeSelf;
                }

                if (send && client) {
                    client.write(JSON.stringify(msg));
                }
            }
        }
    }


});

/**
 * Get the current time in seconds
 *
 * @returns {number} current unix time in seconds
 */
getTimestamp = function () {
    return ((new Date).getTime() / 1000);
};

/**
 * Send a 'heartbeat' message to all connected sockets. Also check if any sockets haven't
 * responded in a given time period, and forcefully disconnect them if that is the case.
 */
heartbeat = function () {
    var i, conn, msg, hbMsg = {};
    hbMsg[Constants.key.ACTION] = Constants.action.HEARTBEAT;

    msg = JSON.stringify(hbMsg);
    for (i in connections) {
        conn = connections[i];
        if (conn) {
            conn.write(msg);
        }
    }
};

/**
 * Remove connections that have timed out
 */
cleanup = function () {
    var cid, lastHeartbeat, conn;
    for (cid in connectionHeartbeats) {
        lastHeartbeat = connectionHeartbeats[cid];
        // if the last timestamp was over a certain number of seconds ago, consider it timed out, and
        // force-close that connection
        if (getTimestamp() - lastHeartbeat > Constants.setting.CONNECTION_TIMEOUT) {
            conn = connections[cid];
            if (conn) {
                console.log(util.format("Connection %s has timed out, closing.", cid));
                conn.end(0);
                removeClientWithId(cid);
            }
        }
    }
}

/**
 * Removes references to a given client from the app (the connection should be properly closed with socket.end() first)
 * @param cid the client ID to remove
 */
removeClientWithId = function (cid) {
    delete connections[cid];
    delete clients[cid];
    delete connectionHeartbeats[cid];
};


/**
 * Start checking heartbeats of clients to see if any have timed out
 */
startCheckingHeartbeats = function () {
    setInterval(function cleanupOnInterval() {
        cleanup();
    }, Constants.setting.HEARTBEAT_CHECK_INTERVAL);
};

/**
 * Start sending heartbeats to the clients on an interval
 */
startSendingHeartbeats = function () {
    setInterval(function sendHeartbeatMessages() {
        heartbeat();
    }, Constants.setting.HEARTBEAT_CHECK_INTERVAL);
};

server.listen(3000, function () {
    console.log("\033[96m Server listening on 3000 \033[39m");
});

startSendingHeartbeats();

// start checking the heartbeat after 2 seconds (give the clients time to respond from the initial request)
setTimeout(function () {
    startCheckingHeartbeats();
}, 2000);
