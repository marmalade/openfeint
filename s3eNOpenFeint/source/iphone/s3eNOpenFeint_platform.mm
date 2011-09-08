/*
 * iphone-specific implementation of the s3eNOpenFeint extension.
 * Add any platform-specific functionality here.
 */
/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */
#include "s3eNOpenFeint_internal.h"
#include "s3e.h"
#import "OpenFeint.h"
#import "OFChallenge.h"
#import "OpenFeint+Dashboard.h"
#import "OFChallengeDefinition.h"
#import "OFChallengeToUser.h"
#import "OFUser.h"
#import "OFHighScore.h"
#import "OFLeaderboard.h"
#import "OFAchievement.h"
#include "iwdebug.h"
#include "s3eEdk.h"
#include "s3eEdk_iphone.h"


/******* Global Variables *******/

//s3eNOFChallengeDefinition* g_nofChallengeDefinitions = nil;
NSMutableArray* g_challengeDefs;
OFChallengeToUser *g_chalToUser;

static void s3eGCReleasePlayerId(uint32 deviceID,
                                 int32 notification,
                                 void* systemData,
                                 void* instance,
                                 int32 returnCode,
                                 void* data)
{
	s3eNOFPlayerInfo *info = (s3eNOFPlayerInfo*)systemData;
	IwTrace(NOPENFEINT,("s3eGCReleasePlayerId invoked with playerId %s",
                      (const char*)info->playerId));
	s3eEdkFreeOS(info->playerId);
}

static void s3eGCReleaseChallengeDefinitions(uint32 deviceID,
                                             int32 notification,
                                             void* systemData,
                                             void* instance,
                                             int32 returnCode,
                                             void* data)
{
	s3eNOFArray *defArray = (s3eNOFArray*)systemData;
	IwTrace(NOPENFEINT,("s3eGCReleaseChallengeDefinitions invoked with count %d",
                      defArray->m_count));
	s3eEdkFreeOS(defArray->m_items); // DeAllocating all of items at once. 
}

static void s3eGCReleaseChallengeToUser(uint32 deviceID,
                                        int32 notification,
                                        void* systemData,
                                        void* instance,
                                        int32 returnCode,
                                        void* data)
{
//	s3eNOFArray *array = (s3eNOFArray*) systemData;
	s3eNOFChallengeToUser *nofChalToUser = (s3eNOFChallengeToUser *)systemData;
	
	IwTrace(NOPENFEINT,("s3eGCReleaseChallengeToUser invoked with challenger %s",
                      nofChalToUser->challenge->challenger->name));
	
	IwTrace(NOPENFEINT,("Deleting challengeDefinition"));
	s3eEdkFreeOS(nofChalToUser->challenge->challengeDefinition);
	
	IwTrace(NOPENFEINT,("Deleting challenger"));
	s3eEdkFreeOS(nofChalToUser->challenge->challenger);
	
	IwTrace(NOPENFEINT,("Deleting challenge"));
	s3eEdkFreeOS(nofChalToUser->challenge);
	
	IwTrace(NOPENFEINT,("Deleting recipient"));
	s3eEdkFreeOS(nofChalToUser->recipient);
	
//	IwTrace(NOPENFEINT,("Deleting nofChalToUser %p", nofChalToUser));
//	s3eEdkFreeOS(nofChalToUser);
	
	IwTrace(NOPENFEINT,("Deallocation complete"));
//	s3eEdkFreeOS(defArray->m_items); // DeAllocating all of items at once. 
}

/********** OpenFeint Delegate **********/

@interface NOFDelegate : NSObject <OpenFeintDelegate> {
	void *m_userLoggedInCallbackFn;
	void *m_dashboardWillAppearCallbackFn;
	void *m_dashboardDidAppearCallbackFn;
	void *m_dashboardWillDisappearCallbackFn;
	void *m_dashboardDidDisappearCallbackFn;
	void *m_showCustomOpenFeintApprovalScreenCallbackFn;
}

- (void)dashboardWillAppear;
- (void)dashboardDidAppear;
- (void)dashboardWillDisappear;
- (void)dashboardDidDisappear;
- (void)userLoggedIn:(NSString*)userId;
- (BOOL)showCustomOpenFeintApprovalScreen;

@end


@implementation NOFDelegate

- (void)userLoggedIn:(NSString*)userId {
	IwTrace(NOPENFEINT,("User loggedIn with id %s", [userId UTF8String]));
	
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH, 
                                 S3E_NOPENFEINT_CALLBACK_PLAYER_LOGGEDIN)
     == FALSE)
		return; // no callback registered for this one
	
	
	s3eNOFPlayerInfo info; 
	
	int dlen = (strlen([userId UTF8String])+1);
	char * playerId = (char*)s3eEdkMallocOS(sizeof(char) * dlen);
	strlcpy((char*)playerId, [userId UTF8String], S3E_NOPENFEINT_STRING_MAX);
	
	info.playerId = playerId;
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_PLAYER_LOGGEDIN,
						   (void*)&info,
						   sizeof(info),
						   NULL,
						   S3E_FALSE,
						   s3eGCReleasePlayerId,
						   NULL);	
 
}
		
		
- (void)dashboardWillAppear {
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH,
                                 S3E_NOPENFEINT_CALLBACK_DASHBOARD_WILL_APPEAR) 
     == S3E_FALSE)
		return;		
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DASHBOARD_WILL_APPEAR);
}

- (void)dashboardDidAppear {
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH,
                                 S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_APPEAR)
     == S3E_FALSE)
		return;		
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_APPEAR);
}

- (void)dashboardWillDisappear {
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH,
                                 S3E_NOPENFEINT_CALLBACK_DASHBOARD_WILL_DISAPPEAR)
     == S3E_FALSE)
		return;		
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DASHBOARD_WILL_DISAPPEAR);
}

