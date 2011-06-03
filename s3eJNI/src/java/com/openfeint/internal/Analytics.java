package com.openfeint.internal;

import java.util.Date;

import android.content.Context;
import android.content.SharedPreferences;

import com.openfeint.internal.OpenFeintInternal;

public class Analytics {
	int numGameSessions;
	long gameSessionMilliseconds;
	int numDashboardLaunches;
	long dashboardMilliseconds;
	int numOnlineGameSessions;
	
	Date dashboardStart;
	Date sessionStart;

	/*
	 * The fields are persistently stored and incremented at the appropriate points in time
	 */

	public Analytics() {
		SharedPreferences prefs = OpenFeintInternal.getInstance().getContext().getSharedPreferences("FeintAnalytics", Context.MODE_PRIVATE);
		prefs.getInt("dashboardLaunches", numDashboardLaunches);
		prefs.getInt("sessionLaunches", numGameSessions);
		prefs.getInt("onlineSessions", numOnlineGameSessions);
		prefs.getLong("sessionMilliseconds", gameSessionMilliseconds);
		prefs.getLong("dashboardMilliseconds", dashboardMilliseconds);
	}
	
	public void markDashboardOpen() {
		++numDashboardLaunches;
		dashboardStart = new Date();
		update();
	}
	
	public void markDashboardClose() {
		if(dashboardStart != null) {
			dashboardMilliseconds += new Date().getTime() - dashboardStart.getTime();
			dashboardStart = null;
			update();
		}
		else {
			OpenFeintInternal.log("Analytics", "Dashboard closed without known starting time");
		}
	}
	
	public void markSessionOpen(boolean online) {
		++numGameSessions;
		if(online) ++numOnlineGameSessions;
		sessionStart = new Date();
		update();
	}
	
	public void markSessionClose() {
		if (sessionStart != null) {
			gameSessionMilliseconds += new Date().getTime() - sessionStart.getTime();
			sessionStart = null;
			update();
		}
		else {
			OpenFeintInternal.log("Analytics", "Session closed without known starting time");			
		}
	}
	
	private void update() {
		SharedPreferences.Editor prefs = OpenFeintInternal.getInstance().getContext().getSharedPreferences("FeintAnalytics", Context.MODE_PRIVATE).edit();
		prefs.putInt("dashboardLaunches", numDashboardLaunches);
		prefs.putInt("sessionLaunches", numGameSessions);
		prefs.putInt("onlineSessions", numOnlineGameSessions);
		prefs.putLong("sessionMilliseconds", gameSessionMilliseconds);
		prefs.putLong("dashboardMilliseconds", dashboardMilliseconds);
		prefs.commit();
	}
	
}
