var net = require('net')
    , util = require('util')
    , heartbeat
    , startCheckingHeartbeats
    , startSendingHeartbeats
    , cleanup
    , getTimestamp
    , removeClientWithId
    , Client = require('./client')
    , connCount = 0
    , connections = {}
    , connectionHeartbeats = {}
    , clients = {}
    , server
    , ACTION_MESSAGE = 'msg'
    , ACTION_DISCONNECT = 'dis'
    , ACTION_CONNECT = 'con'
    , ACTION_LOCATION_REQUEST = 'loc_req'
    , ACTION_LOCATION_BROADCAST = 'loc_res'
    , ACTION_HEARTBEAT = 'hb'
    , CONNECTION_TIMEOUT = 20 // 20 seconds of inactivity forces connection close
    , HEARTBEAT_CHECK_INTERVAL = 5000 // check for dropped connections every 5 seconds
    ;


server = net.createServer(function (conn) {
    console.log("\033[90m New connection. \033[39m");
    conn.setEncoding('utf8');
    connCount++;
    var cid;

    conn.on('close', function () {
        console.log(cid, " disconnected.");
        broadcast({'action': ACTION_DISCONNECT}, false);
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

        if (!message) {
            return;
        }

        if (cid) {
            //treat as json for rest of request types...
            var theClient = clients[cid];

            if (message.action == ACTION_LOCATION_BROADCAST) {
                console.log("\033[31m broadcasting location for cid " + cid + " \033[39m");
                if (message.location && theClient) {
                    theClient.location = message.location;
                }
                broadcast(message, true);
            }

            else if (message.action == ACTION_MESSAGE) {
                console.log("\033[31m ", cid, ">", message, "\033[39m");
                if (message.location && theClient) {
                    theClient.location = message.location;
                }
                broadcast(message, true);
            }

            else if (message.action == ACTION_LOCATION_REQUEST) {
                var target = message.target;
                if (target) { // this is the CID who we need to know their location
                    var client = connections[target];
                    if (client) {
                        console.log(util.format("sending location request to %s", target));
                        client.write(JSON.stringify({
                            "action": ACTION_LOCATION_REQUEST
                        }));
                    }
                }
            }

            else if (message.action == ACTION_HEARTBEAT) {
                connectionHeartbeats[cid] = getTimestamp();
            }

        } else {
            // cid not set, so parse login...
            cid = message.cid;
            if (connections[cid]) {
                console.log("\031[31m Someone already signed in as", cid, "\031[39m");
            }

            // initial sign in:
            else {
                console.log("\033[30m Signed in as ", cid, "\033[39m");
                connections[cid] = conn;

                // create a new client
                var theClient = new Client(cid, message.location, getTimestamp());
                clients[cid] = theClient;

                console.log("client id = ", theClient.clientId);

                // notify self that we connected, pass along clients of connected connections
                var buffer = JSON.stringify({
                    "action": ACTION_CONNECT,
                    "cid": cid,
                    "clients": clients
                });
                console.log("clients ", clients);
                console.log("writing buffer ", buffer);
                conn.write(buffer);

                // set the first heartbeat
                connectionHeartbeats[cid] = getTimestamp();

                // notify everyone else that we connected
                var broadcastData = {'action': ACTION_CONNECT, 'cid': cid, 'date': getTimestamp()};
                if (message.location) {
                    broadcastData.location = message.location;
                }
                broadcast(broadcastData, false);
            }
        }
    });


    function broadcast(msg, includeSelf) {
        if (msg) {
            msg.date = getTimestamp();
            msg.cid = cid;
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
}

/**
 * Send a 'heartbeat' message to all connected sockets. Also check if any sockets haven't
 * responded in a given time period, and forcefully disconnect them if that is the case.
 */
heartbeat = function () {
    var i, conn, msg = JSON.stringify({'action': ACTION_HEARTBEAT});
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
        if (getTimestamp() - lastHeartbeat > CONNECTION_TIMEOUT) {
            conn = connections[cid];
            if (conn) {
                console.log(util.format("Connection %s has timed out, closing.", cid));
                conn.end();
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
}


/**
 * Start checking heartbeats of clients to see if any have timed out
 */
startCheckingHeartbeats = function (){
    setInterval(function cleanupOnInterval() {
        cleanup();
    }, HEARTBEAT_CHECK_INTERVAL);
};

/**
 * Start sending heartbeats to the clients on an interval
 */
startSendingHeartbeats = function() {
    setInterval(function sendHeartbeatMessages() {
        heartbeat();
    }, HEARTBEAT_CHECK_INTERVAL);
}

server.listen(3000, function () {
    console.log("\033[96m Server listening on 3000 \033[39m");
});

startSendingHeartbeats();

// start checking the heartbeat after 2 seconds (give the clients time to respond from the initial request)
setTimeout(function() {
    startCheckingHeartbeats();
}, 2000);
