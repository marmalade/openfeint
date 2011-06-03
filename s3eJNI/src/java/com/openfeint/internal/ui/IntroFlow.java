package com.openfeint.internal.ui;

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.Map;

import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;

import com.openfeint.api.OpenFeint;
import com.openfeint.internal.ImagePicker;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.Util;
import com.openfeint.internal.Util5;
import com.openfeint.internal.ImagePicker.ImagePickerCB;
import com.openfeint.internal.request.IRawRequestDelegate;

public class IntroFlow extends WebNav {
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
    	super.onCreate(savedInstanceState);

    	/* Disabled code for dialog style theme which seems to make text fields almost unusable. */
//    	DisplayMetrics metrics = new DisplayMetrics();
//		WindowManager winMan = (WindowManager)getSystemService(Context.WINDOW_SERVICE);
//		winMan.getDefaultDisplay().getMetrics(metrics);
//		
//		int hMargin = (int)(5  * metrics.density);
//		int vMargin = (int)(29 * metrics.density);
//		
//    	getWindow().setLayout(metrics.widthPixels - hMargin, metrics.heightPixels - vMargin);
    }
	
	@Override
	protected String initialContentPath() {
		String contentName = getIntent().getStringExtra("content_name");
		if (contentName != null) {
			return "intro/"+ contentName;
		} else {
			return "intro/index";
		}
	}

	ImagePicker mImagePicker;
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent returnedIntent) {
		if(null != mImagePicker) {
			if(mImagePicker.onActivityResult(requestCode, resultCode, returnedIntent)) {
				mImagePicker = null;
			}
		}
	}

	
	@Override
	protected ActionHandler createActionHandler(WebNav webNav) {
		return new IntroFlowActionHandler(webNav);
    }

	private class IntroFlowActionHandler extends ActionHandler {
		public IntroFlowActionHandler(WebNav webNav) {
			super(webNav);
		}

    		@Override
    		protected void populateActionList(List<String> actionList) {
    			super.populateActionList(actionList);
    			actionList.add("createUser");
    			actionList.add("loginUser");
    			actionList.add("cacheImage");
    			actionList.add("uploadImage");
    			actionList.add("clearImage");
    			actionList.add("decline");
    			actionList.add("getEmail");
    		}
    		
    		@SuppressWarnings("unused")
			final public void createUser(final Map<String,String> options) {
    			OpenFeintInternal.getInstance().createUser(
    				options.get("name"),
    				options.get("email"),
    				options.get("password"),
    				options.get("password_confirmation"),
    				new IRawRequestDelegate() {
    					@Override
    					public void onResponse(int status, String response) {
    						String js = String.format("%s('%d', %s)", options.get("callback"), status, response.trim());
    						mWebNav.executeJavascript(js);
    					}
    				}
    			);
    		}
    		
    		@SuppressWarnings("unused")
			final public void loginUser(final Map<String,String> options) {
    			OpenFeintInternal.getInstance().loginUser(
    				options.get("email"),
    				options.get("password"),
    				options.get("user_id"),
    				new IRawRequestDelegate() {
    					@Override
    					public void onResponse(int status, String response) {
    						String js = String.format("%s('%d', %s)", options.get("callback"), status, response.trim());
    						mWebNav.executeJavascript(js);
    					}
    				}
    			);
    		}
    		
    		Bitmap cachedImage;
    		@SuppressWarnings("unused")
    		final public void cacheImage(final Map<String,String> options) {
    			//read the image and store it
    			mImagePicker = new ImagePicker(
        				IntroFlow.this,
        				152,
        				new ImagePickerCB() {							
							@Override
							public void onPictureChosen(Bitmap image) {
								cachedImage = image;
							}
						}
        			).show();
    		}
    		
    		@SuppressWarnings("unused")
    		final public void uploadImage(final Map<String,String> options) {
    			//get the image that was stored and upload it
    			if(null != cachedImage) {
					String apiUrl = "/xp/users/"+ OpenFeintInternal.getInstance().getCurrentUser().resourceID() +"/profile_picture";
			        ByteArrayOutputStream out = new ByteArrayOutputStream();
			        cachedImage.compress(Bitmap.CompressFormat.PNG, 100, out);
					upload(apiUrl, out);
    			}
    		}
    		
    		@SuppressWarnings("unused")
    		final public void clearImage(final Map<String,String> options) {
    			cachedImage = null;
    		}
    		
    		@SuppressWarnings("unused")
    		public void decline(final Map<String, String> options) {
    			OpenFeint.userDeclinedFeint();
    			finish();
    		}
    		
    		@SuppressWarnings("unused")
    		public void getEmail(final Map<String, String> options) {
    	    	if (Util.isEclairOrLater()) {
    	    		String account = Util5.getAccountNameEclair(IntroFlow.this);
    	    		if (account != null) {
    	    			executeJavascript(String.format("%s('%s');", options.get("callback"), account));
    	    		}
    	    	}
    		}
    		
    		private void upload(String apiPath, ByteArrayOutputStream stream) {
    	   		OpenFeintInternal.getInstance().uploadFile(apiPath, "profile.png", stream.toByteArray(), "image/png", new IRawRequestDelegate() {
    	    		public void onResponse(int status, String responseBody) {
    	    			OpenFeintInternal.log(TAG, "UPLOAD FINISHED! status:"+ status +" response:"+ responseBody);
    	    		}
    	    	});
    		}
    	};
    }
