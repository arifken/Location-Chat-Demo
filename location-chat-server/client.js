
/**
 * Client
 *
 * Model object representing a client connected to the application
 *
 */
function Client() {
    if (arguments.length > 0) {
        this.cid = arguments[0];
    }

    if (arguments.length > 1) {
        this.location = arguments[1];
    }

    if (arguments.length > 2) {
        this.locationDate = arguments[2];
    }
}

module.exports = Client;