package com.openfeint.internal.db;

import java.io.File;

import com.openfeint.internal.OpenFeintInternal;

import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.os.Environment;

public class DB {
	public static DataStorageHelperX storeHelper;
	
	private static boolean removeDB(Context ctx) {
	    String state = Environment.getExternalStorageState();
	    if (Environment.MEDIA_MOUNTED.equals(state)) {
	    	File sdcard = Environment.getExternalStorageDirectory();
		    File db = new File(sdcard, DBPATH);
		    return db.delete();
		} else {
		    return ctx.getDatabasePath(DBNAME).delete();
		}		
		
	}
	
	public static void createDB(Context ctx) {
	    String state = Environment.getExternalStorageState();
	    if (Environment.MEDIA_MOUNTED.equals(state)) {
	    	File sdcard = Environment.getExternalStorageDirectory();
		    storeHelper = new DataStorageHelperX(sdcard.getAbsolutePath() + DBPATH);
		} else {
			storeHelper = new DataStorageHelperX(ctx);
		}		
	}
	
	public static boolean recover(Context ctx) {
		if (storeHelper != null) {
			storeHelper.close();
		}
		boolean success = removeDB(ctx);
		if (success) {
		    createDB(ctx);
		    success = storeHelper != null;
		}
		return success;
	}
	
	public static void insertManifest(String[] values) {
		try {
			SQLiteDatabase db = storeHelper.getWritableDatabase();
			db.execSQL("INSERT OR REPLACE INTO manifest VALUES(?, ?)", values);		
			db.close();

		} catch (SQLException e) {
			OpenFeintInternal.log("SQL", e.toString());
		}
	}


	public static final String DBNAME = "manifest.db";
	private static final int VERSION = 2;
	private static final String DBPATH = "/openfeint/webui/manifest.db";
	public static class DataStorageHelperX extends SQLiteOpenHelperX {
		DataStorageHelperX(Context context) {
	        super(new DataStorageHelper(context));
	    }
		DataStorageHelperX(String path) {
	        super(path, VERSION);
	    }

	    @Override
	    public void onCreate(SQLiteDatabase db) {
	        db.execSQL("CREATE TABLE manifest (PATH TEXT PRIMARY KEY, HASH TEXT);");
	        db.execSQL("CREATE TABLE store (ID TEXT PRIMARY KEY, VALUE TEXT);");
	    }
	    
	    @Override
	    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
	    	if (oldVersion == 1) {
		        db.execSQL("CREATE TABLE store (ID TEXT PRIMARY KEY, VALUE TEXT);");
	    	}
	    }
	}
	
	public static class DataStorageHelper extends SQLiteOpenHelper {

	    DataStorageHelper(Context context) {
	        super(context, DBNAME, null, VERSION);
	    }

	    @Override
	    public void onCreate(SQLiteDatabase db) {
	        db.execSQL("CREATE TABLE manifest (PATH TEXT PRIMARY KEY, HASH TEXT);");
	        db.execSQL("CREATE TABLE store (ID TEXT PRIMARY KEY, VALUE TEXT);");
	    }
	    
	    @Override
	    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
	    	if (oldVersion == 1) {
		        db.execSQL("CREATE TABLE store (ID TEXT PRIMARY KEY, VALUE TEXT);");
	    	}
	    }
	}
}
