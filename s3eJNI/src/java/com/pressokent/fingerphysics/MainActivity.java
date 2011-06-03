package com.pressokent.fingerphysics;

import java.util.HashMap;
import java.util.Map;

import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings.Secure;
import android.util.Log;
import android.widget.Toast;

import com.android.vending.licensing.AESObfuscator;
import com.android.vending.licensing.LicenseChecker;
import com.android.vending.licensing.LicenseCheckerCallback;
import com.android.vending.licensing.ServerManagedPolicy;
import com.ideaworks3d.airplay.AirplayActivity;
import com.openfeint.api.OpenFeint;
import com.openfeint.api.OpenFeintDelegate;
import com.openfeint.api.OpenFeintSettings;
import com.openfeint.api.resource.Achievement;
import com.openfeint.api.resource.CurrentUser;
import com.openfeint.api.resource.Leaderboard;
import com.openfeint.api.resource.Score;
import com.openfeint.api.resource.User;
import com.openfeint.api.ui.Dashboard;

public class MainActivity extends AirplayActivity 
{
	// static reference to the Activity
	private static MainActivity m_Activity;
	private Handler m_Handler;
    
	private static final byte[] SALT = 
	{
		-5, 88, 7, -60, -3, 78, 79, 114, 0, 51, -55, -66, 118, -31, -25, -122, -79, -52, 36, -118
	};
	
