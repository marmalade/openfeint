/*
java implementation of the s3eNOpenFeint extension.

Add android-specific functionality here.

These functions are called via JNI from native code.
*/
/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */
import com.ideaworks3d.marmalade.LoaderAPI;
import com.ideaworks3d.marmalade.LoaderActivity;

import android.content.DialogInterface;
import android.app.AlertDialog;
import android.app.Dialog;
import android.os.Handler;

import com.openfeint.api.OpenFeint;
import com.openfeint.api.OpenFeintDelegate;
import com.openfeint.api.OpenFeintSettings;
import com.openfeint.api.resource.Achievement;
import com.openfeint.api.resource.CurrentUser;
import com.openfeint.api.resource.Leaderboard;
import com.openfeint.api.resource.Score;
import com.openfeint.api.resource.User;
import com.openfeint.api.resource.CurrentUser;
import com.openfeint.api.ui.Dashboard;

class s3eNOpenFeint implements DialogInterface.OnClickListener
{
	static final String TAG = "MarmaladeMessage";
    private String m_MessageText;
    private String m_MessageTitle;
	private Handler m_Handler = null;
		
	static String gameName = "FunkyRacing";
	static String gameID = "123456"; // dummy ID that is never overwritten
	static String gameKey = "123456"; // dummy key overwritten by real call.
	static String gameSecret = "123456"; // dummy secret overwritten by real func call
	

    public int s3eNewMessageBox(String title, String text)
    {
		m_MessageText = text;
        m_MessageTitle = title;

        //We are currently in the Application thread,
        //enqueue the call to showMessage on the UI thread
        LoaderActivity.m_Activity.runOnUiThread(m_ShowMessage);
		
        return 0;
    }

    private final Runnable m_ShowMessage = new Runnable()
    {
        public void run()
        {
            showMessageReal();
        }
    };

    private void showMessageReal()
    {
        AlertDialog.Builder builder = new
        AlertDialog.Builder(LoaderActivity.m_Activity);
        builder.setTitle(m_MessageTitle);
        builder.setMessage(m_MessageText);
        builder.setPositiveButton("OK", this);
        Dialog dialog = builder.create();
        dialog.show();
    }

    public void onClick(DialogInterface dialog, int button)
    {
        dialog.dismiss();
    }
	

    public int s3eNOFinitializeWithProductKey(String productKey, String secret, String displayName, String productID)
    {
	    	gameName = displayName;
		gameKey = productKey;
		gameSecret = secret;
		gameID = productID;
		LoaderAPI.getActivity().LoaderThread().runOnOSThread(m_s3eNOFinitializeWithProductKey);
//		LoaderActivity.m_Activity.runOnUiThread(m_s3eNOFinitializeWithProductKey);

/*		if(m_Handler==null)
				m_Handler = new Handler();
		m_Handler.post(m_s3eNOFinitializeWithProductKey);*/
        return 0;
    }

	private final Runnable m_s3eNOFinitializeWithProductKey = new Runnable()
	{
		public void run()
		{
				OpenFeintSettings settings = new OpenFeintSettings(gameName, gameKey, gameSecret, gameID);
				OpenFeint.initialize(LoaderAPI.getActivity(), settings, new OpenFeintDelegate() {
					 // **** OpenFeintDelegate functions
					    public void userLoggedIn(CurrentUser user)
					    {
						    NOFLoginCallback(user.userID(),true);

					    }

					    public void userLoggedOut(User user)
					    {
						    NOFLoginCallback(user.userID(),false);
					    }
					
					});
		}
	};