- (void)dashboardDidDisappear {
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH,
                                 S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_DISAPPEAR)
     == S3E_FALSE)
		return;		
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_DISAPPEAR);
}

- (BOOL)showCustomOpenFeintApprovalScreen {
	return FALSE;
}

@end
		

/********** OpenFeintNotification Delegate **********/
@interface NOFNotificationDelegate : NSObject<OFNotificationDelegate>
{
	
}

-(BOOL)isOpenFeintNotificationAllowed:(OFNotificationData*)notificationData;
-(void)handleDisallowedNotification:(OFNotificationData*)notificationData;
-(void)notificationWillShow:(OFNotificationData*)notificationData;

@end

@implementation NOFNotificationDelegate

-(BOOL)isOpenFeintNotificationAllowed:(OFNotificationData*)notificationData
{
  IwTrace(NOPENFEINT, ("isOpenFeintNotificationAllowed called"));
  if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH,
                                 S3E_NOPENFEINT_CALLBACK_IS_OPENFEINT_NOTIFICATION_ALLOWED)
     == S3E_FALSE)
    return TRUE;
  
  s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
                         S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_APPEAR);
	return TRUE;
}

-(void)handleDisallowedNotification:(OFNotificationData*)notificationData
{
	
}

-(void)notificationWillShow:(OFNotificationData*)notificationData
{
	
}

@end

/******** OpenFeint Challenge Delegate ********/

@interface NOFChallengeDelegate : NSObject<OFChallengeDelegate>
{
	
}

- (void)userLaunchedChallenge:(OFChallengeToUser*)challengeToLaunch 
            withChallengeData:(NSData*)challengeData;
- (void)userRestartedChallenge;
- (void)userRestartedCreateChallenge;
- (void)completedChallengeScreenClosed;
- (void)sendChallengeScreenClosed;
- (void)userBootedWithUnviewedChallenges:(NSUInteger)numChallenges;
- (void)userSentChallenges;

@end

@implementation NOFChallengeDelegate

- (void)userLaunchedChallenge:(OFChallengeToUser*)challengeToLaunch 
            withChallengeData:(NSData*)challengeData
{
	IwTrace(NOPENFEINT,("User launched challenge %s", 
                      [[[challengeToLaunch challenge] 
                        challengeDescription] UTF8String]));
	IwTrace(NOPENFEINT,("Challenge data %s", (const char *)challengeData));
	if (s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH, 
                                  S3E_NOPENFEINT_CALLBACK_USER_LAUNCHED_CHALLENGE)
      ==S3E_FALSE) {
		return; // no callback registered
	}
	
	// We have a callback. We need to serialize challengeToLaunch data and provide it to callback via s3eNOFChallengeToUser
	NSDate* today = [NSDate date];
	NSString *strFileName = [NSString stringWithFormat:@"challenge_%d",
                           (int)[today timeIntervalSince1970]];
	NSString *strFile = [NSTemporaryDirectory() 
                       stringByAppendingPathComponent:strFileName];
	IwTrace(NOPENFEINT,("Serialized challenge to %s", [strFile UTF8String]));
	[challengeToLaunch writeToFile:strFile];
	
	// Lets allocate and fill struct to pass all this god forsaken challenge info to our consumer
	
	// Challenge Definition struct
	s3eNOFChallengeDefinition *challengeDefinition = 
  (s3eNOFChallengeDefinition*)s3eEdkMallocOS(sizeof(s3eNOFChallengeDefinition),
                                             TRUE);
	strncpy(challengeDefinition->title, 
			[[[[challengeToLaunch challenge] challengeDefinition] title] 
       UTF8String], S3E_NOPENFEINT_STRING_MAX);
	
	strncpy(challengeDefinition->iconUrl,
			[[[[challengeToLaunch challenge] challengeDefinition] iconUrl]
       UTF8String], S3E_NOPENFEINT_STRING_MAX);
	
	strncpy(challengeDefinition->clientApplicationId,
			[[[[challengeToLaunch challenge] challengeDefinition] clientApplicationId]
       UTF8String], S3E_NOPENFEINT_STRING_MAX);
	
	challengeDefinition->multiAttempt = [[[challengeToLaunch challenge] 
                                        challengeDefinition] multiAttempt];
	
	challengeDefinition->s3eNOFchallengeId = 0; // dont really care about this one here
	
