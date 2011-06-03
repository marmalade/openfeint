package com.openfeint.api;

import android.app.Activity;
import android.content.Context;

import com.openfeint.api.resource.CurrentUser;
import com.openfeint.internal.OpenFeintInternal;

/**
 * Shared entry point for initializing OpenFeint and getting access to its current state.
 * 
 * @author Aurora Feint, Inc.
 */
public class OpenFeint {

	/**
	 * Get the currently logged-in user.  Returns null if no user has logged in,
	 * or if they've logged out.
	 * 
	 * @return The currently logged-in user.
	 */
	static public CurrentUser getCurrentUser() { return OpenFeintInternal.getInstance().getCurrentUser(); }

	/**
	 * Get whether a user is currently logged in or not.
	 * @return whether a user is currently logged in or not.
	 */
	static public boolean isUserLoggedIn() { return OpenFeintInternal.getInstance().isUserLoggedIn(); }

	/**
	 * Initialize OpenFeint.  This will allocate OpenFeint internal structures the
	 * first time it's called, and start the login process for the local user.  This
	 * must be called before any other OpenFeint methods can be called (or see initializeWithoutLoggingIn).
	 * @param ctx Application Context.
	 * @param settings An instance of OpenFeintSettings providing OpenFeint with information about your application.
	 * @param delegate An instance derived from OpenFeintDelegate, for future event notifications.  null is ok.
	 */
	static public void initialize(Context ctx, OpenFeintSettings settings, OpenFeintDelegate delegate) {
		OpenFeintInternal.initialize(ctx, settings, delegate);
	}
	
	/**
	 * Initialize OpenFeint.  This will allocate OpenFeint internal structures the
	 * first time it's called, but won't start the login process for the local user.  Note
	 * that you <em>must</em> call login(currentActivity) before any requests that require
	 * login may be used.
	 * @param ctx Application Context.
	 * @param settings An instance of OpenFeintSettings providing OpenFeint with information about your application.
	 * @param delegate An instance derived from OpenFeintDelegate, for future event notifications.  null is ok.
	 */
	static public void initializeWithoutLoggingIn(Context ctx, OpenFeintSettings settings, OpenFeintDelegate delegate) {
		OpenFeintInternal.initializeWithoutLoggingIn(ctx, settings, delegate);
	}
	
	/**
	 * Update the OpenFeint delegate.  This will notify OpenFeint that further events should be
	 * forwarded to the new delegate.  Calling this with null will clear any existing delegate - be sure
	 * to do this if your delegate closes over an Activity when you leave that Activity, so that
	 * it can be garbage-collected.
	 * 
	 * An example of when you would want to use this is if you only care about login events in your
	 * main menu Activity - then you would call {#link initializeWithoutLoggingIn} from your Application,
	 * then call {@link setDelegate} in your main menu Activity's onCreate method, before finally
	 * calling {@link login}.
	 * @param delegate An instance derived from OpenFeintDelegate, for future event notifications.  null is ok.
	 */
	static public void setDelegate(OpenFeintDelegate delegate) {
		OpenFeintInternal.getInstance().setDelegate(delegate);
	}

	/**
	 * Login to OpenFeint.  This should only be called after {@link #initializeWithoutLoggingIn(Activity, OpenFeintSettings, OpenFeintDelegate) initializeWithoutLoggingIn}, and
	 * should only be called once.
	 */
	static public void login() {
		OpenFeintInternal.getInstance().login();
	}
	
	/**
	 * Determine if the device can connect to the Internet.  If this is false, OpenFeint will not
	 * be able to use its online functionality.
	 */
	static public boolean isNetworkConnected() {
		return OpenFeintInternal.getInstance().isFeintServerReachable();
	}
	
	/**
	 * If you have a custom intro flow, call this method if the user approves Feint.
	 * Call {@link #userDeclinedFeint()} if they decline it.
	 */
	static public void userApprovedFeint() {
		OpenFeintInternal.getInstance().userApprovedFeint();
	}
	
	/**
	 * If you have a custom intro flow, call this method if the user declines Feint.
	 * Call {@link #userApprovedFeint()} if they approve it.
	 */
	static public void userDeclinedFeint() {
		OpenFeintInternal.getInstance().userDeclinedFeint();
	}
	
	/**
	 * Call this method to log out the local user.
	 */
	static public void logoutUser() {
		OpenFeintInternal.getInstance().logoutUser(null);
	}
}
