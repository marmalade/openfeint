/*
 * android-specific implementation of the s3eNOpenFeint extension.
 * Add any platform-specific functionality here.
 */
/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */
#include "s3eNOpenFeint_internal.h"

#include "s3eEdk.h"
#include "s3eEdk_android.h"
#include <jni.h>
#include "IwDebug.h"

static jobject g_Obj;
static jmethodID g_s3eNewMessageBox;
static jmethodID g_s3eNOFinitializeWithProductKey;
static jmethodID g_s3eNOFlaunchDashboardWithHighscorePage;
static jmethodID g_s3eNOFlaunchDashboardWithAchievementsPage;
static jmethodID g_s3eNOFlaunchDashboardWithChallengesPage;
static jmethodID g_s3eNOFlaunchDashboardWithFindFriendsPage;
static jmethodID g_s3eNOFlaunchDashboardWithWhosPlayingPage;
static jmethodID g_s3eNOFlaunchDashboardWithListGlobalChatRoomsPage;
static jmethodID g_s3eNOFlaunchDashboardWithiPurchasePage;
static jmethodID g_s3eNOFlaunchDashboardWithSwitchUserPage;
static jmethodID g_s3eNOFlaunchDashboardWithForumsPage;
static jmethodID g_s3eNOFlaunchDashboardWithInvitePage;
static jmethodID g_s3eNOFlaunchDashboardWithSpecificInvite;
static jmethodID g_s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText;
static jmethodID g_s3eNOFshutdown;
static jmethodID g_s3eNOFlaunchDashboard;
static jmethodID g_s3eNOFdismissDashboard;
static jmethodID g_s3eNOFsetDashboardOrientation;
static jmethodID g_s3eNOFhasUserApprovedFeint;
static jmethodID g_s3eNOFisOnline;
static jmethodID g_s3eNOFdisplayAndSendChallenge;
static jmethodID g_s3eNOFdownloadAllChallengeDefinitions;
static jmethodID g_s3eNOFdownloadChallengeDefinitionWithId;
static jmethodID g_s3eNOFchallengeCompleteWithResult;
static jmethodID g_s3eNOFchallengeDisplayCompletionWithData;
static jmethodID g_s3eNOFsubmitHighScore;
static jmethodID g_s3eNOFupdateAcheivementProgressionComplete;
static jmethodID g_s3eNOFachievements;
static jmethodID g_s3eNOFachievement;
static jmethodID g_s3eNOFachievementUnlock;
static jmethodID g_s3eNOFachievementUnlockAndDefer;
static jmethodID g_s3eNOFsubmitDeferredAchievements;
static jmethodID g_s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke;
static jmethodID g_s3eNOFlaunchDashboardWithListLeaderboardsPage;

