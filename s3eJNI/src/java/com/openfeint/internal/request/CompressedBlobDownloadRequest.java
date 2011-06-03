package com.openfeint.internal.request;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.InflaterInputStream;

import com.openfeint.api.R;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.Util;

public abstract class CompressedBlobDownloadRequest extends DownloadRequest {

	@Override
	protected final void onSuccess(byte[] body) {
		try {
			switch (CompressedBlobPostRequest.compressionMethod()) {
			case Default:
			{
				int i=0;
				if (CompressedBlobPostRequest.MagicHeader.length < body.length) {
					for (; i<CompressedBlobPostRequest.MagicHeader.length; ++i) {
						if (CompressedBlobPostRequest.MagicHeader[i] != body[i])
							break;
					}
				}
				
				if (i == CompressedBlobPostRequest.MagicHeader.length) {
					// skip four bytes for the size_t that we don't need
					int skip = CompressedBlobPostRequest.MagicHeader.length + 4;
					final ByteArrayInputStream postHeaderStream = new ByteArrayInputStream(body,
							skip,
							body.length - skip);
					final InputStream decompressedStream = new InflaterInputStream(postHeaderStream);
					body = Util.toByteArray(decompressedStream);
				}
			}
				break;
			
			case LegacyHeaderless:
				body = Util.toByteArray(new InflaterInputStream(new ByteArrayInputStream(body)));
				break;
				
			default:
				// no compression.
			}

			onSuccessDecompress(body);
		} catch (IOException e) {
			onFailure(OpenFeintInternal.getRString(R.string.of_io_exception_on_download));
		}
	}
	
	abstract protected void onSuccessDecompress(byte decompressedBody[]);
}