	private LicenseCheckerCallback mLicenseCheckerCallback;
	private ServerManagedPolicy mPolicy;
    private LicenseChecker mChecker;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) 
    {
		super.onCreate(savedInstanceState);
		m_Activity = this;
		m_Handler = new Handler();
    }
    
    @Override
    protected void onDestroy() 
    {
        super.onDestroy();
		if (mChecker != null)
			mChecker.onDestroy();
    }
    
    public native void userLoggedIn();
    public native void userLoggedOut();	
	public native void dashboardWillAppear();
    public native void dashboardDidAppear();
    public native void dashboardDidDisappear();
    
    public native void licenseResult(int result);
    
    public void initOpenFeint(final String name, final String key, final String secret, final String id)
    {
    	m_Handler.post(new Runnable() 
    	{
			@Override
			public void run() 
			{
				Map<String, Object> options = new HashMap<String, Object>();
		        options.put(OpenFeintSettings.SettingCloudStorageCompressionStrategy, OpenFeintSettings.CloudStorageCompressionStrategyDefault);
		        // options.put(OpenFeintSettings.RequestedOrientation, ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
		        OpenFeintSettings settings = new OpenFeintSettings(name, key, secret, id, options);
		        
		        Log.i("OpenFeint", "Start OpenFeint initialization..");
		        OpenFeint.initialize(MainActivity.this, settings, new CustomOpenFeintDelegate());  
			}
		});
    }
    
    public void openDashboard()
    {
    	Dashboard.open();
    }
    
    public void unlockAchievement(final String achievementId)
    {
    	new Achievement(achievementId).unlock(new Achievement.UnlockCB() 
		{
			@Override
			public void onSuccess(boolean newUnlock) 
			{
				Log.i("Achievement", "Achievement unlocked: " + achievementId);				
			}

			@Override
			public void onFailure(String exceptionMessage) 
			{
				Log.i("Achievement", "Failed to unlock achievement: " + achievementId);				
				Toast.makeText(MainActivity.this, "Error (" + exceptionMessage + ") unlocking achievement.", Toast.LENGTH_SHORT).show();				
			}			
		});
    }
    
    public void submitScore(final String leaderboardId, final long scoreValue)
    {
    	Leaderboard leaderboard = new Leaderboard(leaderboardId);    	
    	Score score = new Score(scoreValue);
    	score.submitTo(leaderboard, new Score.SubmitToCB() 
    	{
			@Override
			public void onSuccess(boolean newHighScore) 
			{
				Log.i("Leaderboard", "Score submitted. board:" + leaderboardId + " score:" + scoreValue);
			}
			
			@Override
			public void onFailure(String exceptionMessage) 
			{
				Log.i("Leaderboard", "Failed to submit score. board:" + leaderboardId + " score:" + scoreValue);				
				Toast.makeText(MainActivity.this, "Error (" + exceptionMessage + ") submitting highscore.", Toast.LENGTH_SHORT).show();
			}
		});
    }
    
    public void checkLicense(String base64key)
    {
        // Try to use more data here. ANDROID_ID is a single point of attack.
        String deviceId = Secure.getString(getContentResolver(), Secure.ANDROID_ID);

        // Library calls this when it's done.
        mLicenseCheckerCallback = new CustomLicenseCheckerCallback();
        // Construct the LicenseChecker with a policy.
        mPolicy = new ServerManagedPolicy(this, new AESObfuscator(SALT, getPackageName(), deviceId));
		mChecker = new LicenseChecker(this, mPolicy, base64key);
		mChecker.checkAccess(mLicenseCheckerCallback);
    }
    
    public long getActivationRemainingTime()
    {
    	if (mPolicy == null)
    		return 0;
    	
    	return mPolicy.getTrialTime();
    }
    
    private class CustomOpenFeintDelegate extends OpenFeintDelegate
	{
		/**
		 * This method is called when a user logs in.  This happens when:
		 * <ul>
		 * <li> A user creates an account from the intro flow
		 * <li> A user logs in with an existing account from the intro flow 
		 * <li> A user switches to a different user account from the Dashboard 
		 * <li> OpenFeint.initialize() validates a previously-logged in user automatically
		 * </ul>
		 * @param user The CurrentUser that just logged in.
		 */
		public void userLoggedIn(CurrentUser user) 
		{
			Log.i("OpenFeint", "User logged in");		
			MainActivity.this.userLoggedIn();
		}
		
		/**
		 * This method is called when a user logs out.  This happens when
		 * <ul>
		 * <li> A user logs out from the Dashboard
		 * <li> A user switches to a different user account from the Dashboard
		 * <ul>
		 * @param user The User that just logged out.
		 */
		public void userLoggedOut(User user) 
		{
			Log.i("OpenFeint", "User logged out");
			MainActivity.this.userLoggedOut();	
		}

		/**
		 * This method is called when the dashboard opens.
		 */
		public void onDashboardAppear() 
		{
			Log.i("OpenFeint", "On Dashboard appear");
			dashboardDidAppear();
		}

		/**
		 * This method is called when the dashboard closes.
		 */
		public void onDashboardDisappear() 
		{
			Log.i("OpenFeint", "On Dashboard dissapear");
			dashboardDidDisappear();
		}
	}    
    
    private class CustomLicenseCheckerCallback implements LicenseCheckerCallback 
    {    	
    	private static final int LICENSE_RESULT_ACTIVATION_ALLOWED = 0; // Application is licensed
    	private static final int LICENSE_RESULT_ACTIVATION_TRIAL_ALLOWED = 1; // User must activate application withing some period
    	private static final int LICENSE_RESULT_ACTIVATION_TRIAL_EXPIRED = 2; // Activation trial expired, user cannot access application
    	private static final int LICENSE_RESULT_OFFLINE_PERIOD_EXPRIES = 3; // Offline period expired, user must access network to check license
    	private static final int LICENSE_RESULT_BLOCKED = 4; // Application is pirated
    	private static final int LICENSE_RESULT_ERROR_INVALID_PACKAGE_NAME = 5;
    	private static final int LICENSE_RESULT_ERROR_NON_MATCHING_UID = 6;
    	private static final int LICENSE_RESULT_ERROR_NOT_MARKET_MANAGED = 7;
    	private static final int LICENSE_RESULT_ERROR_CHECK_IN_PROGRESS = 8;
    	private static final int LICENSE_RESULT_ERROR_INVALID_PUBLIC_KEY = 9;
    	private static final int LICENSE_RESULT_ERROR_MISSING_PERMISSION = 10;
    	private static final int LICENSE_RESULT_ERROR_UNKNOWN = 11; // Unknown error occured
    	
        public void allow() 
        {
            if (isFinishing()) 
            {
                // Don't update UI if Activity is finishing.
                return;
            }
            // Should allow user access.
			
            if (mPolicy.isTrialMode())
            {
            	Log.i("CustomLicenseChecker", "Trial mode expires in " + mPolicy.getTrialTime() + "ms");
            	licenseResult(LICENSE_RESULT_ACTIVATION_TRIAL_ALLOWED);
            }
            else
            {
            	Log.i("CustomLicenseChecker", "License allowed");
            	licenseResult(LICENSE_RESULT_ACTIVATION_ALLOWED);
            }
        }

        public void dontAllow() 
        {
            if (isFinishing()) 
            {
                // Don't update UI if Activity is finishing.
                return;
            }
            //displayResult(getString(R.string.dont_allow));
            // Should not allow access. In most cases, the app should assume
            // the user has access unless it encounters this. If it does,
            // the app should inform the user of their unlicensed ways
            // and then either shut down the app or limit the user to a
            // restricted set of features.
            
            if (mPolicy.isOfflineExpired())
            {
            	Log.i("CustomLicenseChecker", "Offline period expired");
            	licenseResult(LICENSE_RESULT_OFFLINE_PERIOD_EXPRIES);
            }
            else if (mPolicy.isTrialExpired())
            {
            	Log.i("CustomLicenseChecker", "Activation period expired");
            	licenseResult(LICENSE_RESULT_ACTIVATION_TRIAL_EXPIRED);
            }
            else
            {
            	Log.i("CustomLicenseChecker", "License don't allowed");
            	licenseResult(LICENSE_RESULT_BLOCKED);
            }
        }

        public void applicationError(ApplicationErrorCode errorCode) 
        {
            if (isFinishing()) 
            {
                // Don't update UI if Activity is finishing.
                return;
            }
            // This is a polite way of saying the developer made a mistake
            // while setting up or calling the license checker library.
            // Please examine the error code and fix the error.

            Log.i("CustomLicenseChecker", "Application error: " + errorCode);
			
            if (errorCode == ApplicationErrorCode.INVALID_PACKAGE_NAME)
            	licenseResult(LICENSE_RESULT_ERROR_INVALID_PACKAGE_NAME);
            else if (errorCode == ApplicationErrorCode.NON_MATCHING_UID)
            	licenseResult(LICENSE_RESULT_ERROR_NON_MATCHING_UID);
            else if (errorCode == ApplicationErrorCode.NOT_MARKET_MANAGED)
            	licenseResult(LICENSE_RESULT_ERROR_NOT_MARKET_MANAGED);
            else if (errorCode == ApplicationErrorCode.CHECK_IN_PROGRESS)
            	licenseResult(LICENSE_RESULT_ERROR_CHECK_IN_PROGRESS);
            else if (errorCode == ApplicationErrorCode.INVALID_PUBLIC_KEY)
            	licenseResult(LICENSE_RESULT_ERROR_INVALID_PUBLIC_KEY);
            else if (errorCode == ApplicationErrorCode.MISSING_PERMISSION)
            	licenseResult(LICENSE_RESULT_ERROR_MISSING_PERMISSION);
            else
            	licenseResult(LICENSE_RESULT_ERROR_UNKNOWN);
        }
    }
}