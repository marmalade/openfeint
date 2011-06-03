package com.openfeint.internal.request;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.openfeint.api.R;
import com.openfeint.internal.OpenFeintInternal;

public abstract class BitmapRequest extends DownloadRequest {

	// Override me
	public void onSuccess(Bitmap responseBody) { }

	@Override protected void onSuccess(byte[] body) {
		Bitmap b = BitmapFactory.decodeByteArray(body, 0, body.length);
		if (b != null) {
			onSuccess(b);
		} else {
			onFailure(OpenFeintInternal.getRString(R.string.of_bitmap_decode_error));
		}
	}

}
