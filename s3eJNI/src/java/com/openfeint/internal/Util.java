package com.openfeint.internal;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;
import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.Environment;
import android.util.DisplayMetrics;
import android.view.WindowManager;

import com.openfeint.api.OpenFeintSettings;
import com.openfeint.internal.resource.ResourceClass;

public class Util {
	private static final String TAG = "Util";
	public static final int VERSION = Integer.valueOf(Build.VERSION.SDK);
    public static boolean isEclairOrLater() {
    	return VERSION >= 5;
    }

    public static void setOrientation(Activity act) {
        Integer orientation =(Integer) OpenFeintInternal.getInstance().getSettings().get(OpenFeintSettings.RequestedOrientation);

        if (orientation != null) {
            act.setRequestedOrientation(orientation.intValue());
        }
    }

    public static final byte[] toByteArray(InputStream is) throws IOException {
		final int CHUNK_SIZE = 4096;
		byte readBuffer[] = new byte[CHUNK_SIZE];
		ByteArrayOutputStream accumulator = new ByteArrayOutputStream();
		int count;
		while ((count = is.read(readBuffer)) > 0) {
			accumulator.write(readBuffer, 0, count);
		}
		accumulator.close();
		return accumulator.toByteArray();
	}
	
	public static void deleteFiles(File path) {
		if(path.isDirectory()) {
			String[] files = path.list();
			for(String name : files) {
				File child = new File(path, name);
				deleteFiles(child);
			}
		}
		path.delete();
	}
	
	// Copies all files under srcDir to dstDir.
	// If dstDir does not exist, it will be created.
	public static void copyDirectory(File srcDir, File dstDir) throws IOException {
	    if (srcDir.isDirectory()) {
	        if (!dstDir.exists()) {
	            dstDir.mkdir();
	        }

	        String[] children = srcDir.list();
	        for (int i=0; i<children.length; i++) {
	            copyDirectory(new File(srcDir, children[i]),
	                                 new File(dstDir, children[i]));
	        }
	    } else {
	        // This method is implemented in Copying a File
	        copyFile(srcDir, dstDir);
	    }
	}
	
	public static void copyFile(File src, File dst) throws IOException {
        InputStream in = new FileInputStream(src);
        OutputStream out = new FileOutputStream(dst);
        copyStream(in, out);
	}
	
	public static void copyStream(InputStream in, OutputStream out) throws IOException {
        // Copy the bits from instream to outstream
        int len;
        byte[] copyBuffer = new byte[16384];
        while ((len = in.read(copyBuffer)) > 0) {
            out.write(copyBuffer, 0, len);
        }
        in.close();
        out.close();
	}
	
	public static void saveFile(byte[] in, String path) throws IOException {
		File file = new File(path);
		file.getParentFile().mkdirs();
	    FileOutputStream out =  new FileOutputStream(file);
	    out.write(in);
	    out.close();
	}
	
	public static DisplayMetrics getDisplayMetrics() {
		DisplayMetrics metrics = new DisplayMetrics();
		WindowManager wm = (WindowManager)OpenFeintInternal.getInstance().getContext().getSystemService(Context.WINDOW_SERVICE);
		wm.getDefaultDisplay().getMetrics(metrics);
		return metrics;
	}

	public static void run(String cmd) {
		try {
			java.lang.Runtime.getRuntime().exec(cmd);
			OpenFeintInternal.log(TAG, cmd);

		} catch (Exception e) {
			OpenFeintInternal.log(TAG, e.getMessage());
		}
	}

	public static void createSymbolic(String dst, String src) {
		run("ln -s " + dst + " " + src);
	}

	public static boolean isSymblic(File f) {
		try {
			return !f.getCanonicalPath().equals(f.getAbsolutePath());
		} catch (IOException e) {
		}
		return false;
	}

	public static void moveWebCache(Context ctx) {
		File cache = new File(ctx.getCacheDir(), "webviewCache");

		if (isSymblic(cache)) {
			return;
		}
	    String state = Environment.getExternalStorageState();
	    if (!Environment.MEDIA_MOUNTED.equals(state)) {
	    	return;
	    }
	   	File sdcard = new File(Environment.getExternalStorageDirectory(), "openfeint/cache");
    	if (!sdcard.exists()) {
    		sdcard.mkdirs();
    	}
		deleteFiles(cache);
		createSymbolic(sdcard.getAbsolutePath(), cache.getAbsolutePath());
	}
	
	public static byte[] readWholeFile(String path) throws IOException {
		File f = new File(path);
		int len = (int)f.length();
		InputStream in = new FileInputStream(f);
		byte[] b = new byte[len];
		in.read(b);
		return b;
	}
	public static Object getObjFromJsonFile(String path) {
		try {
	        InputStream in = new FileInputStream(new File(path));
	        return getObjFromJsonStream(in);
		}	catch (Exception e) {
		}
		return null;
	}
	
	public static Object getObjFromJsonStream(InputStream in) throws JsonParseException, IOException {
		JsonFactory jsonFactory = new JsonFactory(); // for thread safety, we make our own.
		JsonParser jp = jsonFactory.createJsonParser(in);
		JsonResourceParser jrp = new JsonResourceParser(jp);
		return jrp.parse();
	}

	public static Object getObjFromJson(byte[] json) {
		JsonFactory jsonFactory = new JsonFactory(); // for thread safety, we make our own.
		try {
			JsonParser jp = jsonFactory.createJsonParser(json);
			JsonResourceParser jrp = new JsonResourceParser(jp);
			return jrp.parse();
		} catch (Exception e) {
			OpenFeintInternal.log(TAG, e.getMessage());
		}
		return null;
	}

	public static Object getObjFromJson(byte[] json, ResourceClass resourceClass) {
        JsonFactory jsonFactory = new JsonFactory(); // for thread safety, we make our own.
        try {
            JsonParser jp = jsonFactory.createJsonParser(json);
            JsonResourceParser jrp = new JsonResourceParser(jp);
            return jrp.parse(resourceClass);
        } catch (Exception e) {
            OpenFeintInternal.log(TAG, e.getMessage());
        }
        return null;
    }

	public static String getDpiName(Context ctx) {
        DisplayMetrics metrics = new DisplayMetrics();
        WindowManager winMan = (WindowManager)ctx.getSystemService(Context.WINDOW_SERVICE);
        winMan.getDefaultDisplay().getMetrics(metrics);
        if (metrics.density >= 2) {
            return "udpi";
        } else if (metrics.density >= 1.5) {
            return "hdpi";
        } else {
            return "mdpi";
        }
    }
    
}
