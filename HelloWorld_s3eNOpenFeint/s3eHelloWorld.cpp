/*
 * This file is part of the Marmalade SDK Code Samples.
 *
 * Copyright (C) 2001-2011 Ideaworks3D Ltd.
 * All Rights Reserved.
 *
 * This source code is intended only as a supplement to Ideaworks Labs
 * Development Tools and/or on-line documentation.
 *
 * THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 */

/**
 * @page ExampleS3EHelloWorld S3E Hello World Example
 *
 * The following example, in typical Hello World style, displays the phrase
 * "Hello, World!" on screen.
 *
 * The functions required to achieve this are:
 * Printing the text to screen:
 * <ul>
 *   <li>s3eDebugPrint()
 * </ul
 *
 * Handling the text:
 * <ul>
 *   <li>s3eDeviceCheckQuitRequest()
 *   <li>s3eSurfaceClear()
 *   <li>s3eSurfaceShow()
 * </ul>
 *
 * All examples will follow this basic pattern; a brief description of what
 * the example does will be given followed by a list of all the important
 * functions and, perhaps, classes.
 *
 * Should the example be more complex, a more detailed explanation of what the
 * example does and how it does it will be added. Note that most examples
 * use an example framework to remove boilerplate code and allow the projects
 * to be made up of a single source file for easy viewing. This framework can
 * be found in the examples/s3e/ExamplesMain directory.
 *
 * @include s3eHelloWorld.cpp
 */

#include "s3e.h"
#include "ExamplesMain.h"
#include "s3eNOpenFeint.h"
#include "s3eFacebook.h"

static Button* g_MessageBox;
static Button* g_NOFInitialize;
static Button* g_NOFShutdown;
static Button* g_NOFLaunchDashboard;
static Button* g_NOFTestButton1;
static Button* g_NOFTestButton2;


static char persistentChallengeId[50];
//static Button* g_NOFSetOrientation;

static s3eNOFChallengeDefinition *g_nofChallengeDefinitions = NULL;


/******** CALLBACKS ********/
static int32 playerLoggedIn(void *systemData, void *userData) 
{
	if(systemData)
	{
		s3eNOFPlayerInfo *info = (s3eNOFPlayerInfo*)systemData;
		AppendMessage("PlayerId received is %s", info->playerId);
	}
	
	return 0;
}

static int32 dashBoardAppeared(void *systemData, void *userData) 
{
	AppendMessage("Dashboard appeared");
	return 0;
}

static int32 didDownloadAllChallengeDefinitions(void *systemData, void *userData)
{
	if(!systemData)
	{
		AppendMessage("Downloaded all challenges with 0 items");
		return 0;
	}
		
	s3eNOFArray *defArray = (s3eNOFArray*)systemData;
	AppendMessage("AllChallengeDefinitions Downloaded with count %d" , defArray->m_count);
	for (uint i=0; i < defArray->m_count; i++) {
		AppendMessage("Challenge %s, appId %s, iconUrl %s, multiAttempt %d",
					  ((s3eNOFChallengeDefinition*)defArray->m_items)[i].title,
					  ((s3eNOFChallengeDefinition*)defArray->m_items)[i].clientApplicationId,
  					  ((s3eNOFChallengeDefinition*)defArray->m_items)[i].iconUrl,
					  ((s3eNOFChallengeDefinition*)defArray->m_items)[i].multiAttempt);
	}
	if (defArray->m_count>0) {
		g_nofChallengeDefinitions = (s3eNOFChallengeDefinition*)defArray->m_items; 
	}
	return 0;
}

static int32 didFailDownloadChallengeDefinitions(void *systemData, void *userData)
{
	AppendMessage("Failed to download AllChallengeDefinitions");
	return 0;
}


static int32 userLaunchedChallenge(void *systemData, void *userData)
{
	if (!systemData) {
		return -1;
	}
//	s3eNOFArray *array = (s3eNOFArray*)systemData;
	s3eNOFChallengeToUser *nofChalToUser = (s3eNOFChallengeToUser*)systemData;
	AppendMessage("Challenge %s from %s to %s with id %s", 
				  nofChalToUser->challenge->challengeDefinition->title,
				  nofChalToUser->challenge->challenger->name,
				  nofChalToUser->recipient->name,
				  nofChalToUser->nofPersistentId);
	strncpy(persistentChallengeId,nofChalToUser->nofPersistentId,sizeof(persistentChallengeId));
	return 0;
}

//static int32 RemotePushNotificationRecieved(void* systemData, void* userData)
//{
//  AppendMessageColour(BLUE, "PushNotification `xee6666'%s'", (char*)systemData);
//  return 0;
//}


