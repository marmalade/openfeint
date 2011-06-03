package com.openfeint.internal.request;

import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.Util;

public class CacheFileRequest extends CacheRequest {
	private static final String TAG = "CacheFile";
    protected String path;
    protected String url;
    public CacheFileRequest(String path, String url, String key) {
    	super(key);
    	this.path = path;
    	this.url = url;
    }

	@Override
	public void onResponse(int responseCode, byte[] body) {
		if(responseCode == 200) {
			try {
				Util.saveFile(body, path);
				super.on200Response();
			} catch (Exception e) {
				OpenFeintInternal.log(TAG, e.toString());
			}
		}		
	}

	@Override
	public String path() {
		return url;
	}
    
}
