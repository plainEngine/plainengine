#import <Foundation/Foundation.h>

/** This class represents the queue of notifications */
@interface MPNotificationQueue : NSObject
{
	// the FIFO
	NSMutableArray *notifications;
	// synchronization object
	NSLock *theLock;
}
/** Receives notifications and adds them to the FIFO */
- (void) receiveNotification: (NSNotification *)anNotification;

/**
  * Gets the element from FIFO's top
  * (method just returns pointer and doesn't retain object)
  */
- (NSNotification *) getTop;
/** Removes the top element of FIFO */
- (void) popTop;

/** Factory method */
+ notificationQueue;
@end