    public int s3eNOFlaunchDashboardWithHighscorePage(String leaderboardId)
    {
	Dashboard.openLeaderboard(leaderboardId);
        return 0; 
    }
    public int s3eNOFlaunchDashboardWithAchievementsPage()
    {
	Dashboard.openAchievements();
        return 0;
    }
    public int s3eNOFlaunchDashboardWithChallengesPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithFindFriendsPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithWhosPlayingPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithListGlobalChatRoomsPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithiPurchasePage(String clientApplicationId)
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithSwitchUserPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithForumsPage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithInvitePage()
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithSpecificInvite(String inviteIdentifier)
    {
        return -1; // not supported
    }
    public int s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText(String prepopulatedText, String originialMessage, String imageName, String linkedUrl)
    {
        return -1; // not supported
    }
    public int s3eNOFshutdown()
    {
		// Function is not needed for java implementation. Always returns 0
        return 0;
    }

    public int s3eNOFlaunchDashboard()
    {
		LoaderActivity.m_Activity.runOnUiThread(new Runnable()
			{
				public void run()
				{
						Dashboard.open();
				}
			});
        return 0;
    }
    public int s3eNOFdismissDashboard()
    {
        return -1; // not supported
    }
    public int s3eNOFsetDashboardOrientation()
    {
        return -1; // not supported
    }
    public boolean s3eNOFhasUserApprovedFeint()
    {
       return OpenFeint.isUserLoggedIn(); 
    }
    public boolean s3eNOFisOnline()
    {
	return OpenFeint.isUserLoggedIn(); 
    }
    public int s3eNOFdisplayAndSendChallenge(String challengeDescription)
    {
        return -1; // not supported by OpenFeint on Android
    }
    public int s3eNOFdownloadAllChallengeDefinitions()
    {
        return -1; // not supported by OpenFeint on Android
    }
    public int s3eNOFdownloadChallengeDefinitionWithId(String challengeDefinitionId)
    {
        return -1; // not supported by OpenFeint on Android
    }
    public int s3eNOFchallengeCompleteWithResult(String challengePeristentId)
    {
        return -1; // not supported by OpenFeint on Android
    }
    public int s3eNOFchallengeDisplayCompletionWithData(String reChallengeDescription, String challengePeristentId)
    {
        return -1; // not supported by OpenFeint on Android
    }
    public int s3eNOFsubmitHighScore(String leaderBoadId, String score, String displayText, String customData)
    {
	Leaderboard lbd = new Leaderboard(leaderBoadId);
	long lScore = Long.parseLong(score);
	Score nofScore = new Score(lScore, displayText);
	nofScore.customData = customData;

	nofScore.submitTo(lbd, new Score.SubmitToCB () 
		{
			public void onSuccess (boolean newHighScore)
			{
				// do nothing
			}
		});
        return 0;
    }
    public int s3eNOFupdateAcheivementProgressionComplete(String achievementId, String updatePercentComplete, boolean showUpdateNotification)
    {
	Achievement ach = new Achievement(achievementId);
	float fPercent = Float.parseFloat(updatePercentComplete);
	ach.updateProgression(fPercent, new Achievement.UpdateProgressionCB()
		{	
			public void onSuccess (boolean complete)
			{
				// do nothing
			}
		});
        return 0;
    }
    public int s3eNOFachievements()
    {
        return -1;
    }
    public int s3eNOFachievement(String achievementId)
    {
        return -1;
    }
    public int s3eNOFachievementUnlock(String achievementId)
    {
	Achievement ach = new Achievement(achievementId);
	ach.unlock(new Achievement.UnlockCB() 
		{
			public void onSuccess(boolean newUnlock)
			{
				// do nothing
			}
		});
        return 0;
    }
    public int s3eNOFachievementUnlockAndDefer(String achievementId)
    {
        return -1;
    }
    public int s3eNOFsubmitDeferredAchievements()
    {
        return -1;
    }
    public int s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke(String deviceToken)
    {
        return -1;
    }
    public int s3eNOFlaunchDashboardWithListLeaderboardsPage()
    {
	Dashboard.openLeaderboards();
        return 0;
    }

       // *** Native Callbacks
    public native void NOFLoginCallback(String userId, boolean result);
}

/* vi: set ts=4 sw=4 background=dark*/