s3eResult s3eNOpenFeintInit_platform()
{
    // Get the environment from the pointer
    JNIEnv* env = s3eEdkJNIGetEnv();
    jobject obj = NULL;
    jmethodID cons = NULL;

    // Get the extension class
    jclass cls = s3eEdkAndroidFindClass("s3eNOpenFeint");
    if (!cls)
        goto fail;

    // Get its constructor
    cons = env->GetMethodID(cls, "<init>", "()V");
    if (!cons)
        goto fail;

    // Construct the java class
    obj = env->NewObject(cls, cons);
    if (!obj)
        goto fail;

    // Get all the extension methods
    g_s3eNewMessageBox = env->GetMethodID(cls, "s3eNewMessageBox", "(Ljava/lang/String;Ljava/lang/String;)I");
    if (!g_s3eNewMessageBox)
        goto fail;

    g_s3eNOFinitializeWithProductKey = env->GetMethodID(cls, "s3eNOFinitializeWithProductKey", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I");
    if (!g_s3eNOFinitializeWithProductKey)
        goto fail;

    g_s3eNOFlaunchDashboardWithHighscorePage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithHighscorePage", "(Ljava/lang/String;)I");
    if (!g_s3eNOFlaunchDashboardWithHighscorePage)
        goto fail;

    g_s3eNOFlaunchDashboardWithAchievementsPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithAchievementsPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithAchievementsPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithChallengesPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithChallengesPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithChallengesPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithFindFriendsPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithFindFriendsPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithFindFriendsPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithWhosPlayingPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithWhosPlayingPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithWhosPlayingPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithListGlobalChatRoomsPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithListGlobalChatRoomsPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithListGlobalChatRoomsPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithiPurchasePage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithiPurchasePage", "(Ljava/lang/String;)I");
    if (!g_s3eNOFlaunchDashboardWithiPurchasePage)
        goto fail;

    g_s3eNOFlaunchDashboardWithSwitchUserPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithSwitchUserPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithSwitchUserPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithForumsPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithForumsPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithForumsPage)
        goto fail;

    g_s3eNOFlaunchDashboardWithInvitePage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithInvitePage", "()I");
    if (!g_s3eNOFlaunchDashboardWithInvitePage)
        goto fail;

    g_s3eNOFlaunchDashboardWithSpecificInvite = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithSpecificInvite", "(Ljava/lang/String;)I");
    if (!g_s3eNOFlaunchDashboardWithSpecificInvite)
        goto fail;

    g_s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I");
    if (!g_s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText)
        goto fail;

    g_s3eNOFshutdown = env->GetMethodID(cls, "s3eNOFshutdown", "()I");
    if (!g_s3eNOFshutdown)
        goto fail;

    g_s3eNOFlaunchDashboard = env->GetMethodID(cls, "s3eNOFlaunchDashboard", "()I");
    if (!g_s3eNOFlaunchDashboard)
        goto fail;

    g_s3eNOFdismissDashboard = env->GetMethodID(cls, "s3eNOFdismissDashboard", "()I");
    if (!g_s3eNOFdismissDashboard)
        goto fail;

    g_s3eNOFsetDashboardOrientation = env->GetMethodID(cls, "s3eNOFsetDashboardOrientation", "()I");
    if (!g_s3eNOFsetDashboardOrientation)
        goto fail;

    g_s3eNOFhasUserApprovedFeint = env->GetMethodID(cls, "s3eNOFhasUserApprovedFeint", "()Z");
    if (!g_s3eNOFhasUserApprovedFeint)
        goto fail;

    g_s3eNOFisOnline = env->GetMethodID(cls, "s3eNOFisOnline", "()Z");
    if (!g_s3eNOFisOnline)
        goto fail;

    g_s3eNOFdisplayAndSendChallenge = env->GetMethodID(cls, "s3eNOFdisplayAndSendChallenge", "(Ljava/lang/String;)I");
    if (!g_s3eNOFdisplayAndSendChallenge)
        goto fail;

    g_s3eNOFdownloadAllChallengeDefinitions = env->GetMethodID(cls, "s3eNOFdownloadAllChallengeDefinitions", "()I");
    if (!g_s3eNOFdownloadAllChallengeDefinitions)
        goto fail;

    g_s3eNOFdownloadChallengeDefinitionWithId = env->GetMethodID(cls, "s3eNOFdownloadChallengeDefinitionWithId", "(Ljava/lang/String;)I");
    if (!g_s3eNOFdownloadChallengeDefinitionWithId)
        goto fail;

    g_s3eNOFchallengeCompleteWithResult = env->GetMethodID(cls, "s3eNOFchallengeCompleteWithResult", "(Ljava/lang/String;)I");
    if (!g_s3eNOFchallengeCompleteWithResult)
        goto fail;

    g_s3eNOFchallengeDisplayCompletionWithData = env->GetMethodID(cls, "s3eNOFchallengeDisplayCompletionWithData", "(Ljava/lang/String;Ljava/lang/String;)I");
    if (!g_s3eNOFchallengeDisplayCompletionWithData)
        goto fail;

    g_s3eNOFsubmitHighScore = env->GetMethodID(cls, "s3eNOFsubmitHighScore", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I");
    if (!g_s3eNOFsubmitHighScore)
        goto fail;

    g_s3eNOFupdateAcheivementProgressionComplete = env->GetMethodID(cls, "s3eNOFupdateAcheivementProgressionComplete", "(Ljava/lang/String;Ljava/lang/String;Z)I");
    if (!g_s3eNOFupdateAcheivementProgressionComplete)
        goto fail;

    g_s3eNOFachievements = env->GetMethodID(cls, "s3eNOFachievements", "()I");
    if (!g_s3eNOFachievements)
        goto fail;

    g_s3eNOFachievement = env->GetMethodID(cls, "s3eNOFachievement", "(Ljava/lang/String;)I");
    if (!g_s3eNOFachievement)
        goto fail;

    g_s3eNOFachievementUnlock = env->GetMethodID(cls, "s3eNOFachievementUnlock", "(Ljava/lang/String;)I");
    if (!g_s3eNOFachievementUnlock)
        goto fail;

    g_s3eNOFachievementUnlockAndDefer = env->GetMethodID(cls, "s3eNOFachievementUnlockAndDefer", "(Ljava/lang/String;)I");
    if (!g_s3eNOFachievementUnlockAndDefer)
        goto fail;

    g_s3eNOFsubmitDeferredAchievements = env->GetMethodID(cls, "s3eNOFsubmitDeferredAchievements", "()I");
    if (!g_s3eNOFsubmitDeferredAchievements)
        goto fail;

    g_s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke = env->GetMethodID(cls, "s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke", "(Ljava/lang/String;)I");
    if (!g_s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke)
        goto fail;

    g_s3eNOFlaunchDashboardWithListLeaderboardsPage = env->GetMethodID(cls, "s3eNOFlaunchDashboardWithListLeaderboardsPage", "()I");
    if (!g_s3eNOFlaunchDashboardWithListLeaderboardsPage)
        goto fail;



    IwTrace(NOPENFEINT, ("NOPENFEINT init success"));
    g_Obj = env->NewGlobalRef(obj);
    env->DeleteLocalRef(obj);
    env->DeleteGlobalRef(cls);

    // Add any platform-specific initialisation code here
    return S3E_RESULT_SUCCESS;

fail:
    jthrowable exc = env->ExceptionOccurred();
    if (exc)
    {
        env->ExceptionDescribe();
        env->ExceptionClear();
        IwTrace(s3eNOpenFeint, ("One or more java methods could not be found"));
    }
    return S3E_RESULT_ERROR;

}

void s3eNOpenFeintTerminate_platform()
{
    // Add any platform-specific termination code here
}

s3eResult s3eNewMessageBox_platform(const char* title, const char* text)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring title_jstr = env->NewStringUTF(title);
    jstring text_jstr = env->NewStringUTF(text);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNewMessageBox, title_jstr, text_jstr);
}

