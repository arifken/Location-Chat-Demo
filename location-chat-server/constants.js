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

module.exports = {

    action: {
        MESSAGE: 'msg', // action indicating a chat message has been sent by a user to the "chat room"
        DISCONNECT: 'dis', // action fired when a user is disconnected from the server
        CONNECT: 'con', // action fired when a user connects to the server
        LOCATION_REQUEST: 'loc_req', // action fired when a user is requesting an updated location from another user
        LOCATION_BROADCAST: 'loc_res', // action fired when a user broadcasts their updated location to the server
        HEARTBEAT: 'hb' // action sent and received from client indicating they are still connected
    },

    key: {
        ACTION: 'action',
        MESSAGE: 'msg',
        CLIENT_ID: 'cid',
        DATE: 'date',
        LOCATION: 'location',
        TARGET: 'target',
        CLIENTS: 'clients'
    },

    setting: {
        CONNECTION_TIMEOUT: 20 // 20 seconds of inactivity forces connection close
        , HEARTBEAT_CHECK_INTERVAL: 5000 // check for dropped connections every 5 seconds
    }

}