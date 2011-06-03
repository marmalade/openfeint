package com.openfeint.internal;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import android.provider.MediaStore;

import com.openfeint.internal.request.IRawRequestDelegate;

public class ImagePicker {
	public static final int IMAGE_PICKER_REQ_ID = 10009;
	protected static final String TAG = "ImagePicker";
	
	Activity mActivity;
	ImagePickerCB mCallback;
	String mApiPath;
	int mMaxLength;
	
	abstract public static class ImagePickerCB {
		public void onAbort() {}
		abstract public void onPictureChosen(Bitmap image);
	}
	
	public ImagePicker(Activity currentActivity, int maxLength, ImagePickerCB cb) {
		mActivity = currentActivity;
		mCallback = cb;
		mMaxLength = maxLength;
	}
	
	
	public ImagePicker(Activity currentActivity, String apiPath, int maxLength) {
		mActivity  = currentActivity;
		mApiPath   = apiPath;
		mMaxLength = maxLength;
	}

		
	public ImagePicker show() {
		ActivityManager am = (ActivityManager)mActivity.getSystemService(Activity.ACTIVITY_SERVICE);
		ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
		am.getMemoryInfo(mi);

		Intent intent = new Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.INTERNAL_CONTENT_URI);
		intent.setType("image/*");
		mActivity.startActivityForResult(intent, IMAGE_PICKER_REQ_ID);
		return this;
	}
	
	//note: this must be forwarded into by mActivity
	//return a true if the image picker detects the proper request code
	public boolean onActivityResult(int requestCode, int resultCode, Intent returnedIntent) {
		if(requestCode == IMAGE_PICKER_REQ_ID) {			
			if (resultCode == Activity.RESULT_OK) {  
				Uri selectedImage = returnedIntent.getData();
		        String[] columns = {MediaStore.Images.ImageColumns.DATA, MediaStore.Images.ImageColumns.ORIENTATION};
	
		        Cursor cursor = mActivity.getContentResolver().query(selectedImage, columns, null, null, null);
		        cursor.moveToFirst();
	
		        int columnIndex = cursor.getColumnIndex(columns[0]);
		        String filePath = cursor.getString(columnIndex);
				int rotation = cursor.getInt(cursor.getColumnIndex(columns[1]));
		        cursor.close();

		        Bitmap image = resize(filePath, mMaxLength, rotation);
		        OpenFeintInternal.log(TAG, "image! "+ image.getWidth() +"x"+ image.getHeight());
	
		        if(null != mCallback) {
		        	mCallback.onPictureChosen(image);
		        }
		        else {
			        ByteArrayOutputStream out = new ByteArrayOutputStream();
			        image.compress(Bitmap.CompressFormat.PNG, 100, out);
		        	upload(mApiPath, out);
		        }
	        }
			else {
				if(null != mCallback)
					mCallback.onAbort();			
			}
			return true;
		}
		return false;
	}
	
	private Bitmap resize(String filePath, int maxLength, int rotation) {
		Bitmap image = preScaleImage(filePath, maxLength);
		
		int width  = image.getWidth();
		int height = image.getHeight();
		boolean tall = height > width; 
		
		// Crop the center and make it square
		int _x = tall ? 0 : (width-height)/2;
		int _y = tall ? (height-width)/2 : 0;
		int _length = (tall ? width : height);
		
		float scale = (float)maxLength / (float)_length;

		Matrix transform = new Matrix();
		transform.postScale(scale, scale);
		transform.postRotate(rotation);

		return Bitmap.createBitmap(image, _x, _y, _length, _length, transform, false);
	}
	
	// http://stackoverflow.com/questions/477572/android-strange-out-of-memory-issue
	private Bitmap preScaleImage(String filePath, int maxLength) {
		File f = new File(filePath);
		
		try {
	        //Decode image size
	        BitmapFactory.Options o = new BitmapFactory.Options();
	        o.inJustDecodeBounds = true;
	        BitmapFactory.decodeStream(new FileInputStream(f), null, o);

	        //Find the correct scale value. It should be the power of 2.
	        int minDim = Math.min(o.outWidth, o.outHeight);
	        int scale = 1;
	        while (minDim/2 > maxLength) {
	            minDim /= 2;
	            scale++;
	        }

	        //Decode with inSampleSize
	        BitmapFactory.Options o2 = new BitmapFactory.Options();
	        o2.inSampleSize = scale;
	        return BitmapFactory.decodeStream(new FileInputStream(f), null, o2);
	        
	    } catch (FileNotFoundException e) {
	    	OpenFeintInternal.log(TAG, e.toString());
	    }
	    return null;
	}
	
	private void upload(String apiPath, ByteArrayOutputStream stream) {
   		OpenFeintInternal.getInstance().uploadFile(apiPath, "profile.png", stream.toByteArray(), "image/png", new IRawRequestDelegate() {
    		public void onResponse(int status, String responseBody) {
    			OpenFeintInternal.log(TAG, "UPLOAD FINISHED! status:"+ status +" response:"+ responseBody);
    		}
    	});
	}
}
