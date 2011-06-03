package com.openfeint.api.resource;

import java.util.Date;
import java.util.List;

import android.graphics.Bitmap;

import com.openfeint.api.R;
import com.openfeint.internal.APICallback;
import com.openfeint.internal.AchievementUnlockCache;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.notifications.AchievementNotification;
import com.openfeint.internal.request.BitmapRequest;
import com.openfeint.internal.request.JSONRequest;
import com.openfeint.internal.request.OrderedArgList;
import com.openfeint.internal.resource.BooleanResourceProperty;
import com.openfeint.internal.resource.DateResourceProperty;
import com.openfeint.internal.resource.FloatResourceProperty;
import com.openfeint.internal.resource.IntResourceProperty;
import com.openfeint.internal.resource.Resource;
import com.openfeint.internal.resource.ResourceClass;
import com.openfeint.internal.resource.StringResourceProperty;

/**
 * The resource class that represents an Achievement in OpenFeint.
 * You use this class to get a list of Achievements that your
 * application contains, to query whether the local user has unlocked
 * them, or to unlock them for the local user.
 * 
 * @author Aurora Feint, Inc.
 */
public class Achievement extends Resource {
	
	/**
	 * Create an Achievement object with the given resource id.  This won't automatically
	 * fill the other fields out - see Achievement.list() if you want to consult other
	 * fields of the Achievement.
	 * 
	 * @param resourceID the resource ID of the Achievement.
	 */
	public Achievement(String resourceID) { setResourceID(resourceID); }

	/**
	 * The user-visible title of the Achievement.
	 */
	public String title;
	
	/**
	 * The user-visible description of the Achievement.
	 */
	public String description;
	/**
	 * How many Feint Points this Achievement awards.
	 */
	public int gamerscore; // unsigned
	/**
	 * The URL of the Achievement icon.
	 */
	public String iconUrl;
	/**
	 * Whether this Achievement is secret or not.
	 */
	public boolean isSecret;
	/**
	 * Whether or not this Achievement has been unlocked by the local user.
	 */
	public boolean isUnlocked;
	/**
	 * The incremental percentage of completion by the local user.  The range is 0.0 to 100.0.
	 */
	public float percentComplete;
	/**
	 * If this.isUnlocked, the date at which it was unlocked.
	 */
	public java.util.Date unlockDate;
	/**
	 * The version of your application at which this achievement was introduced.
	 */
	public String endVersion;
	/**
	 * The version of your application at which this achievement was removed.
	 */
	public String startVersion;
	/**
	 * If you've specified an Achievement ordering on the Developer Dashboard,
	 * this is the position in the list of this Achievement.
	 */
	public int position; // unsigned
	
	/**
	 * A callback class you can extend for calling Achievement.list().
	 */
	public abstract static class ListCB extends APICallback {
		/**
		 * When Achievement.list() completes, this method will be called with
		 * the list of Achievements for your application.
		 * @param achievements the list of Achievements for your application. 
		 */
		public abstract void onSuccess(final List<Achievement> achievements);
	}
	/**
	 * Call this method to get a list of Achievements that are available
	 * to your application.  These are the Achievements that you've created
	 * on the Developer Dashboard.
	 * @param cb The callback object that will be given the list of Achievements.
	 */
	public static void list(final ListCB cb) {
		final String path =  "/xp/games/" + OpenFeintInternal.getInstance().getAppID() + "/achievements";
		JSONRequest req = new JSONRequest() {
			@Override public String method() { return "GET"; }
			@Override public String path() { return path; }
			
			@Override public void onSuccess(Object responseBody) {
				if (null != cb) {
					try {
						@SuppressWarnings("unchecked") List<Achievement> achievements = (List<Achievement>)responseBody;
						cb.onSuccess(achievements);
					} catch (Exception e) {
						onFailure(OpenFeintInternal.getRString(R.string.of_unexpected_response_format));
					}
				}
			}
			
			@Override public void onFailure(String exceptionMessage) {
				super.onFailure(exceptionMessage);
				if (cb != null) {
					cb.onFailure(exceptionMessage);
				}
			}
		};

		req.launch();
	}

