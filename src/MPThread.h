#import <Foundation/Foundation.h>
#import <MPNotificationQueue.h>
#import <MPSubject.p>
#import <MPThreadStrategy.h>
#import <MPUtility.h>
#import <MPStringToCStringConverter.h>

typedef enum
{
	message_receiving = 0,
	request_receiving, 
	elements_count
} subject_binding_target;


@interface MPThread : NSObject
{
@private
	// stuff
	MPNotificationQueue *notifications;
	MPThreadStrategy *strategy;
	NSMutableArray *routinesStack;
	// containers
	NSMutableDictionary *subjects; // name to subject
	NSMutableDictionary *messageNameToSubscribedSubjects; // message name to array of subscribed subjects
	NSMutableDictionary *requestNameToSubscribedSubjects; // request name to array of subscribed subjects
	NSMutableArray *subjectsWhichHandleAllMessages;
	NSMutableArray *allSubjects;
	SEL handleMessageWithName;
	//
	MPPool *mutableStringPool;
	MPStringToCStringConverter *cstrconv;	
}
- init;
- initWithStrategy: (MPThreadStrategy *)aStrategy;
- (void) dealloc;
+ thread;
+ threadWithStrategy: (MPThreadStrategy *)aStrategy;
//
- (BOOL) isWorking;
- (void) prepare;
- (void) start;
- (void) stop;
- (void) pause;
- (void) resume;
// 
- (void) threadRoutine;
- (BOOL) processNextMessage;
- (void) yield;
//
- (BOOL) addSubject: (id<MPSubject>)aSubject withName: (NSString *)aName;
- (BOOL) removeSubjectWithName: (NSString *)aName;
//
- (BOOL) bindSubjectWithName: (NSString *)aName to: (subject_binding_target)aTarget withName: (NSString *)aName;
- (BOOL) bindSubject: (id<MPSubject>)aSubject to: (subject_binding_target)aTarget withName: (NSString *)aName;
- (void) unbindSubject: (id<MPSubject>)aSubject;
//
- (id<MPSubject>) getSubjectByName: (NSString *)aName;
@end

