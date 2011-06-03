package com.openfeint.internal.request;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.DeflaterOutputStream;

import com.openfeint.api.OpenFeintSettings;
import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.request.multipart.ByteArrayPartSource;
import com.openfeint.internal.request.multipart.PartSource;
import com.openfeint.internal.resource.BlobUploadParameters;

public class CompressedBlobPostRequest extends BlobPostRequest {
	
	BlobUploadParameters mParameters;
	String mFilename;
	byte mUncompressedData;
	
	public CompressedBlobPostRequest(BlobUploadParameters parameters, String filename, byte[] uncompressedData) {
		super(parameters, _makePartSource(filename, uncompressedData), "application/octet-stream");
	}

	public static final byte[] MagicHeader = "OFZLHDR0".getBytes();
	
	public enum CompressionMethod {
		Default,
		Uncompressed,
		LegacyHeaderless,
	};
	
	public static CompressionMethod compressionMethod() {
		String s = (String)OpenFeintInternal.getInstance().getSettings().get(OpenFeintSettings.SettingCloudStorageCompressionStrategy);
		if (s == null)
			return CompressionMethod.Default;
		if (s.equals(OpenFeintSettings.CloudStorageCompressionStrategyLegacyHeaderlessCompression))
			return CompressionMethod.LegacyHeaderless;
		if (s.equals(OpenFeintSettings.CloudStorageCompressionStrategyNoCompression))
			return CompressionMethod.Uncompressed;
		return CompressionMethod.Default;
	}
	
	private static byte[] _compress(byte data[]) throws IOException {
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DeflaterOutputStream dos = new DeflaterOutputStream(baos);

		dos.write(data);
		dos.close();
		return baos.toByteArray();
	}
	
	// This is little endian for compatibility with the iOS api.  in a better world we'd use network byte order.
	private static byte[] integerToLittleEndianByteArray(int i) {
		byte rv[] = new byte[4];
		rv[0] = (byte)(i >>  0);
		rv[1] = (byte)(i >>  8);
		rv[2] = (byte)(i >> 16);
		rv[3] = (byte)(i >> 24);
		return rv;
	}
	
	private static PartSource _makePartSource(String filename, byte[] uncompressedData) {
		byte uploadData[] = uncompressedData;
		
		try {
			switch (compressionMethod()) {
			case Default:
			{
				byte tenativeData[] = _compress(uncompressedData);
				byte[] uncompressedSize = integerToLittleEndianByteArray(uncompressedData.length);
				final int compressedLength = tenativeData.length + MagicHeader.length + uncompressedSize.length;
				if (compressedLength < uncompressedData.length) {
					uploadData = new byte[compressedLength];
					System.arraycopy(MagicHeader, 0, uploadData, 0, MagicHeader.length);
					System.arraycopy(uncompressedSize, 0, uploadData, MagicHeader.length, uncompressedSize.length);
					System.arraycopy(tenativeData, 0, uploadData, MagicHeader.length + 4, tenativeData.length);
				}
			}
				break;
			case LegacyHeaderless:
				uploadData = _compress(uncompressedData);
				break;
			default:
				// default in this case is uncompressed, so just use the uncompressedData.
				break;
			}
		} catch (IOException e) {
			return null;
		}
		
		return new ByteArrayPartSource(filename, uploadData);
	}
}
