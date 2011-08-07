//
//  main.c
//  XPC Calc Service
//
//  Created by Colin Barrett on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <xpc/xpc.h>
#include <assert.h>

static void XPC_Calc_Service_process_request(xpc_object_t request, xpc_object_t reply)
{
    xpc_dictionary_set_string(reply, "message", "hello world");
}

static void XPC_Calc_Service_peer_event_handler(xpc_connection_t peer, xpc_object_t event) 
{
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
		// Handle the message.
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        XPC_Calc_Service_process_request(event, reply);
        xpc_connection_send_message(peer, reply);
        xpc_release(reply);        
	}
}

static void XPC_Calc_Service_event_handler(xpc_connection_t peer) 
{
	// By defaults, new connections will target the default dispatch
	// concurrent queue.
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		XPC_Calc_Service_peer_event_handler(peer, event);
	});
	
	// This will tell the connection to begin listening for events. If you
	// have some other initialization that must be done asynchronously, then
	// you can defer this call until after that initialization is done.
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[])
{
	xpc_main(XPC_Calc_Service_event_handler);
	return 0;
}