//	OFUser *user;
//	[user lastPlayedGameId
	// OFUser (our challenger that sent this request) s3eNOFUser
	
	
	s3eNOFUser *nofchallenger = (s3eNOFUser*)s3eEdkMallocOS(sizeof(s3eNOFUser),
                                                          TRUE);
	
	if ([[[[challengeToLaunch challenge] challenger] 
        lastPlayedGameId] length]>0) {
		strncpy(nofchallenger->lastPlayedGameId, 
				[[[[challengeToLaunch challenge] challenger] lastPlayedGameId]
         UTF8String],	S3E_NOPENFEINT_STRING_MAX);
	}
	
	if ([[[[challengeToLaunch challenge] challenger] name] length]>0) {
		strncpy(nofchallenger->name, 
				[[[[challengeToLaunch challenge] challenger] name] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	

	IwTrace(NOPENFEINT, ("Last Played Game Id %s",
                       [[[[challengeToLaunch challenge] challenger]
                         lastPlayedGameId] UTF8String]));
	
	if ([[[[challengeToLaunch challenge] challenger]
        lastPlayedGameId] length]>0) {
		strncpy(nofchallenger->lastPlayedGameName, 
				[[[[challengeToLaunch challenge] challenger]
          lastPlayedGameName] UTF8String], S3E_NOPENFEINT_STRING_MAX);
	}
	IwTrace(NOPENFEINT, ("Last Played Game Name %s",
                       [[[[challengeToLaunch challenge] challenger]
                         lastPlayedGameName] UTF8String]));
	
//	OFUser *user = [[challengeToLaunch challenge] challenger];

	
	nofchallenger->online = [[[challengeToLaunch challenge] challenger] online];
	
	if ([[[[challengeToLaunch challenge] challenger] userId] length]>0) {
		strncpy(nofchallenger->userId, 
				[[[[challengeToLaunch challenge] challenger] userId] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	
	IwTrace(NOPENFEINT, ("userId %s", [[[[challengeToLaunch challenge] challenger]
                                      userId] UTF8String]));
	
	if ([[[[challengeToLaunch challenge] challenger]
        profilePictureUrl] length]>0) {
		strncpy(nofchallenger->profilePictureUrl, 
				[[[[challengeToLaunch challenge] challenger] profilePictureUrl]
         UTF8String], S3E_NOPENFEINT_STRING_MAX);
		

	}

	IwTrace(NOPENFEINT, ("profilePictureUrl %s", [[[[challengeToLaunch challenge]
                                                  challenger] profilePictureUrl]
                                                UTF8String]));	
	snprintf(
          nofchallenger->latitude,
          sizeof(nofchallenger->latitude),
          "%f",
          [[[challengeToLaunch challenge] challenger] latitude]
          );
  snprintf(
           nofchallenger->longitude,
           sizeof(nofchallenger->longitude),
           "%f",
           [[[challengeToLaunch challenge] challenger] longitude]
          );
	
	
	// NSData challenge data
	NSData *chalData = [[challengeToLaunch challenge] challengeData];
	s3eNOFChallengeData nofchallengeData;
	nofchallengeData.data = (void*)[chalData bytes];
	nofchallengeData.length = [chalData length];
	
	
	IwTrace(NOPENFEINT, ("Creating challenge struct and copying data"));
	// OFChallenge part s3eNOFChallenge
	s3eNOFChallenge *nofchallenge = 
  (s3eNOFChallenge*) s3eEdkMallocOS(sizeof(s3eNOFChallenge), TRUE);
	
	nofchallenge->challengeDefinition = challengeDefinition;
	nofchallenge->challenger = nofchallenger;
	
	strncpy(nofchallenge->challengeDescription, 
			[[[challengeToLaunch challenge] challengeDescription] UTF8String], 
			S3E_NOPENFEINT_STRING_MAX);
	
	strncpy(nofchallenge->userMessage, 
			[[[challengeToLaunch challenge] userMessage] UTF8String], 
			S3E_NOPENFEINT_STRING_MAX);
	
	strncpy(nofchallenge->hiddenText, 
			[[[challengeToLaunch challenge] hiddenText] UTF8String], 
			S3E_NOPENFEINT_STRING_MAX);
	nofchallenge->challengeData = &nofchallengeData;
	
	strncpy(nofchallenge->challengeDataUrl, 
			[[[challengeToLaunch challenge] challengeDataUrl] UTF8String], 
			S3E_NOPENFEINT_STRING_MAX);
	
	IwTrace(NOPENFEINT, ("Copying recipient data"));
	
	// s3eNOFUser recipient
	s3eNOFUser *nofrecipient = (s3eNOFUser*)s3eEdkMallocOS(sizeof(s3eNOFUser), TRUE);
	
	if ([[[challengeToLaunch recipient] lastPlayedGameId] length]>0) {
		strncpy(nofrecipient->lastPlayedGameId, 
				[[[challengeToLaunch recipient] lastPlayedGameId] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	
	if ([[[challengeToLaunch recipient] name] length]>0) {
		strncpy(nofrecipient->name, 
				[[[challengeToLaunch recipient] name] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	
	
	IwTrace(NOPENFEINT, ("Last Played Game Id %s", [[[challengeToLaunch recipient]
                                                   lastPlayedGameId]
                                                  UTF8String]));
	
	if ([[[challengeToLaunch recipient] lastPlayedGameName] length]>0) {
		strncpy(nofrecipient->lastPlayedGameName, 
				[[[challengeToLaunch recipient] lastPlayedGameName] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	IwTrace(NOPENFEINT, ("Last Played Game Name %s",
                       [[[challengeToLaunch recipient] lastPlayedGameName]
                        UTF8String]));
	
	//	OFUser *user = [[challengeToLaunch challenge] challenger];
	
	
	nofrecipient->online = [[challengeToLaunch recipient] online];
	
	if ([[[challengeToLaunch recipient] userId] length]>0) {
		strncpy(nofrecipient->userId, 
				[[[challengeToLaunch recipient] userId] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	
	if ([[[challengeToLaunch recipient] profilePictureUrl] length]>0) {
		strncpy(nofrecipient->profilePictureUrl, 
				[[[challengeToLaunch recipient] profilePictureUrl] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	
	IwTrace(NOPENFEINT, ("profilePictureUrl %s",
                       [[[challengeToLaunch recipient]
                         profilePictureUrl] UTF8String]));	
  
	snprintf(
          nofrecipient->latitude,
          sizeof(nofrecipient->latitude),
          "%f",
          [[challengeToLaunch recipient] latitude]
          );
	snprintf(
           nofrecipient->longitude,
           sizeof(nofrecipient->longitude),
           "%f",
           [[challengeToLaunch recipient] longitude]
           );
	
	
	// ChallengeToUser s3eNOFChallengeToUser
	s3eNOFChallengeToUser *nofChalToUser = 
  (s3eNOFChallengeToUser*)s3eEdkMallocOS(sizeof(s3eNOFChallengeToUser), TRUE);
  
	nofChalToUser->challenge = nofchallenge;
	nofChalToUser->recipient = nofrecipient;
	nofChalToUser->result = (s3eNOFChallengeResult)[challengeToLaunch result];
	if ([[challengeToLaunch resultDescription] length] > 0) {
		strncpy(nofChalToUser->resultDescription,
				[[challengeToLaunch resultDescription] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	if ([[challengeToLaunch formattedResultDescription] length] > 0) {
		strncpy(nofChalToUser->formattedResultDescription,
				[[challengeToLaunch formattedResultDescription] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	nofChalToUser->hasBeenViewed = [challengeToLaunch hasBeenViewed];
	nofChalToUser->attempts = [challengeToLaunch attempts];
	nofChalToUser->hasDecrementedChallengeCount = 
  [challengeToLaunch hasDecrementedChallengeCount];
	nofChalToUser->isCompleted = [challengeToLaunch isCompleted];
	if ([[challengeToLaunch formattedResultDescription] length] > 0) {
		strncpy(nofChalToUser->formattedResultDescription,
				[[challengeToLaunch formattedResultDescription] UTF8String],
				S3E_NOPENFEINT_STRING_MAX);
	}
	nofChalToUser->hasBeenViewed = [challengeToLaunch hasBeenViewed];
	nofChalToUser->attempts = [challengeToLaunch attempts];
	nofChalToUser->hasDecrementedChallengeCount = 
  [challengeToLaunch hasDecrementedChallengeCount];
	nofChalToUser->isCompleted = [challengeToLaunch isCompleted];
	strncpy(nofChalToUser->nofPersistentId,
			[strFileName UTF8String],
			S3E_NOPENFEINT_STRING_MAX_1);
	
	
	IwTrace(NOPENFEINT,("nofChalToUser pointer %p", nofChalToUser));
	
	
	/*
	s3eNOFArray array;
	array.m_items = nofChalToUser;
	array.m_count = 1;
	*/
	
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_USER_LAUNCHED_CHALLENGE,
						   nofChalToUser,
						   sizeof(s3eNOFChallengeToUser),
						   NULL,
						   S3E_FALSE,
						   s3eGCReleaseChallengeToUser,
						   NULL);
	s3eEdkFreeOS(nofChalToUser);
	
/*	s3eEdkFreeOS(nofChalToUser);
	s3eEdkFreeOS(nofrecipient);
	s3eEdkFreeOS(nofchallenge);
	s3eEdkFreeOS(nofchallenger);
	s3eEdkFreeOS(challengeDefinition);
*/	
}

- (void)userRestartedChallenge
{
}

- (void)userRestartedCreateChallenge
{
}

- (void)completedChallengeScreenClosed
{
}

- (void)sendChallengeScreenClosed
{
}

- (void)userBootedWithUnviewedChallenges:(NSUInteger)numChallenges
{
}

- (void)userSentChallenges
{
}

@end

/********* OpenFeint OFChallengeDefinitionDelegate ******/
@interface NOFChallengeDefinitionDelegate : 
NSObject<OFChallengeDefinitionDelegate>
{
	
}

- (void) didDownloadAllChallengeDefinitions: (NSArray*)challengeDefinitions;
- (void) didDownloadChallengeDefinition: 
(OFChallengeDefinition *) 	challengeDefinition;
- (void) didFailDownloadChallengeDefinition;
- (void) didFailDownloadChallengeDefinitions;
@end

@implementation NOFChallengeDefinitionDelegate

- (void) didDownloadAllChallengeDefinitions:(NSArray *)challengeDefinitions {
	if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH, S3E_NOPENFEINT_CALLBACK_DID_DOWNLOAD_ALL_CHALLENGE_DEFINITIONS) == S3E_FALSE)
		return; // Someone asked to download definitions but then didn't register callback to retreive data
	
	// Copy all definitions to our general purpose array
	[g_challengeDefs removeAllObjects];
	// Copy to our Global Var
	[g_challengeDefs addObjectsFromArray:challengeDefinitions];
	IwTrace(NOPENFEINT,("Total challenges downloaded %d", [g_challengeDefs count]));
	IwTrace(NOPENFEINT,("Pointer address for g_challengeDefs %p", g_challengeDefs));

	
	s3eNOFChallengeDefinition* nofChallengeDefinitions = (s3eNOFChallengeDefinition*)s3eEdkMallocOS([challengeDefinitions count] * sizeof(s3eNOFChallengeDefinition), TRUE);
	
	s3eNOFArray defArray;	
	
	for (uint i=0; i < [challengeDefinitions count]; i++) {
		
		// Copy title 
		strlcpy((char*)nofChallengeDefinitions[i].title, 
				[[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] title] UTF8String], 
				S3E_NOPENFEINT_STRING_MAX);
		IwTrace(NOPENFEINT,
				("Challenge Definition title %s",
				 [[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] title] UTF8String]));
		
		// Copy iconUrl 
		strlcpy((char*)nofChallengeDefinitions[i].iconUrl, 
				[[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] iconUrl] UTF8String], 
				S3E_NOPENFEINT_STRING_MAX);
		IwTrace(NOPENFEINT,
				("Challenge Definition title %s",
				 [[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] iconUrl] UTF8String]));
		
		// Copy clientApplicationId 
		strlcpy((char*)nofChallengeDefinitions[i].clientApplicationId, 
				[[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] clientApplicationId] UTF8String], 
				S3E_NOPENFEINT_STRING_MAX);
		IwTrace(NOPENFEINT,
				("Challenge Definition title %s",
				 [[(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] clientApplicationId] UTF8String]));
		
		// Get value of multiAttempt
		nofChallengeDefinitions[i].multiAttempt = [(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:i] multiAttempt];
		
		nofChallengeDefinitions[i].s3eNOFchallengeId = i; // simple index based id
		
//		nofChallengeDefinitions[i];
	}
	defArray.m_count = [challengeDefinitions count];
	defArray.m_items = nofChallengeDefinitions;
	
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DID_DOWNLOAD_ALL_CHALLENGE_DEFINITIONS,
						   (void*)&defArray,
						   sizeof(defArray),
						   NULL,
						   S3E_FALSE,
						   s3eGCReleaseChallengeDefinitions,
						   NULL);
	 
}

- (void) didDownloadChallengeDefinition:(OFChallengeDefinition *)challengeDefinition {
}

- (void) didFailDownloadChallengeDefinition {
}

- (void) didFailDownloadChallengeDefinitions {
		if(s3eEdkCallbacksIsRegistered(S3E_EXT_NOPENFEINT_HASH, S3E_NOPENFEINT_CALLBACK_DID_FAIL_DOWNLOAD_CHALLENGE_DEFINITIONS) == S3E_FALSE)
			return; // No callback registered
	
	s3eEdkCallbacksEnqueue(S3E_EXT_NOPENFEINT_HASH,
						   S3E_NOPENFEINT_CALLBACK_DID_FAIL_DOWNLOAD_CHALLENGE_DEFINITIONS);
}

@end

/********** Delegate Instances *******/
NOFDelegate* g_ofDelegate;
NOFChallengeDefinitionDelegate* g_ofChallengeDefinitionDelegate;
NOFChallengeDelegate* g_ofChallengeDelegate;


s3eResult s3eNOpenFeintInit_platform()
{
	
	// Lets load IOSNotifications extension
/*	if (s3eIOSNotificationsAvailable()==S3E_FALSE)
	{
		IwTrace(NOPENFEINT,("IOSNotifications extension not found"));
		return S3E_RESULT_ERROR;
	}
 */
    // Add any platform-specific initialisation code here
	g_ofDelegate = [NOFDelegate new];
	g_ofChallengeDefinitionDelegate = [NOFChallengeDefinitionDelegate new];
	
	// Initialise challenge delegate
	g_ofChallengeDelegate = [NOFChallengeDelegate new];
	
	// Allocate our Array to hold challenges
	g_challengeDefs = [[NSMutableArray arrayWithCapacity:10] retain]; // initial capacity of 10. it will increase if more items are added.
    return S3E_RESULT_SUCCESS;
}

void s3eNOpenFeintTerminate_platform()
{
    // Add any platform-specific termination code here
	delete g_ofDelegate;
	delete g_ofChallengeDefinitionDelegate;	
	[g_challengeDefs removeAllObjects];
	[g_challengeDefs release];
}

s3eResult s3eNewMessageBox_platform(
                                    const char* title,
                                    const char* text
                                    )
{
	UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setTitle: [[NSString alloc] initWithUTF8String:title]];
    [dialog setMessage: [[NSString alloc] initWithUTF8String:text]];
    [dialog addButtonWithTitle:@"OK"];
    [dialog show];
    [dialog release];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFinitializeWithProductKey_platform(
                                                  const char* productKey,
                                                  const char* secret,
                                                  const char* displayName,
                                                  const s3eNOFArray* settings
                                                  )
{
	UIWindow* mainwindow = s3eEdkGetUIWindow();
	
	/*
	NSDictionary* settings1 = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:UIInterfaceOrientationPortrait], OpenFeintSettingDashboardOrientation,
							   @"FunkyRacers", OpenFeintSettingShortDisplayName,
							   [NSNumber numberWithBool:YES], OpenFeintSettingEnablePushNotifications,
							   [NSNumber numberWithBool:YES], OpenFeintSettingUseSandboxPushNotificationServer,
							   [NSNumber numberWithBool:NO], OpenFeintSettingDisableUserGeneratedContent,
							   [NSNumber numberWithBool:NO], OpenFeintSettingAlwaysAskForApprovalInDebug,
							   mainwindow, OpenFeintSettingPresentationWindow,
							   nil
							   ];
	*/

	NSString *strDisplayName = [[[NSString alloc] initWithUTF8String:displayName] autorelease];
	NSString *strSecret = [[[NSString alloc] initWithUTF8String:secret] autorelease];
	NSString *strProductKey = [[[NSString alloc] initWithUTF8String:productKey] autorelease];

	int uiOrientation = 0;
	int enablePushNotification = 0;
	int useSandboxNotification =0 ;
	int disableUserGenContent =0;
	int alwaysAskForApprovalInDbg= 0;
	NSString *strShortDisplayName = nil;
	if (!settings) {
		return S3E_RESULT_ERROR;
	}
	
	// Lets get settings for OpenFeint initialization
	IwTrace(NOPENFEINT,("Total settings array items %d", settings->m_count));
	s3eNOFSettingVal *items = (s3eNOFSettingVal*)settings->m_items;
	for (uint i=0; i< settings->m_count; i++) {
		IwTrace(NOPENFEINT, ("Varname %s", items[i].m_varName));
		if (!strcasecmp(items[i].m_varName, "OpenFeintSettingDashboardOrientation")) {
			// Dashboard orientation setting
			uiOrientation = items[i].m_intVal;
			
		}
		else if (!strcasecmp(items[i].m_varName, "OpenFeintSettingShortDisplayName")) {
			// Dashboard orientation setting
			strShortDisplayName	= [[[NSString alloc] initWithUTF8String:items[i].m_stringVal] autorelease];
			
		}
		else if (!strcasecmp(items[i].m_varName, "OpenFeintSettingEnablePushNotifications")) {

			enablePushNotification = items[i].m_intVal;
			
		}
		else if (!strcasecmp(items[i].m_varName, "OpenFeintSettingUseSandboxPushNotificationServer")) {

			useSandboxNotification = items[i].m_intVal;
			
		}
		else if (!strcasecmp(items[i].m_varName, "OpenFeintSettingDisableUserGeneratedContent")) {

			disableUserGenContent = items[i].m_intVal;
			
		}
		else if (!strcasecmp(items[i].m_varName, "OpenFeintSettingAlwaysAskForApprovalInDebug")) {

			alwaysAskForApprovalInDbg = items[i].m_intVal;
			
		}
	}
	NSDictionary* settings2 = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:uiOrientation], OpenFeintSettingDashboardOrientation,
							   strShortDisplayName, OpenFeintSettingShortDisplayName,
							   [NSNumber numberWithInt:enablePushNotification], OpenFeintSettingEnablePushNotifications,
							   [NSNumber numberWithInt:useSandboxNotification], OpenFeintSettingUseSandboxPushNotificationServer,
							   [NSNumber numberWithInt:disableUserGenContent], OpenFeintSettingDisableUserGeneratedContent,
							   [NSNumber numberWithInt:alwaysAskForApprovalInDbg], OpenFeintSettingAlwaysAskForApprovalInDebug,
							   mainwindow, OpenFeintSettingPresentationWindow,
							   nil
							   ];
	//	ofDelegate = [NOFDelegate new];
	
	OFDelegatesContainer* delegates = [OFDelegatesContainer containerWithOpenFeintDelegate:g_ofDelegate
																	  andChallengeDelegate:g_ofChallengeDelegate
																   andNotificationDelegate:nil];
	//IwTrace(GAMECENTER,"Initializing OpenFeint");
	// TODO: Use parameters sent from application (API Consumer)
	
//	const char* deviceToken = s3eIOSNotificationsGetRemoteNotificationToken();
//	IwTrace(NOPENFEINT,("Notification device token is %s",deviceToken));
//	NSData *nsDevToken = [NSData dataWithBytes:deviceToken length:strlen(deviceToken)];
	
//	[OpenFeint applicationDidRegisterForRemoteNotificationsWithDeviceToken:nsDevToken];
	
//	[nsDevToken release];
	[OpenFeint initializeWithProductKey:strProductKey
							  andSecret:strSecret
						 andDisplayName:strDisplayName
							andSettings:settings2
						   andDelegates:delegates];
	
	
	// Setting other delegates that are global
	[OFChallengeDefinition setDelegate:g_ofChallengeDefinitionDelegate];
	
	
    return S3E_RESULT_SUCCESS;	

}

s3eResult s3eNOFlaunchDashboardWithHighscorePage_platform(const char* leaderboardId)
{
	NSString *str = [[[NSString alloc] initWithUTF8String:leaderboardId] autorelease];
	[OpenFeint launchDashboardWithHighscorePage:str];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithAchievementsPage_platform()
{
	[OpenFeint launchDashboardWithAchievementsPage];
	
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithChallengesPage_platform()
{
	[OpenFeint launchDashboardWithChallengesPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithFindFriendsPage_platform()
{
	[OpenFeint launchDashboardWithFindFriendsPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithWhosPlayingPage_platform()
{
	[OpenFeint launchDashboardWithWhosPlayingPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithListGlobalChatRoomsPage_platform()
{
	[OpenFeint launchDashboardWithListGlobalChatRoomsPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithiPurchasePage_platform(const char* clientApplicationId)
{
	NSString *str = [[[NSString alloc] initWithUTF8String:clientApplicationId] autorelease];
	[OpenFeint launchDashboardWithiPurchasePage:str];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithSwitchUserPage_platform()
{
	[OpenFeint launchDashboardWithSwitchUserPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithForumsPage_platform()
{
	[OpenFeint launchDashboardWithForumsPage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithInvitePage_platform()
{
	[OpenFeint launchDashboardWithInvitePage];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithSpecificInvite_platform(const char* inviteIdentifier)
{
	NSString *str = [[[NSString alloc] initWithUTF8String: inviteIdentifier] autorelease];
	[OpenFeint launchDashboardWithSpecificInvite:str];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText_platform(
                                                                                   const char* prepopulatedText,
                                                                                   const char * originialMessage,
                                                                                   const char* imageName,
                                                                                   const char* linkedUrl
                                                                                   )
{
	NSString *prepText = [[[NSString alloc] initWithUTF8String:prepopulatedText] autorelease];
	NSString *origMsg = [[[NSString alloc] initWithUTF8String:originialMessage] autorelease];
	NSString *imgName = [[[NSString alloc] initWithUTF8String:imageName] autorelease];
	NSString *linkUrl = [[[NSString alloc] initWithUTF8String:linkedUrl] autorelease];
	
	[OpenFeint launchDashboardWithSocialNotificationWithPrepopulatedText:prepText 
														originialMessage:origMsg 
															   imageName:imgName 
															   linkedUrl:linkUrl];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFshutdown_platform()
{
	[OpenFeint shutdown];
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFlaunchDashboard_platform()
{
	[OpenFeint launchDashboard];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFdismissDashboard_platform()
{
	[OpenFeint dismissDashboard];
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFsetDashboardOrientation_platform(s3eNOFUIInterfaceOrientation orientation)
{
//	[OpenFeint setDashboardOrientation:orientation];
    return S3E_RESULT_SUCCESS;
}

ushort s3eNOFhasUserApprovedFeint_platform()
{
	return [OpenFeint hasUserApprovedFeint];
}

ushort s3eNOFisOnline_platform()
{
    return [OpenFeint isOnline];
}

s3eResult s3eNOFdisplayAndSendChallenge_platform(
                                                 s3eNOFChallengeDefinition* challengeDefinition, 
                                                 const char* challengeDescription, 
                                                 const s3eNOFChallengeData* challengeData
                                                 )
{
	NSData* data = [NSData dataWithBytes:challengeData->data 
                                length:challengeData->length];
	IwTrace(NOPENFEINT,("Total challenges %d", [g_challengeDefs count]));
	
	uint index = challengeDefinition->s3eNOFchallengeId;
	IwTrace(NOPENFEINT,("s3eNOFchallengeId is %d",index));

	
	OFChallengeDefinition *chalDef = [(OFChallengeDefinition*)[g_challengeDefs objectAtIndex:index] retain];
	IwTrace(NOPENFEINT,("displayAndSendChallenge %s", [[chalDef title] UTF8String]));
	
	NSString *strDesc = [[[NSString alloc] initWithUTF8String:challengeDescription] autorelease];
	
	OFChallenge *ofChal = [[[OFChallenge alloc] initWithDefinition:chalDef 
                                            challengeDescription:strDesc 
                                                   challengeData:data] 
                         autorelease];
	[ofChal displayAndSendChallenge];
	
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFdownloadAllChallengeDefinitions_platform()
{
	OFRequestHandle *req = [OFChallengeDefinition downloadAllChallengeDefinitions];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFdownloadChallengeDefinitionWithId_platform(const char* challengeDefinitionId)
{
	NSString *str = [[[NSString alloc] initWithUTF8String:challengeDefinitionId] autorelease];
	[OFChallengeDefinition downloadChallengeDefinitionWithId:str];
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFchallengeCompleteWithResult_platform(
                                                     s3eNOFChallengeResult challengeResult,
                                                     const char* challengePeristentId
                                                     )
{
	NSString *strFileName = [[[NSString alloc] initWithUTF8String: challengePeristentId] autorelease];
	NSString *strFile = [NSTemporaryDirectory() stringByAppendingPathComponent:strFileName];
	
	OFChallengeToUser *chalToUser = [OFChallengeToUser readFromFile:strFile];
	if (chalToUser) {
		[chalToUser completeWithResult:(OFChallengeResult)challengeResult];
	}
	else {
		IwTrace(NOPENFEINT,("s3eNOFchallengeCompleteWithResult_platform Couldn't load challengeToUser from file %s", challengePeristentId));
		return S3E_RESULT_ERROR;
	}
    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFchallengeDisplayCompletionWithData_platform(s3eNOFChallengeData* challengeData, 
															const char* reChallengeDescription, 
															const char* challengePeristentId)
{
	NSData *data =[NSData dataWithBytes:challengeData->data length:challengeData->length];
	
	NSString *strFileName = [[[NSString alloc] initWithUTF8String: challengePeristentId] autorelease];
	NSString *strFile = [NSTemporaryDirectory() stringByAppendingPathComponent:strFileName];
	
	OFChallengeToUser *chalToUser = [OFChallengeToUser readFromFile:strFile];
	if (chalToUser) {
		[chalToUser displayCompletionWithData:data 
					   reChallengeDescription:[[[NSString alloc]
						initWithUTF8String:reChallengeDescription] autorelease]];
	}
	else {
		IwTrace(NOPENFEINT,("s3eNOFchallengeDisplayCompletionWithData_platform Couldn't load challengeToUser from file %s",
                        challengePeristentId));
		return S3E_RESULT_ERROR;
	}

    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFsubmitHighScore_platform(
                                         const char* leaderBoadId,
                                         const char* score,
                                         const char* displayText,
                                         const char* customData
                                         )
{	
	 
	
	IwTrace(NOPENFEINT,("Called s3eNOFsubmitHighScore_platform"));

//	IwTrace(NOPENFEINT,("Converted score to longlong num as string %s", score));

	NSString *strScore = [[[NSString alloc] initWithUTF8String:score] autorelease];
	NSNumber* num = [NSNumber numberWithLongLong:[strScore longLongValue]];
	
//	NSString *str = [NSString stringWithFormat:@"Posting high score as %@", num];
	
//	IwTrace(NOPENFEINT,("Calling initForSubmissionWithScore with highscore", [str UTF8String]));
	OFHighScore* hscore = [[[OFHighScore alloc] initForSubmissionWithScore:[num longLongValue]] autorelease];

	if (displayText) {
		NSString* displayText1 = [[[NSString alloc] initWithUTF8String:displayText] autorelease];	
		IwTrace(NOPENFEINT,("copied displaytext %s", displayText));
		hscore.displayText = displayText1;
	}

	if (customData) {
		NSString* customData1 = [[[NSString alloc] initWithUTF8String:customData] autorelease];
		IwTrace(NOPENFEINT,("Converted customdata %s", customData));
		hscore.customData = customData1;
	}
	
	
	IwTrace(NOPENFEINT,("Getting leaderboard from id %s", leaderBoadId));
	NSString *strLeaderBoardId = [[[NSString alloc] initWithUTF8String:leaderBoadId] autorelease];
	OFLeaderboard *leaderBoard = [OFLeaderboard leaderboard:strLeaderBoardId];
	if (leaderBoard) {
		IwTrace(NOPENFEINT,("Calling Highscore object %p submitTo", hscore));
		[hscore submitTo:leaderBoard];
	}
	else {
		return S3E_RESULT_ERROR;
	}	
	
    return S3E_RESULT_SUCCESS;
}


s3eResult s3eNOFupdateAcheivementProgressionComplete_platform(const char* achievementId, double updatePercentComplete, bool showUpdateNotification)
{
  if (!achievementId) {
    return S3E_RESULT_ERROR;
  }
  
  NSString *strAchId = [[[NSString alloc] initWithUTF8String:achievementId]  autorelease];
  OFAchievement *ach = [OFAchievement achievement:strAchId];
  if (ach) { 
    [ach updateProgressionComplete:updatePercentComplete andShowNotification:showUpdateNotification];
  }

  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFachievements_platform(s3eNOFArray* achArray)
{
  

  if (achArray==NULL) {
    return S3E_RESULT_ERROR; 
  }

  NSArray *achs = [OFAchievement achievements];
  
    // Stop for loop when either our array is full or we dont have 
    // any more achievements
  uint outCount = 0;

  for (uint i=0; i<achArray->m_count && i<[achs count]; i++) {

    s3eNOFAchievement *achievement = &((s3eNOFAchievement*)achArray->m_items)[i];

    OFAchievement *ach = [achs objectAtIndex:i];
    
      // copy all data to struct
      // Copy Title

    
    if ([ach title]) {
      strncpy(
              achievement->title,
              [[ach title] UTF8String],
              sizeof(achievement->title)
              );
    }
    
    IwTrace(NOPENFEINT, ("Achievement title %s and copied %s",
                         [[ach title] UTF8String],
                         achievement->title));
    
      // Copy Description
    if ([ach description]) {
      strncpy(
              achievement->description,
              [[ach description] UTF8String],
              sizeof(achievement->description)
              );
    }
    

      // Copy Gamerscore
    achievement->gamerscore = [ach gamerscore];
    
    
    achievement->isSecret = [ach isSecret];
    
    
    NSDate *unlockDate = [ach unlockDate];
    if (unlockDate) {
      achievement->unlockDate = [unlockDate timeIntervalSince1970];
    }

    achievement->isUnlocked = [ach isUnlocked];
    
    
    snprintf(
             achievement->percentComplete,
             sizeof(achievement->percentComplete),
             "%f",
             [ach percentComplete]
             );
    
    achievement->isUnlockedByComparedToUser = [ach isUnlockedByComparedToUser];

    
    if ([ach comparedToUserId]) {
      strncpy(
              achievement->comparedToUserId,
              [[ach comparedToUserId] UTF8String],
              sizeof(achievement->comparedToUserId)
              );
    }
    
    
    if ([ach endVersion]) {
      strncpy(
              achievement->endVersion,
              [[ach endVersion] UTF8String],
              sizeof(achievement->endVersion)
              );
    }
    
    
    if ([ach startVersion]) {
      strncpy(
              achievement->startVersion,
              [[ach startVersion] UTF8String],
              sizeof(achievement->startVersion)
              );
    }

    
    achievement->position = [ach position];
    
    
    if ([ach iconUrl]) {
      strncpy(
              achievement->iconUrl,
              [[ach iconUrl] UTF8String],
              sizeof(achievement->iconUrl)
              );
    }

    outCount++;
    
  }
  achArray->m_count = outCount;
  
    //  s3eNOFachievements(achArray);
    //  IwTrace(NOPENFEINT, ("Size of double %d", (int)sizeof(double)));
    //  IwTrace(NOPENFEINT, ("Achievement size %d", (int)sizeof(s3eNOFAchievement)));
  for (uint i=0; i < achArray->m_count; i++) {
      //      s3eNOFAchievement* ach = &((s3eNOFAchievement*)achArray.m_items[i]);
      //    IwTrace(NOPENFEINT,("Acheivement at %p title %s", 
      //                &((s3eNOFAchievement*)achArray->m_items)[i],
      //                ((s3eNOFAchievement*)achArray->m_items)[i].title));
  }
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFachievement_platform(
                                     s3eNOFAchievement *achievement,
                                     const char* achievementId
                                     )
{
  NSString *strAchId = [[[NSString alloc] initWithUTF8String:achievementId] 
                        autorelease];
  OFAchievement *ach = [OFAchievement achievement:strAchId];
  
  if (!ach || !achievement) {
    return S3E_RESULT_ERROR;
  }
  
  
    // copy all data to struct
  
    // Copy Title
  if ([ach title]) {
    strncpy(
            achievement->title,
            [[ach title] UTF8String],
            sizeof(achievement->title)
            );
  }
  

    // Copy Description
  
  if ([ach description]) {
    strncpy(
            achievement->description,
            [[ach description] UTF8String],
            sizeof(achievement->description)
            );
  }
  

    // Copy Gamerscore
  achievement->gamerscore = [ach gamerscore];
  

  achievement->isSecret = [ach isSecret];
  

  NSDate *unlockDate = [ach unlockDate];
  if (unlockDate) {
    achievement->unlockDate = [unlockDate timeIntervalSince1970];
  }

  achievement->isUnlocked = [ach isUnlocked];
  

  snprintf(
           achievement->percentComplete,
           sizeof(achievement->percentComplete),
           "%f",
           [ach percentComplete]
           );
  
  achievement->isUnlockedByComparedToUser = [ach isUnlockedByComparedToUser];
  

  if ([ach comparedToUserId]) {
    strncpy(
            achievement->comparedToUserId,
            [[ach comparedToUserId] UTF8String],
            sizeof(achievement->comparedToUserId)
            );
  }
  

  if ([ach endVersion]) {
    strncpy(
            achievement->endVersion,
            [[ach endVersion] UTF8String],
            sizeof(achievement->endVersion)
            );
  }
  

  if ([ach startVersion]) {
    strncpy(
            achievement->startVersion,
            [[ach startVersion] UTF8String],
            sizeof(achievement->startVersion)
            );
  }
  

  achievement->position = [ach position];
  

  if ([ach iconUrl]) {
    strncpy(
            achievement->iconUrl,
            [[ach iconUrl] UTF8String],
            sizeof(achievement->iconUrl)
            );
  }
  
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFachievementUnlock_platform(const char* achievementId)
{
  if (!achievementId) {
    return S3E_RESULT_ERROR;
  }
  
  NSString *strAchId = [[[NSString alloc] initWithUTF8String:achievementId] autorelease]; 
  OFAchievement *ach = [OFAchievement achievement:strAchId];
  if (ach) { 
    [ach unlock];
  }
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFachievementUnlockAndDefer_platform(const char* achievementId)
{
  if (!achievementId) {
    return S3E_RESULT_ERROR;
  }
  
  NSString *strAchId = [[[NSString alloc] initWithUTF8String:achievementId]  autorelease];
  OFAchievement *ach = [OFAchievement achievement:strAchId];
  if (ach) { 
      [ach unlockAndDefer];
  }
  return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFsubmitDeferredAchievements_platform()
{
  [OFAchievement submitDeferredAchievements];
  return S3E_RESULT_SUCCESS;
}


s3eResult s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke_platform(const char* deviceToken)
{
  if (deviceToken==NULL) {
    return S3E_RESULT_ERROR;
  }
  
    // TODO: Check if the line below releases the data or not
  NSData *data = [NSData dataWithBytes:deviceToken length:strlen(deviceToken)];

  [OpenFeint applicationDidRegisterForRemoteNotificationsWithDeviceToken:data];
  return S3E_RESULT_SUCCESS;
}
