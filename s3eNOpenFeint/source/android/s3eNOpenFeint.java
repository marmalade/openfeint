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

import com.openfeint.api.OpenFeint;
import com.openfeint.api.OpenFeintDelegate;
import com.openfeint.api.OpenFeintSettings;
import com.openfeint.api.resource.Achievement;
import com.openfeint.api.resource.CurrentUser;
import com.openfeint.api.resource.Leaderboard;
import com.openfeint.api.resource.Score;
import com.openfeint.api.resource.User;
import com.openfeint.api.ui.Dashboard;

class s3eNOpenFeint implements DialogInterface.OnClickListener
{
	static final String TAG = "MarmaladeMessage";
    private String m_MessageText;
    private String m_MessageTitle;
		
	static final String gameName = "FunkyRacing";
	static final String gameID = "330603";
	static final String gameKey = "TD5741bq5dsEWStKk3rdMA";
	static final String gameSecret = "HgjtDJBBRW8sBfASq9Iv6hDAfchXAHMYJvNU5gQ0";
	

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
	
    public int s3eNOFinitializeWithProductKey(String productKey, String secret, String displayName)
    {
		LoaderAPI.getActivity().LoaderThread().runOnOSThread(m_s3eNOFinitializeWithProductKey);
        return 0;
    }

	private final Runnable m_s3eNOFinitializeWithProductKey = new Runnable()
	{
		public void run()
		{
				OpenFeintSettings settings = new OpenFeintSettings(gameName, gameKey, gameSecret, gameID);
				OpenFeint.initialize(LoaderAPI.getActivity(), settings, new OpenFeintDelegate() {});
		}
	};

    public int s3eNOFlaunchDashboardWithHighscorePage(String leaderboardId)
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithAchievementsPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithChallengesPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithFindFriendsPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithWhosPlayingPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithListGlobalChatRoomsPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithiPurchasePage(String clientApplicationId)
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithSwitchUserPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithForumsPage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithInvitePage()
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithSpecificInvite(String inviteIdentifier)
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithSocialNotificationWithPrepopulatedText(String prepopulatedText, String originialMessage, String imageName, String linkedUrl)
    {
        return 0;
    }
    public int s3eNOFshutdown()
    {
		// Function is not needed for java implementation. Always returns 0
        return 0;
    }

    public int s3eNOFlaunchDashboard()
    {
        return 0;
    }
    public int s3eNOFdismissDashboard()
    {
        return 0;
    }
    public int s3eNOFsetDashboardOrientation()
    {
        return 0;
    }
    public void s3eNOFhasUserApprovedFeint()
    {
        
    }
    public void s3eNOFisOnline()
    {
        
    }
    public int s3eNOFdisplayAndSendChallenge(String challengeDescription)
    {
        return 0;
    }
    public int s3eNOFdownloadAllChallengeDefinitions()
    {
        return 0;
    }
    public int s3eNOFdownloadChallengeDefinitionWithId(String challengeDefinitionId)
    {
        return 0;
    }
    public int s3eNOFchallengeCompleteWithResult(String challengePeristentId)
    {
        return 0;
    }
    public int s3eNOFchallengeDisplayCompletionWithData(String reChallengeDescription, String challengePeristentId)
    {
        return 0;
    }
    public int s3eNOFsubmitHighScore(String leaderBoadId, String score, String displayText, String customData)
    {
        return 0;
    }
    public int s3eNOFupdateAcheivementProgressionComplete(String achievementId, String updatePercentComplete, boolean showUpdateNotification)
    {
        return 0;
    }
    public int s3eNOFachievements()
    {
        return 0;
    }
    public int s3eNOFachievement(String achievementId)
    {
        return 0;
    }
    public int s3eNOFachievementUnlock(String achievementId)
    {
        return 0;
    }
    public int s3eNOFachievementUnlockAndDefer(String achievementId)
    {
        return 0;
    }
    public int s3eNOFsubmitDeferredAchievements()
    {
        return 0;
    }
    public int s3eNOFapplicationDidRegisterForRemoteNotificationsWithDeviceToke(String deviceToken)
    {
        return 0;
    }
    public int s3eNOFlaunchDashboardWithListLeaderboardsPage()
    {
        return 0;
    }
}
