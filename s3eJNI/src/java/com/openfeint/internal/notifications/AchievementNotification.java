package com.openfeint.internal.notifications;

import java.util.HashMap;
import java.util.Map;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.openfeint.api.R;
import com.openfeint.api.resource.Achievement;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.request.BitmapRequest;
import com.openfeint.internal.request.ExternalBitmapRequest;


public class AchievementNotification extends NotificationBase {
	protected AchievementNotification(Achievement achievement, Map<String,Object> userData) {
		//TODO: read from achievement or factory function
		super(OpenFeintInternal.getRString(R.string.of_achievement_unlocked), null, Category.Achievement, Type.Success, userData);
	}

	
	public void loadedImage(Bitmap map) {
		displayView.invalidate();
	}

	@Override protected boolean createView() {
		final Achievement achievement = (Achievement) getUserData().get("achievement");

		LayoutInflater inflater = (LayoutInflater)OpenFeintInternal.getInstance().getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		displayView = inflater.inflate(R.layout.of_achievement_notification, null);
		if (achievement.isUnlocked) {
			displayView.findViewById(R.id.of_achievement_progress_icon).setVisibility(View.INVISIBLE);
		} else {
			displayView.findViewById(R.id.of_achievement_score_icon).setVisibility(View.INVISIBLE);
		}
		
		((TextView)displayView.findViewById(R.id.of_achievement_text)).setText(achievement.title);
		
		final String scoreText = achievement.isUnlocked ? Integer.toString(achievement.gamerscore) : String.format("%d%%", (int)achievement.percentComplete);
		((TextView)displayView.findViewById(R.id.of_achievement_score)).setText(scoreText);
		
		if(null != achievement.iconUrl) {
			final Drawable iconImage = getResourceDrawable(achievement.iconUrl);
			if(null == iconImage) {
				//try to load from Feint server
				BitmapRequest req = new ExternalBitmapRequest(achievement.iconUrl) {
					
					@Override public void onSuccess(Bitmap responseBody) {
						((ImageView)displayView.findViewById(R.id.of_achievement_icon)).setImageDrawable(new BitmapDrawable(responseBody));
						showToast();
					}
					
					@Override public void onFailure(String exceptionMessage) {
						OpenFeintInternal.log("NotificationImage", "Failed to load image "+ achievement.iconUrl + ":" + exceptionMessage);
						showToast();
					}
				};
		
				req.launch();
				return false;
			}
			else
			{
				((ImageView)displayView.findViewById(R.id.of_achievement_icon)).setImageDrawable(iconImage);
			}
		}
		return true;
	}
	
	@Override
	protected void drawView(Canvas canvas) {
		displayView.draw(canvas);
	}
	
	public static void showStatus(Achievement achievement) {
		Map<String,Object> userData = new HashMap<String,Object>();
		userData.put("achievement", achievement);
		AchievementNotification notification = new AchievementNotification(achievement, userData);
		notification.checkDelegateAndView();
	}
	
}