s3eResult s3eNOFinitializeWithProductKey_platform(const char* productKey, const char* secret, const char* displayName, const s3eNOFArray* settings)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring productKey_jstr = env->NewStringUTF(productKey);
    jstring secret_jstr = env->NewStringUTF(secret);
    jstring displayName_jstr = env->NewStringUTF(displayName);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFinitializeWithProductKey, productKey_jstr, secret_jstr, displayName_jstr);
}

s3eResult s3eNOFlaunchDashboardWithHighscorePage_platform(const char* leaderboardId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring leaderboardId_jstr = env->NewStringUTF(leaderboardId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithHighscorePage, leaderboardId_jstr);
}

s3eResult s3eNOFlaunchDashboardWithAchievementsPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithAchievementsPage);
}

s3eResult s3eNOFlaunchDashboardWithChallengesPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithChallengesPage);
}

s3eResult s3eNOFlaunchDashboardWithFindFriendsPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithFindFriendsPage);
}

s3eResult s3eNOFlaunchDashboardWithWhosPlayingPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithWhosPlayingPage);
}

s3eResult s3eNOFlaunchDashboardWithListGlobalChatRoomsPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithListGlobalChatRoomsPage);
}

s3eResult s3eNOFlaunchDashboardWithiPurchasePage_platform(const char* clientApplicationId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring clientApplicationId_jstr = env->NewStringUTF(clientApplicationId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithiPurchasePage, clientApplicationId_jstr);
}

s3eResult s3eNOFlaunchDashboardWithSwitchUserPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithSwitchUserPage);
}

s3eResult s3eNOFlaunchDashboardWithForumsPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithForumsPage);
}

s3eResult s3eNOFlaunchDashboardWithInvitePage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithInvitePage);
}

s3eResult s3eNOFlaunchDashboardWithSpecificInvite_platform(const char* inviteIdentifier)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring inviteIdentifier_jstr = env->NewStringUTF(inviteIdentifier);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithSpecificInvite, inviteIdentifier_jstr);
}

s3eResult s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText_platform(const char* prepopulatedText, const char * originialMessage, const char* imageName, const char* linkedUrl)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring prepopulatedText_jstr = env->NewStringUTF(prepopulatedText);
    jstring originialMessage_jstr = env->NewStringUTF(originialMessage);
    jstring imageName_jstr = env->NewStringUTF(imageName);
    jstring linkedUrl_jstr = env->NewStringUTF(linkedUrl);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText, prepopulatedText_jstr, originialMessage_jstr, imageName_jstr, linkedUrl_jstr);
}

s3eResult s3eNOFshutdown_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFshutdown);
}

s3eResult s3eNOFlaunchDashboard_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboard);
}

