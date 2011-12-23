/*
 * Internal header for the s3eNOpenFeint extension.
 *
 * This file should be used for any common function definitions etc that need to
 * be shared between the platform-dependent and platform-indepdendent parts of
 * this extension.
 */

/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */


#ifndef S3ENOPENFEINT_INTERNAL_H
#define S3ENOPENFEINT_INTERNAL_H

#include "s3eTypes.h"
#include "s3eNOpenFeint.h"
#include "s3eNOpenFeint_autodefs.h"


/**
 * Initialise the extension.  This is called once then the extension is first
 * accessed by s3eregister.  If this function returns S3E_RESULT_ERROR the
 * extension will be reported as not-existing on the device.
 */
s3eResult s3eNOpenFeintInit();

/**
 * Platform-specific initialisation, implemented on each platform
 */
s3eResult s3eNOpenFeintInit_platform();

/**
 * Terminate the extension.  This is called once on shutdown, but only if the
 * extension was loader and Init() was successful.
 */
void s3eNOpenFeintTerminate();

/**
 * Platform-specific termination, implemented on each platform
 */
void s3eNOpenFeintTerminate_platform();
s3eResult s3eNewMessageBox_platform(const char* title, const char* text);

s3eResult s3eNOFinitializeWithProductKey_platform(const char* productKey, const char* secret, const char* displayName, const s3eNOFArray* settings);

s3eResult s3eNOFlaunchDashboardWithHighscorePage_platform(const char* leaderboardId);

s3eResult s3eNOFlaunchDashboardWithAchievementsPage_platform();

s3eResult s3eNOFlaunchDashboardWithChallengesPage_platform();

s3eResult s3eNOFlaunchDashboardWithFindFriendsPage_platform();

s3eResult s3eNOFlaunchDashboardWithWhosPlayingPage_platform();

s3eResult s3eNOFlaunchDashboardWithListGlobalChatRoomsPage_platform();

s3eResult s3eNOFlaunchDashboardWithiPurchasePage_platform(const char* clientApplicationId);

s3eResult s3eNOFlaunchDashboardWithSwitchUserPage_platform();

s3eResult s3eNOFlaunchDashboardWithForumsPage_platform();

s3eResult s3eNOFlaunchDashboardWithInvitePage_platform();

s3eResult s3eNOFlaunchDashboardWithSpecificInvite_platform(const char* inviteIdentifier);

s3eResult s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText_platform(const char* prepopulatedText, const char * originialMessage, const char* imageName, const char* linkedUrl);

s3eResult s3eNOFshutdown_platform();

s3eResult s3eNOFlaunchDashboard_platform();

s3eResult s3eNOFdismissDashboard_platform();

s3eResult s3eNOFsetDashboardOrientation_platform(s3eNOFUIInterfaceOrientation orientation);

ushort s3eNOFhasUserApprovedFeint_platform();

ushort s3eNOFisOnline_platform();

s3eResult s3eNOFdisplayAndSendChallenge_platform(s3eNOFChallengeDefinition* challengeDefinition, const char* challengeDescription, const s3eNOFChallengeData* challengeData);

s3eResult s3eNOFdownloadAllChallengeDefinitions_platform();

s3eResult s3eNOFdownloadChallengeDefinitionWithId_platform(const char* challengeDefinitionId);

s3eResult s3eNOFchallengeCompleteWithResult_platform(s3eNOFChallengeResult challengeResult, const char* challengePeristentId);

s3eResult s3eNOFchallengeDisplayCompletionWithData_platform(s3eNOFChallengeData* challengeData, const char* reChallengeDescription, const char* challengePeristentId);

s3eResult s3eNOFsubmitHighScore_platform(const char* leaderBoadId, const char* score, const char* displayText, const char* customData);

s3eResult s3eNOFupdateAcheivementProgressionComplete_platform(const char* achievementId, const char* updatePercentComplete, bool showUpdateNotification);

s3eResult s3eNOFachievements_platform(s3eNOFArray* achArray);

s3eResult s3eNOFachievement_platform(s3eNOFAchievement* achievement, const char* achievementId);

s3eResult s3eNOFachievementUnlock_platform(const char* achievementId);

s3eResult s3eNOFachievementUnlockAndDefer_platform(const char* achievementId);

s3eResult s3eNOFsubmitDeferredAchievements_platform();

s3eResult s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke_platform(const char* deviceToken);

s3eResult s3eNOFlaunchDashboardWithListLeaderboardsPage_platform();


#endif /* !S3ENOPENFEINT_INTERNAL_H */