	/**
	 * A callback class you can extend for calling downloadIcon().
	 */
	public abstract static class DownloadIconCB extends APICallback {
		/**
		 * When downloadIcon() completes, this method will be called with
		 * a Bitmap of the Achievement icon.
		 * @param iconBitmap the Achievement icon, as a Bitmap. 
		 */
		public abstract void onSuccess(final Bitmap iconBitmap);
	}
	/**
	 * Call this method to download the icon of the given Achievement, in
	 * android.graphics.Bitmap format.
	 * @param cb The callback object that will be given the Bitmap of the icon.
	 */
	public void downloadIcon(final DownloadIconCB cb) {
		if (this.iconUrl == null) {
			if (null != cb) {
				cb.onFailure(OpenFeintInternal.getRString(R.string.of_null_icon_url));
			}
			return;
		}
		
		BitmapRequest req = new BitmapRequest() {
			@Override public String method() { return "GET"; }

			@Override public String url() { return Achievement.this.iconUrl; }
			@Override public String path() { return ""; }
			
			@Override public void onSuccess(Bitmap responseBody) {
				if (null != cb) {
					cb.onSuccess(responseBody);
				}
			}
			
			@Override public void onFailure(String exceptionMessage) {
				if (null != cb) {
					cb.onFailure(exceptionMessage);
				}
			}
		};

		req.launch();
	}

	/**
	 * A callback class you can extend for calling Achievement.unlock().
	 */
	public abstract static class UnlockCB extends APICallback {
		/**
		 * Called when the achievement has been unlocked.
		 * @param newUnlock Will be true if this was a newly unlocked achievement for this user.
		 */
		public abstract void onSuccess(boolean newUnlock);
	}
	
	/**
	 * Call this method to unlock this Achievement for the currently logged-in user.
	 * @param cb an optional callback object that will be notified when Achievement
	 * unlocking succeeds or fails.
	 */	
	public void unlock(final UnlockCB cb) {
		UpdateProgressionCB upCB = null;
		if (cb != null) {
			upCB = new UpdateProgressionCB() {
				@Override public void onSuccess(boolean complete) {
					cb.onSuccess(complete);
				}
				@Override public void onFailure(String exceptionMessage) {
					cb.onFailure(exceptionMessage);
				}
			};
		}
		updateProgression(100.0f, upCB);
	}
	
	/**
	 * A callback class you can extend for calling Achievement.updateProgression().
	 */
	public abstract static class UpdateProgressionCB extends APICallback {
		/**
		 * Called when the achievement has been updated.  NOTE: onFailure() will be called if
		 * you attempt to update the progression with a lower percentComplete than previously existed.
		 * @param complete Will be true if this update caused the achievement to unlock for this user.
		 */
		public abstract void onSuccess(boolean complete);
	}
	
	/**
	 * Call this method to update the progression on this Achievement for the currently
	 * logged-in user.
	 * @param pctComplete the percentage completion, between 0.0f and 100.0f.
	 * @param cb an optional callback object that will be notified when Achievement
	 * updating succeeds or fails.  Note that if you provide a pctComplete outside of the 0.0f..100.0f range,
	 * it will be clamped, but if you try to update the progression value to a lower value, onFailure() will
	 * be called instead of onSuccess().
	 */	
	public void updateProgression(float pctComplete, final UpdateProgressionCB cb) {
		if (pctComplete > 100.f) pctComplete = 100.f;
		if (pctComplete < 0.f) pctComplete = 0.f;
		
		final String resID = resourceID();
		
		if (null == resID) {
			if (null != cb) {
				cb.onFailure(OpenFeintInternal.getRString(R.string.of_achievement_unlock_null));
			}
			return;
		}
		
		if (AchievementUnlockCache.isUnlocked(resID)) {
			if (cb != null) {
				cb.onSuccess(false);
			}
			return;
		}
			
		final String path = "/xp/games/" + OpenFeintInternal.getInstance().getAppID() + "/achievements/" + resID + "/unlock";
		
		OrderedArgList args = new OrderedArgList();
		args.put("percent_complete", new Float(pctComplete).toString());
		
		JSONRequest req = new JSONRequest(args) {
			@Override public boolean wantsLogin() { return true; }
			@Override public String method() { return "PUT"; }
			@Override public String path() { return path; }
			@Override protected void onResponse(int responseCode, Object responseBody) {
				if (responseCode >= 200 && responseCode < 300) { 
					final Achievement achievement = (Achievement) responseBody;
					
					final int oldPercentComplete = (int)Achievement.this.percentComplete;
					Achievement.this.shallowCopy(achievement);
					final int newPercentComplete = (int)Achievement.this.percentComplete;
					
					if (201 == responseCode) {
						AchievementUnlockCache.markAsUnlocked(resID);
						AchievementNotification.showStatus(achievement);
					}
					else if (newPercentComplete > oldPercentComplete) {
						AchievementNotification.showStatus(achievement);
					}
					
					if (null != cb) {
						cb.onSuccess(201 == responseCode);
					}
				} else {
					onFailure(responseBody);
				}
			}

			@Override public void onFailure(String exceptionMessage) {
				super.onFailure(exceptionMessage);
				if (cb != null) {
					cb.onFailure(exceptionMessage);
				}
			}
		};

		req.launch();
	}	

