package com.openfeint.internal.request;

import com.openfeint.api.R;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.Util;
import com.openfeint.internal.resource.ServerException;

public abstract class JSONRequest extends JSONContentRequest {
	
	public void onSuccess(Object responseBody) { }
	public void onFailure(String exceptionMessage) { }

	public JSONRequest() {
		super();
	}
	
	public JSONRequest(OrderedArgList args) {
		super(args);
	}
	
	public void onResponse(int responseCode, byte[] bodyStream) {
		if (!isResponseJSON()) {
			// Server screwed up.
			onResponse(responseCode, notJSONError(responseCode));
		} else {
//			OpenFeintInternal.log("JSONRequest", bodyStream);
//			bodyStream = new ByteArrayInputStream(s.getBytes("UTF-8"));
			Object responseBody = Util.getObjFromJson(bodyStream);
			if (responseBody != null) onResponse(responseCode, responseBody);
		}
	}

	protected void onResponse(int responseCode, Object responseBody) {
		if (200 <= responseCode && responseCode < 300 && (responseBody == null || !(responseBody instanceof ServerException))) {
			onSuccess(responseBody);
		} else {
			onFailure(responseBody);
		}
	}

	protected void onFailure(Object responseBody) {
		String exceptionMessage = OpenFeintInternal.getRString(R.string.of_unknown_server_error);
		
		if (responseBody != null && responseBody instanceof ServerException) {
			ServerException e = (ServerException)responseBody;
			exceptionMessage = e.message;
			
			if (e.needsDeveloperAttention) {
				OpenFeintInternal.log("ServerException", exceptionMessage);
				OpenFeintInternal.getInstance().displayErrorDialog(exceptionMessage);
			}
		}
		
		onFailure(exceptionMessage);
	}
}