static int32 isOpenFeintNotificationAllowed(void *systemData, void *userData) 
{
	AppendMessageColour(RED,"isOpenFeintNotificationAllowed called");
	return 0;
}

/******** CALLBACKS END *******/

void ExampleInit()
{
#define NUM_MESSAGES 30
#define MESSAGE_LEN 80

    InitMessages(NUM_MESSAGES, MESSAGE_LEN);
    AppendMessageColour(GREEN, "Checking for extension");
    
    SetButtonScale(GetButtonScale()-1);
    g_MessageBox = NewButton("MessageBox");
    if (s3eNOpenFeintAvailable())
	{
		g_NOFInitialize = NewButton("OF Initialize");
		g_NOFShutdown = NewButton("OF Shutdown");
		g_NOFLaunchDashboard = NewButton("OF LaunchDashboard");
		g_NOFTestButton1 = NewButton("OF Test 1");
		g_NOFTestButton2 = NewButton("OF Test 2");
		

		// Register for callbacks
		AppendMessageColour(BLUE, "*************");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");
		AppendMessage("");		
		AppendMessage("");
		AppendMessage("");
		AppendMessageColour(GREEN, "Registering for callback");
		
		s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_PLAYER_LOGGEDIN, &playerLoggedIn, NULL);
		s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_DASHBOARD_DID_APPEAR, &dashBoardAppeared, NULL);
		s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_DID_DOWNLOAD_ALL_CHALLENGE_DEFINITIONS,
							  &didDownloadAllChallengeDefinitions,
							  NULL);
		s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_DID_FAIL_DOWNLOAD_CHALLENGE_DEFINITIONS,
							  &didFailDownloadChallengeDefinitions,
							  NULL);
		s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_USER_LAUNCHED_CHALLENGE,
							  &userLaunchedChallenge,
							  NULL);
    
    s3eNOpenFeintRegister(S3E_NOPENFEINT_CALLBACK_IS_OPENFEINT_NOTIFICATION_ALLOWED,
                          &isOpenFeintNotificationAllowed,
                          NULL);
    
	}
    else
    {
        AppendMessageColour(RED,"Could not load s3eNOpenFeint extension");
      return;
    }
  
  if(s3eFacebookAvailable())
  {
    s3eFBInit("193667878484");
  }
  else
    AppendMessageColour(RED,"Could not load s3eFacebook extension");
//  if (!s3eIOSNotificationsAvailable())
//  {
//    AppendMessageColour(RED,"Extension Not Available");
//    return;
//  }
//  else {
//      // Register IOS Notification
//      //     s3eDeviceRegister(S3E_DEVICE_PUSH_NOTIFICATION, RemotePushNotificationRecieved, 0);
//           s3eIOSNotificationsRegister(S3E_IOSNOTIFICATIONS_REMOTE, RemotePushNotificationRecieved, NULL);
//
//      // s3eIOSNotificationsGetLaunchNotification();
//  }
//	g_is3eNGAvailable = NewButton("IsNGAvailable");
}

void ExampleTerm()
{
}

