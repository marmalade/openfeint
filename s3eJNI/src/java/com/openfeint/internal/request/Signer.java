package com.openfeint.internal.request;

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.codec.binary.Base64;

public class Signer {
	private String mKey;
	public String getKey() { return mKey; }
	
	private String mSecret;
	
	private String mSigningKey;
	
	private String mAccessToken;
	
	public Signer(String key, String secret) {
		mKey = key;
		mSecret = secret;
		mSigningKey = mSecret + "&";
	}
	
	public void setAccessToken(String token, String tokenSecret) {
		mAccessToken = token;
		mSigningKey = mSecret + "&" + tokenSecret;
	}
	
	public String sign(String path, String method, long secondsSinceEpoch, OrderedArgList unsignedParams) {
		
		if (mAccessToken != null) { unsignedParams.put("token", mAccessToken); }
		
		StringBuilder sigbase = new StringBuilder();
		sigbase.append(path);
		sigbase.append('+');
		sigbase.append(mSecret);
		sigbase.append('+');
		sigbase.append(method);
		sigbase.append('+');
		
		final String argString = unsignedParams.getArgString();
		sigbase.append(argString == null ? "" : argString);
		
		try {
		    SecretKeySpec key = new SecretKeySpec((mSigningKey).getBytes("UTF-8"),"HmacSHA1");
		    Mac mac = Mac.getInstance("HmacSHA1");
		    mac.init(key);
		    byte[] bytes = mac.doFinal(sigbase.toString().getBytes("UTF-8"));
		    return new String(Base64.encodeBase64(bytes)).replace("\r\n", "");
		} catch (UnsupportedEncodingException e) {
		} catch (InvalidKeyException e) {
		} catch (NoSuchAlgorithmException e) {
		}
		
		return null;
	}
};
