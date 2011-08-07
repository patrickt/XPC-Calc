//
//  main.c
//  XPC Calc Service
//
//  Created by Colin Barrett on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <xpc/xpc.h>
#include <assert.h>
#import "Shared.h"

NSMutableArray *stack = nil; 

static xpc_object_t XPC_Calc_Service_NSArray_to_xpc_array(NSArray *inArray)
{
    xpc_object_t outArray = xpc_array_create(NULL, 0);
    
    for (NSNumber *boxedNum in inArray) {
        xpc_array_set_int64(outArray, XPC_ARRAY_APPEND, [boxedNum integerValue]);
    }
    
    return outArray;
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
        
        int64_t messageType = xpc_dictionary_get_int64(event, "type");
        
        if (messageType == MessagePush) {
            xpc_object_t reply = xpc_dictionary_create_reply(event);
            
            [stack addObject:[NSNumber numberWithInteger:xpc_dictionary_get_int64(event, "num")]];
            xpc_dictionary_set_value(reply, "stack", XPC_Calc_Service_NSArray_to_xpc_array(stack));
            
            xpc_connection_send_message(peer, reply);
            xpc_release(reply);        
        } else if (messageType == MessageOperator) {
            xpc_object_t reply = xpc_dictionary_create_reply(event);
            
            xpc_connection_send_message(peer, reply);
            xpc_release(reply);        
        } else if (messageType == MessageClear) {
            [stack removeAllObjects];
        }
	}
}

static void XPC_Calc_Service_event_handler(xpc_connection_t peer) 
{
    stack = [[NSMutableArray alloc] init];

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