bool ExampleUpdate()
{
    Button* pressed = GetSelectedButton();
    if (pressed && pressed == g_MessageBox)
        s3eNewMessageBox("Title", "Hello world");
	else if (pressed && pressed == g_NOFInitialize)
	{
    
   		s3eNOFSettingVal *settings = (s3eNOFSettingVal*)s3eMalloc(sizeof(s3eNOFSettingVal) * 6);
		// Fill settings
		// UIOrientation value
		strncpy(settings[0].m_varName,
				"OpenFeintSettingDashboardOrientation",
					S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[0].m_intVal = s3eNOFUIInterfaceOrientationPortrait;
		
		
		// Shortdisplay name
		strncpy(settings[1].m_varName, 
				"OpenFeintSettingShortDisplayName", 
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		strncpy(settings[1].m_stringVal, 
				"FunkyRacers", 
				S3E_NOPENFEINT_STRING_MAX);
		
		// Push Notification Setting
		strncpy(settings[2].m_varName,
				"OpenFeintSettingEnablePushNotifications",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[2].m_intVal = 1; // TRUE/YES
		
		
		// Sandbox Notification Mode
		strncpy(settings[3].m_varName,
				"OpenFeintSettingUseSandboxPushNotificationServer",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[3].m_intVal = 1;
		

		// Disable User generated content
		strncpy(settings[4].m_varName,
				"OpenFeintSettingDisableUserGeneratedContent",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[4].m_intVal = 0;
		
		// Disable ask for approval in debug mode
		strncpy(settings[5].m_varName,
				"OpenFeintSettingAlwaysAskForApprovalInDebug",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[5].m_intVal = 0;
		
		
		
		s3eNOFArray array;
		array.m_count = 6;
		array.m_items = settings;
		s3eNOFinitializeWithProductKey("TD5741bq5dsEWStKk3rdMA",
									   "HgjtDJBBRW8sBfASq9Iv6hDAfchXAHMYJvNU5gQ0",
									   "RacingGame",
									   &array);
		s3eFree(settings);
		AppendMessageColour(GREEN, "Called s3eNOFinitializeWithProductKey");
		 //g_doRender1 = false;	
      // Lets try to give the API the token
//    const char* deviceToken = s3eIOSNotificationsGetRemoteNotificationToken();
//    char tmp[40];
//    const char *tmp1 = deviceToken;
//    memset(tmp,'\0', sizeof(tmp));
//    
//      // need to get rid of spaces in middle
//    int i =0;
//    while(*tmp1)
//    {
//      if(*tmp1!=' ') 
//      {
//          // not a space. we can copy
//        tmp[i] = *tmp1;
//        i++;
//      }
//      tmp1++;
//    }
//    
//    if (deviceToken) {
//      AppendMessageColour(BLUE,"Device token is %s",tmp);
//      s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke(tmp);
//    }

	}
	else if (pressed && pressed == g_NOFShutdown)
	{
		s3eNOFshutdown();
		AppendMessageColour(GREEN, "Called s3eNOFshutdown");
	}
	else if (pressed && pressed == g_NOFLaunchDashboard)
	{
      //	s3eNOFlaunchDashboard();
    s3eNOFlaunchDashboardWithListLeaderboardsPage();
		AppendMessageColour(GREEN, "Called s3eNOFlaunchDashboardWithListLeaderboardsPage");

	}
	else if (pressed && pressed == g_NOFTestButton1)
	{
    const unsigned int max_achievements = 20; // whatever we think is max we need
    void* data = s3eMalloc(sizeof(s3eNOFAchievement) * max_achievements);
    if (data == NULL) {
      AppendMessageColour(RED, ("Couldn't allocate data"));
      return false;
    }
    
    s3eNOFArray achArray;
    achArray.m_items = data;
    achArray.m_count = max_achievements;
    s3eNOFachievements(&achArray);
      //    AppendMessage("Size of achievement %d and double %d", 
      //          sizeof(s3eNOFAchievement),
      //          sizeof(double));
    for (uint i=0; i < achArray.m_count && i < max_achievements; i++) {
        //      s3eNOFAchievement* ach = &((s3eNOFAchievement*)achArray.m_items[i]);
        //      AppendMessage("Ach at %p", &((s3eNOFAchievement*)achArray.m_items)[i]);
      AppendMessage("Acheivement title %s", ((s3eNOFAchievement*)achArray.m_items)[i].title);
    }
    s3eFree(data);
	}
	else if (pressed && pressed == g_NOFTestButton2)
	{
		//s3eNOFdisplayAndSendChallenge(&g_nofChallengeDefinitions[1]);
/*		s3eNOFchallengeCompleteWithResult(kNOFChallengeResultRecipientLost, persistentChallengeId);
		
		AppendMessageColour(GREEN, "Called s3eNOFchallengeCompleteWithResult");
		s3eNOFChallengeData chalData;
		const char *dd = "SCORE=5"; 
		chalData.data = (void*)dd;
		chalData.length = strlen(dd);
		s3eNOFchallengeDisplayCompletionWithData(&chalData, 
													"Challenge Lost", 
												 persistentChallengeId);
		AppendMessageColour(GREEN, "Called s3eNOFchallengeDisplayCompletionWithData");
*/
    
    /*
    s3eNOFAchievement *ach = (s3eNOFAchievement*)s3eMalloc(sizeof(s3eNOFAchievement));
    AppendMessageColour(GREEN,"Calling s3eNOFachievement");
    s3eNOFachievement(ach, "1117662");
    AppendMessage("Achievement title %s", ach->title);
      //    AppendMessage("Achievement description %s", ach->description);
    s3eFree(ach);
  */
    
      //    s3eNOFachievementUnlock("1117662");

      
     
	}
    return true;
}

/*
 * The following function outputs the phrase "Hello World" to screen. It uses
 * The s3eDebugPrint() function to print the phrase.
 */
void ExampleRender()
{
    // Print Hello, World
//    s3eDebugPrint(50, 100, "`x666666Hello, World", 0);
	
	int y = GetYBelowButtons();
    int x = 10*GetButtonScale();
	
//    s3eDebugPrintf(x, y, 1, "`xee3333Local user: '%s'", g_UserName);
    y += 40;
	
    // Print messages from all peers, newest first
    PrintMessages(x, y);
	
}