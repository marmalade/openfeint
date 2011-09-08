/*
Generic implementation of the s3eNOpenFeint extension.
This file should perform any platform-indepedentent functionality
(e.g. error checking) before calling platform-dependent implementations.
*/

/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */


#include "s3eNOpenFeint_internal.h"
s3eResult s3eNOpenFeintInit()
{
    //Add any generic initialisation code here
    return s3eNOpenFeintInit_platform();
}

void s3eNOpenFeintTerminate()
{
    //Add any generic termination code here
    s3eNOpenFeintTerminate_platform();
}

s3eResult s3eNewMessageBox(const char* title, const char* text)
{
	return s3eNewMessageBox_platform(title, text);
}

s3eResult s3eNOFinitializeWithProductKey(const char* productKey, const char* secret, const char* displayName, const s3eNOFArray* settings)
{
	return s3eNOFinitializeWithProductKey_platform(productKey, secret, displayName, settings);
}

s3eResult s3eNOFlaunchDashboardWithHighscorePage(const char* leaderboardId)
{
	return s3eNOFlaunchDashboardWithHighscorePage_platform(leaderboardId);
}

s3eResult s3eNOFlaunchDashboardWithAchievementsPage()
{
	return s3eNOFlaunchDashboardWithAchievementsPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithChallengesPage()
{
	return s3eNOFlaunchDashboardWithChallengesPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithFindFriendsPage()
{
	return s3eNOFlaunchDashboardWithFindFriendsPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithWhosPlayingPage()
{
	return s3eNOFlaunchDashboardWithWhosPlayingPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithListGlobalChatRoomsPage()
{
	return s3eNOFlaunchDashboardWithListGlobalChatRoomsPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithiPurchasePage(const char* clientApplicationId)
{
	return s3eNOFlaunchDashboardWithiPurchasePage_platform(clientApplicationId);
}

s3eResult s3eNOFlaunchDashboardWithSwitchUserPage()
{
	return s3eNOFlaunchDashboardWithSwitchUserPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithForumsPage()
{
	return s3eNOFlaunchDashboardWithForumsPage_platform();
}

s3eResult s3eNOFlaunchDashboardWithInvitePage()
{
	return s3eNOFlaunchDashboardWithInvitePage_platform();
}

s3eResult s3eNOFlaunchDashboardWithSpecificInvite(const char* inviteIdentifier)
{
	return s3eNOFlaunchDashboardWithSpecificInvite_platform(inviteIdentifier);
}

s3eResult s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText(const char* prepopulatedText, const char * originialMessage, const char* imageName, const char* linkedUrl)
{
	return s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText_platform(prepopulatedText, originialMessage, imageName, linkedUrl);
}

s3eResult s3eNOFshutdown()
{
	return s3eNOFshutdown_platform();
}

s3eResult s3eNOFlaunchDashboard()
{
	return s3eNOFlaunchDashboard_platform();
}

s3eResult s3eNOFdismissDashboard()
{
	return s3eNOFdismissDashboard_platform();
}

s3eResult s3eNOFsetDashboardOrientation(s3eNOFUIInterfaceOrientation orientation)
{
	return s3eNOFsetDashboardOrientation_platform(orientation);
}

ushort s3eNOFhasUserApprovedFeint()
{
	return s3eNOFhasUserApprovedFeint_platform();
}

ushort s3eNOFisOnline()
{
	return s3eNOFisOnline_platform();
}

s3eResult s3eNOFdisplayAndSendChallenge(s3eNOFChallengeDefinition* challengeDefinition, const char* challengeDescription, const s3eNOFChallengeData* challengeData)
{
	return s3eNOFdisplayAndSendChallenge_platform(challengeDefinition, challengeDescription, challengeData);
}

s3eResult s3eNOFdownloadAllChallengeDefinitions()
{
	return s3eNOFdownloadAllChallengeDefinitions_platform();
}

s3eResult s3eNOFdownloadChallengeDefinitionWithId(const char* challengeDefinitionId)
{
	return s3eNOFdownloadChallengeDefinitionWithId_platform(challengeDefinitionId);
}

s3eResult s3eNOFchallengeCompleteWithResult(s3eNOFChallengeResult challengeResult, const char* challengePeristentId)
{
	return s3eNOFchallengeCompleteWithResult_platform(challengeResult, challengePeristentId);
}

s3eResult s3eNOFchallengeDisplayCompletionWithData(s3eNOFChallengeData* challengeData, const char* reChallengeDescription, const char* challengePeristentId)
{
	return s3eNOFchallengeDisplayCompletionWithData_platform(challengeData, reChallengeDescription, challengePeristentId);
}

s3eResult s3eNOFsubmitHighScore(const char* leaderBoadId, const char* score, const char* displayText, const char* customData)
{
	return s3eNOFsubmitHighScore_platform(leaderBoadId, score, displayText, customData);
}

s3eResult s3eNOFupdateAcheivementProgressionComplete(const char* achievementId, double updatePercentComplete, bool showUpdateNotification)
{
	return s3eNOFupdateAcheivementProgressionComplete_platform(achievementId, updatePercentComplete, showUpdateNotification);
}

s3eResult s3eNOFachievements(s3eNOFArray* achArray)
{
	return s3eNOFachievements_platform(achArray);
}

s3eResult s3eNOFachievement(s3eNOFAchievement* achievement, const char* achievementId)
{
	return s3eNOFachievement_platform(achievement, achievementId);
}

s3eResult s3eNOFachievementUnlock(const char* achievementId)
{
	return s3eNOFachievementUnlock_platform(achievementId);
}

s3eResult s3eNOFachievementUnlockAndDefer(const char* achievementId)
{
	return s3eNOFachievementUnlockAndDefer_platform(achievementId);
}

s3eResult s3eNOFsubmitDeferredAchievements()
{
	return s3eNOFsubmitDeferredAchievements_platform();
}

s3eResult s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke(const char* deviceToken)
{
	return s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke_platform(deviceToken);
}