	/**
	 * A callback class you can extend for calling Achievement.load().
	 */
	public abstract static class LoadCB extends APICallback {
		/**
		 * when Achievement.load() completes, this will be called to let you know
		 * that the fields in the Achievement object on which load() was called
		 * are ready to be read.
		 */
		public abstract void onSuccess();
	}
	/**
	 * Call this method to fill out the fields of this Achievement object.  If you've
	 * created a Achievement with the (String resourceID) constructor and then call this
	 * method, all the remaining Achievement fields will be filled out for the Achievement
	 * represented by that resource ID.
	 * @param cb The callback object that will be notified when load() completes.
	 */
	public void load(final LoadCB cb) {
		final String resID = resourceID();
		if (null == resID) {
			if (null != cb) {
				cb.onFailure(OpenFeintInternal.getRString(R.string.of_achievement_load_null));
			}
			return;
		}

		final String path =  "/xp/games/" + OpenFeintInternal.getInstance().getAppID() + "/achievements/" + resID;
		
		JSONRequest req = new JSONRequest() {
			@Override public String method() { return "GET"; }
			@Override public String path() { return path; }
			@Override public void onSuccess(Object responseBody) {
				Achievement.this.shallowCopy((Achievement)responseBody);
				if (cb != null) {					
					cb.onSuccess();
				}
			}
			
			@Override public void onFailure(String exceptionMessage) {
				super.onFailure(exceptionMessage);
				if (cb != null) {
					cb.onFailure(exceptionMessage);
				}
			}
		};

		req.launch();
	}

	/**
	 * This constructor is for use by the parser only.
	 */
	public Achievement() { }

	/**
	 * This method is used internally by OpenFeint.
	 */
	public static ResourceClass getResourceClass() {
		ResourceClass klass = new ResourceClass (Achievement.class, "achievement") { public Resource factory () { return new Achievement (); } };

		klass.mProperties.put("title", new StringResourceProperty() { public void set(Resource obj, String val) { ((Achievement)obj).title = val; } public String get(Resource obj) { return ((Achievement)obj).title; } });
		klass.mProperties.put("description", new StringResourceProperty() { public void set(Resource obj, String val) { ((Achievement)obj).description = val; } public String get(Resource obj) { return ((Achievement)obj).description; } });
		klass.mProperties.put("gamerscore", new IntResourceProperty() { public void set(Resource obj, int val) { ((Achievement)obj).gamerscore = val; } public int get(Resource obj) { return ((Achievement)obj).gamerscore; } });
		klass.mProperties.put("icon_url", new StringResourceProperty() { public void set(Resource obj, String val) { ((Achievement)obj).iconUrl = val; } public String get(Resource obj) { return ((Achievement)obj).iconUrl; } });
		klass.mProperties.put("is_secret", new BooleanResourceProperty() { public void set(Resource obj, boolean val) { ((Achievement)obj).isSecret = val; } public boolean get(Resource obj) { return ((Achievement)obj).isSecret; } });
		klass.mProperties.put("is_unlocked", new BooleanResourceProperty() { public void set(Resource obj, boolean val) { ((Achievement)obj).isUnlocked = val; } public boolean get(Resource obj) { return ((Achievement)obj).isUnlocked; } });
		klass.mProperties.put("percent_complete", new FloatResourceProperty() { public void set(Resource obj, float val) { ((Achievement)obj).percentComplete = val; } public float get(Resource obj) { return ((Achievement)obj).percentComplete; } });
		klass.mProperties.put("unlocked_at", new DateResourceProperty() { public void set(Resource obj, Date val) { ((Achievement)obj).unlockDate = val; } public Date get(Resource obj) { return ((Achievement)obj).unlockDate; } });
		klass.mProperties.put("position", new IntResourceProperty() { public void set(Resource obj, int val) { ((Achievement)obj).position = val; } public int get(Resource obj) { return ((Achievement)obj).position; } });
		klass.mProperties.put("end_version", new StringResourceProperty() { public void set(Resource obj, String val) { ((Achievement)obj).endVersion = val; } public String get(Resource obj) { return ((Achievement)obj).endVersion; } });
		klass.mProperties.put("start_version", new StringResourceProperty() { public void set(Resource obj, String val) { ((Achievement)obj).startVersion = val; } public String get(Resource obj) { return ((Achievement)obj).startVersion; } });

		return klass;
	}
}