s3eResult s3eNOFdismissDashboard_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFdismissDashboard);
}

s3eResult s3eNOFsetDashboardOrientation_platform(s3eNOFUIInterfaceOrientation orientation)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFsetDashboardOrientation);
}

ushort s3eNOFhasUserApprovedFeint_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    //    env->CallVoidMethod(g_Obj, g_s3eNOFhasUserApprovedFeint);
    return env->CallBooleanMethod(g_Obj, g_s3eNOFhasUserApprovedFeint);
    //return S3E_RESULT_SUCCESS;
}

ushort s3eNOFisOnline_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return env->CallBooleanMethod(g_Obj, g_s3eNOFisOnline);
    //    return S3E_RESULT_SUCCESS;
}

s3eResult s3eNOFdisplayAndSendChallenge_platform(s3eNOFChallengeDefinition* challengeDefinition, const char* challengeDescription, const s3eNOFChallengeData* challengeData)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring challengeDescription_jstr = env->NewStringUTF(challengeDescription);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFdisplayAndSendChallenge, challengeDescription_jstr);
}

s3eResult s3eNOFdownloadAllChallengeDefinitions_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFdownloadAllChallengeDefinitions);
}

s3eResult s3eNOFdownloadChallengeDefinitionWithId_platform(const char* challengeDefinitionId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring challengeDefinitionId_jstr = env->NewStringUTF(challengeDefinitionId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFdownloadChallengeDefinitionWithId, challengeDefinitionId_jstr);
}

s3eResult s3eNOFchallengeCompleteWithResult_platform(s3eNOFChallengeResult challengeResult, const char* challengePeristentId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring challengePeristentId_jstr = env->NewStringUTF(challengePeristentId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFchallengeCompleteWithResult, challengePeristentId_jstr);
}

s3eResult s3eNOFchallengeDisplayCompletionWithData_platform(s3eNOFChallengeData* challengeData, const char* reChallengeDescription, const char* challengePeristentId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring reChallengeDescription_jstr = env->NewStringUTF(reChallengeDescription);
    jstring challengePeristentId_jstr = env->NewStringUTF(challengePeristentId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFchallengeDisplayCompletionWithData, reChallengeDescription_jstr, challengePeristentId_jstr);
}

s3eResult s3eNOFsubmitHighScore_platform(const char* leaderBoadId, const char* score, const char* displayText, const char* customData)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring leaderBoadId_jstr = env->NewStringUTF(leaderBoadId);
    jstring score_jstr = env->NewStringUTF(score);
    jstring displayText_jstr = env->NewStringUTF(displayText);
    jstring customData_jstr = env->NewStringUTF(customData);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFsubmitHighScore, leaderBoadId_jstr, score_jstr, displayText_jstr, customData_jstr);
}

s3eResult s3eNOFupdateAcheivementProgressionComplete_platform(const char* achievementId, const char* updatePercentComplete, bool showUpdateNotification)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring achievementId_jstr = env->NewStringUTF(achievementId);
    jstring updatePercentComplete_jstr = env->NewStringUTF(updatePercentComplete);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFupdateAcheivementProgressionComplete, achievementId_jstr, updatePercentComplete_jstr, showUpdateNotification);
}

s3eResult s3eNOFachievements_platform(s3eNOFArray* achArray)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFachievements);
}

s3eResult s3eNOFachievement_platform(s3eNOFAchievement* achievement, const char* achievementId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring achievementId_jstr = env->NewStringUTF(achievementId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFachievement, achievementId_jstr);
}

s3eResult s3eNOFachievementUnlock_platform(const char* achievementId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring achievementId_jstr = env->NewStringUTF(achievementId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFachievementUnlock, achievementId_jstr);
}

s3eResult s3eNOFachievementUnlockAndDefer_platform(const char* achievementId)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring achievementId_jstr = env->NewStringUTF(achievementId);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFachievementUnlockAndDefer, achievementId_jstr);
}

s3eResult s3eNOFsubmitDeferredAchievements_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFsubmitDeferredAchievements);
}

s3eResult s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke_platform(const char* deviceToken)
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    jstring deviceToken_jstr = env->NewStringUTF(deviceToken);
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke, deviceToken_jstr);
}

s3eResult s3eNOFlaunchDashboardWithListLeaderboardsPage_platform()
{
    JNIEnv* env = s3eEdkJNIGetEnv();
    return (s3eResult)env->CallIntMethod(g_Obj, g_s3eNOFlaunchDashboardWithListLeaderboardsPage);
}
