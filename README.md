# Location Chat

This is an iOS and node.js example app to demonstrate realtime chat and location tracking in a mobile app.

## Features

  - Send realtime chat messages to other connected users
  - See other users' positions on a map
  - Request an updated location from another user
  
## To Run

The iOS app uses the [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) project for TCP connectivity, so you'll get the submodule after cloning:

    git submodule update --init --recursive

### Start the Node app

By default, the node app runs on `localhost` on port `3000`. To start the node app:

    cd ./location-chat-server
    node index.js
    
You should see
   
    Server listening on 3000

### Start the iOS app

Run the iOS app from the simulator and you should get a "sign in" screen. Just enter any name and the app will use that as your 'Client ID' for the time connected.

That's it!

