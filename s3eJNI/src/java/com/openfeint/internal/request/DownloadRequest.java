package com.openfeint.internal.request;

import java.io.IOException;

import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonParser;

import com.openfeint.api.R;
import com.openfeint.internal.JsonResourceParser;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.resource.ServerException;

public abstract class DownloadRequest extends BaseRequest {

	public DownloadRequest() {
		super();
	}

	public DownloadRequest(OrderedArgList args) {
		super(args);
	}

	@Override public String method() { return "GET"; }

	public void onFailure(String exceptionMessage) {
		OpenFeintInternal.log("ServerException", exceptionMessage);
	}

	@Override
	public void onResponse(int responseCode, byte[] body) {
		String exceptionMessage = OpenFeintInternal.getRString(R.string.of_unknown_server_error);
		if (200 <= responseCode && responseCode < 300 && body != null) {
			onSuccess(body);
			return;
		} else if (404 == responseCode) {
			exceptionMessage = OpenFeintInternal.getRString(R.string.of_file_not_found);
		} else try {
			// try to parse response body
			JsonFactory jsonFactory = new JsonFactory(); // for thread safety, we make our own.
			JsonParser jp = jsonFactory.createJsonParser(body);
			JsonResourceParser jrp = new JsonResourceParser(jp);
			Object responseBody = jrp.parse();
			if (responseBody != null && responseBody instanceof ServerException) {
				ServerException e = (ServerException)responseBody;
				exceptionMessage = e.exceptionClass + ": " + e.message;
			}
		} catch (IOException e) {
				exceptionMessage = OpenFeintInternal.getRString(R.string.of_error_parsing_error_message);
		}
		onFailure(exceptionMessage);
	}

	protected abstract void onSuccess(byte[] body);

}