package com.openfeint.internal.request;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.concurrent.Future;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpEntityEnclosingRequestBase;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.AbstractHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpParams;
import org.apache.http.util.EntityUtils;

import com.openfeint.api.R;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.resource.ServerException;

public abstract class BaseRequest {

	private static int DEFAULT_RETRIES = 2;
	private static long DEFAULT_TIMEOUT = 20 * 1000;
	
	protected static String TAG = "Request";
	private OrderedArgList mArgs;
	private HttpUriRequest mRequest;
	private byte[] mResponseBody;
	private boolean mResponded = false;
	private String mResponseEncoding = null;
	private String mResponseType = null;
	protected String getResponseEncoding() { return mResponseEncoding; }
	protected String getResponseType() { return mResponseType; }
	private int mResponseCode;
	private static String sBaseServerURL = null;
	private long mSecondsSinceEpoch;
	private String mSignature = null;
	private String mKey = null;
	private int mRetriesLeft = 0;
	
	public int numRetries() { return DEFAULT_RETRIES; }
	public long timeout() { return DEFAULT_TIMEOUT; }
	
	private Future<?> mFuture = null;
	
	private HttpParams mHttpParams = null;
	
	public void setFuture(Future<?> future) {
		mFuture = future;
	}

	public Future<?> getFuture() {
		return mFuture;
	}
	
	protected HttpParams getHttpParams() { 
		if (mHttpParams == null) {
			mHttpParams = new BasicHttpParams();
		}
		return mHttpParams;
	}
	
	// If we know a request will fail if we're not logged in, override
	// wantsLogin() to return true.  This way, if we can log in and we're not
	// already logged in, we'll issue a login request and queue the given request
	// after that.
	public boolean wantsLogin() {
		return false;
	}

	// By default, requests are signed - we turn it off as necessary to save cpu.
	public boolean signed() { return true; }
	
	// Almost all requests need the device session.  The exception are requests that aren't signed
	// (i.e., aren't going to (sBaseServerURL + "/xp/" + x), and of course the device session itself.
	// This exists primarily to keep requests from issuing in parallel with the session and stomping
	// on cookies.
	public boolean needsDeviceSession() { return signed(); }

	public BaseRequest() {
		super();
	}
	
	public BaseRequest(OrderedArgList args) {
		super();
		setArgs(args);
	}

	public abstract String method();

	public abstract String path();

	public String url() {
		if (sBaseServerURL == null) {
			sBaseServerURL = OpenFeintInternal.getInstance().getServerUrl();
		}
		return sBaseServerURL + path();
	}

	public final void sign(Signer authority) {
		if (mArgs==null) mArgs = new OrderedArgList();
		if (signed()) {
			mSecondsSinceEpoch = System.currentTimeMillis()/1000;
			mSignature = authority.sign(path(), method(), mSecondsSinceEpoch, mArgs);
			mKey = authority.getKey();
		}
	}

	public final void setArgs(OrderedArgList args) {
		mArgs = args;
	}
	
	protected HttpUriRequest generateRequest() {
		HttpUriRequest retval = null;
		String meth = method();
		
		if (meth.equals("GET") || meth.equals("DELETE")) {
			String url = url();
			String argString = mArgs.getArgString();
			if (argString != null) {
				url += "?" + argString;
			}
			if      (meth.equals("GET"))    retval = new HttpGet   (url);
			else if (meth.equals("DELETE")) retval = new HttpDelete(url);
		} else {
			HttpEntityEnclosingRequestBase postReq = null;
			
			if      (meth.equals("POST")) 	postReq = new HttpPost(url());
			else if (meth.equals("PUT"))  	postReq = new HttpPut(url());
			else throw new RuntimeException("Unsupported HTTP method: "+ meth);
			
			try {
				String encoding = "UTF-8";
				UrlEncodedFormEntity entity = new UrlEncodedFormEntity(mArgs.getArgs(), encoding);
				entity.setContentType("application/x-www-form-urlencoded; charset=" + encoding);
				postReq.setEntity(entity);
			} catch (UnsupportedEncodingException e) {
				OpenFeintInternal.log(TAG, "Unable to encode request.");
				e.printStackTrace(System.err);
			}
			
			retval = postReq;
		}

		if (signed() && mSignature != null && mKey != null) {
			retval.addHeader("X-OF-Signature", mSignature);
			retval.addHeader("X-OF-Key", mKey);
		}
		
		addParams(retval);
		
		return retval;
	}

	protected final void addParams(HttpUriRequest retval) {
		if (mHttpParams != null) {
			retval.setParams(mHttpParams);
		}
	}
	private HttpResponse response_;
	public final void exec() {
		mRequest = generateRequest();
		mRetriesLeft = numRetries();
	
		mResponseBody = null;

		while (mResponseBody == null) {
			try {
				AbstractHttpClient client = OpenFeintInternal.getInstance().getClient();
				client.execute(mRequest, new ResponseHandler<Object>() {

					@Override
					public Object handleResponse(HttpResponse response)
							throws ClientProtocolException, IOException {
				        HttpEntity entity = response.getEntity();
				        // Failure by default
				        mResponseBody = new byte[0];
			        	mResponseCode = response.getStatusLine().getStatusCode();

				        if (entity != null) {
				        	final Header contentEncoding = entity.getContentEncoding();
 				        	if (contentEncoding != null) {
 				        		mResponseEncoding = contentEncoding.getValue();
 				        	}
 				        	
 				        	final Header contentType = entity.getContentType();
 				        	if (contentType != null) {
 				        		mResponseType = contentType.getValue();
 				        	}

 				        	mResponseBody = EntityUtils.toByteArray(entity);
 				        	if (entity.getContentLength() >= 0 && entity.getContentLength() != mResponseBody.length) {
				        		// Content-Length mismatch with content, consider this a failure
				        		OpenFeintInternal.log(TAG, "Content-Length mismatch with content - " + mRequest.getURI().toASCIIString());
				        		mResponseCode = 0;
				        	}
				        }
						response_ = response;
				        return null;
					}
				
				});
				
				mRequest = null;
				
			} catch (Exception e) {
				OpenFeintInternal.log(TAG, "Error executing request '" + path() + "'.");
				e.printStackTrace(System.err);
				if (--mRetriesLeft < 0) {
					// build up a fake exception body.
					ServerException se = new ServerException();
					se.exceptionClass = e.getClass().getName();
					se.message = e.getMessage();
					if (se.message == null) {
						se.message = OpenFeintInternal.getRString(R.string.of_unknown_server_error);
					}
					String exceptionBody = se.generate();
		        	mResponseBody = exceptionBody.getBytes();
		        	mResponseCode = 0;
		        	break;
				}
			}
		}
	}
	
	/*
	 *  this only valid during life time of onResponse
	 */
	public HttpResponse getResponse() { return response_;}

	public abstract void onResponse(int responseCode, byte[] body);
	public final void onResponse() {
		if (!mResponded) {
			mResponded = true;
			onResponse(mResponseCode, mResponseBody);
			response_ = null;
		}
	}
	
	public void launch() {
		OpenFeintInternal.makeRequest(this);
	}
	
	public void postTimeoutCleanup() {
    	final HttpUriRequest req = mRequest;
		mRequest = null;

		if (null != req) {
    		try {
    			req.abort();
    		} catch (UnsupportedOperationException e) {
    			// well, we tried
    		}
    	}

    	ServerException se = new ServerException();
		se.exceptionClass = "Timeout";
		se.message = OpenFeintInternal.getRString(R.string.of_timeout);
    	mResponseBody = se.generate().getBytes();
    	mResponseCode = 0;
    }
}