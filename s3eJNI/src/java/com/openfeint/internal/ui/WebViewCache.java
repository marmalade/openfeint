package com.openfeint.internal.ui;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.DefaultHandler;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;

import com.openfeint.internal.OpenFeintInternal;
import com.openfeint.internal.Util;
import com.openfeint.internal.db.DB;
import com.openfeint.internal.request.BaseRequest;
import com.openfeint.internal.request.CacheRequest;

public class WebViewCache {
	final static String TAG = "WebViewCache";
	
	//PUBLIC API
	public static URI serverOverride;  //set before initialization
	public static String manifestPrefixOverride;  //set before initialization
	
	public static WebViewCache initialize(Context context) {
		sInstance = new WebViewCache(context);
		return sInstance;
	}
	
	public static void prioritize(String path) {
	    sInstance.prioritizeInner(path);
	}
	
	public static boolean trackPath(String path, WebViewCacheCallback cb) {
		return sInstance.trackPathInner(path, cb);
	}

	public static boolean isLoaded(String path) {
		return sInstance.isLoadedInner(path);
	}
	
	private static final String WEBUI = "webui";
	public final void setRootUriSdcard(final File path) {
    	final File webui = new File(path, WEBUI);
    	final boolean copyDefault = !webui.exists();
    	if (copyDefault) {
		    File noMedia = new File(path, ".nomedia");
		    try {
		      noMedia.createNewFile();
            } catch (IOException e) {
    	    }

    		if (!webui.mkdirs()) {
    			setRootUriInternal();
    	        return;
    		}
    	}
    	rootPath = webui.getAbsolutePath() + "/";
		rootUri = "file://"+ rootPath;
    	if (copyDefault) {
			final File baseDir = appContext.getFilesDir();
			final File inPhoneWebui = new File(baseDir, WEBUI);
    		if (inPhoneWebui.isDirectory()) {
    			try {
    				// move copy db here so that 
    				// we could create db out of WebViewCache
					Util.copyFile(appContext.getDatabasePath(DB.DBNAME), 
							new File(webui, DB.DBNAME));
				} catch (IOException e) {
				}
    		}    		
    		Thread t = new Thread(new Runnable() {
    			public void run() {
    				try {
		        		if (inPhoneWebui.isDirectory()) {
		        			Util.copyDirectory(inPhoneWebui, webui);
		        			deleteAll();
		        			OpenFeintInternal.log(TAG, "copy in phone data finish");
		        			clientManifestReady();
		        		} else {
		        			OpenFeintInternal.log(TAG, "copy from asset");
		    				copyDefaultBackground(baseDir);
		        		}
					} catch (IOException e) {
	        			OpenFeintInternal.log(TAG, e.getMessage());
				        setRootUriInternal();
				        return;
					}
    			}
    		});
    		t.start();
    		return;
    	} else {
    		clientManifestReady();
    	}
    	
    	deleteAll();
	}
	
	public final void setRootUriInternal() {
		OpenFeintInternal.log(TAG, "can't use sdcard");
		final File baseDir = appContext.getFilesDir();
		File rootDir = new File(baseDir, WEBUI);
		rootPath = rootDir.getAbsolutePath() +"/";
		rootUri = "file://"+ rootPath;
		final File inPhoneWebui = new File(baseDir, WEBUI);
		boolean hasInPhoneData = inPhoneWebui.isDirectory();
		if (!hasInPhoneData) {
			Thread t = new Thread(new Runnable() {
				public void run() {
					copyDefaultBackground(baseDir);
				}
			});
			t.start();
		} else {
			clientManifestReady();
		}
	}
	
	public static final String getItemUri(String itemPath) {
		return rootUri + itemPath;
	}
	
	public static void start() {
	    sInstance.sync();
	}
	
	//PRIVATE API
	
	static WebViewCache sInstance;
	private static String rootUri;
	private static String rootPath;
	Handler mHandler;
	Set<PathAndCallback> trackedPaths;
	Map<String, ItemAndCallback> trackedItems;
	static final int kServerManifestReady = 0;
	static final int kDataLoaded = 1;
	static final int kClientManifestReady = 2;
	static boolean loadingFinished = false;
	WebViewCacheCallback delegate;
	ManifestData serverManifest;
	Map<String, String> clientManifest;
	Set<String> pathsToLoad;	
	Set<String> prioritizedPaths;  
	
	//determining state:
	//  not loaded manifest yet:    manifest == null, loadingFinished == NO
	//  manifest failed:  manifest == null, loadingFinished = YES
	//  in process of loading items, manifest != null, loadingFinished = NO
	//  all done loading manifest != null, loadinFinished = YES

	
	final URI serverURI = getServerURI();
	
	Context appContext;
	//INNER CLASSES
	private static class ManifestItem {
		public String path;
		public String hash;
		public Set<String> dependentObjects;
		ManifestItem(String _path, String _hash) { path = _path; hash = _hash; dependentObjects = new HashSet<String>(); }
		ManifestItem(ManifestItem item) {
			path = item.path;
			dependentObjects  = new HashSet<String>(item.dependentObjects);
		}
	}

	private static class ManifestData {
		Set<String> globals;
		Map<String, ManifestItem> objects;
		ManifestData(byte[] stm) throws Exception {
			String line;
			globals = new HashSet<String>();
			objects = new HashMap<String, ManifestItem>();
			ManifestItem item = null;			
			try {
				InputStreamReader reader = new InputStreamReader(new ByteArrayInputStream(stm));
				BufferedReader buffered = new BufferedReader(reader, 8192);
				while((line = buffered.readLine()) != null) {
					line = line.trim();
					if(line.length() == 0) continue;
					switch(line.charAt(0)) {
					case '#':
						//comment, do nothing
						break;
					case '-':
						if(item != null) {
							item.dependentObjects.add(line.substring(1).trim());
						} else {
							throw new Exception("Manifest Syntax Error: Dependency without an item");
						}
						break;
					default:
						String[] pieces = line.split(" ");
						String path;
						if(pieces.length >= 2) {
							if(pieces[0].charAt(0) == '@') {
								path = pieces[0].substring(1);
								globals.add(path);
							}
							else {
								path = pieces[0];
							}
							item = new ManifestItem(path, pieces[1]);
							objects.put(path, item);
						} else {
							throw new Exception("Manifest Syntax Error: Extra items in line");							
						}
						//new object
						break;
					}
				}	
			}  catch (Exception e) {
				throw new Exception(e);  //this will tell the loader it failed
			}
		}
	}
	//structures for use inside collections
	private static class ItemAndCallback {
		public final ManifestItem item;
		public final WebViewCacheCallback callback;
		public ItemAndCallback(ManifestItem _item, WebViewCacheCallback _cb) {
			item = _item;
			callback = _cb;
		}
	}
	
	private static class PathAndCallback {
		public final String path;
		public final WebViewCacheCallback callback;
		public PathAndCallback(String _path, WebViewCacheCallback _cb) {
			path = _path;
			callback = _cb;
		}
	}
	
	private boolean trackPathInner(String path, WebViewCacheCallback cb) {
		if(WebViewCache.loadingFinished) {
			cb.pathLoaded(path);
			return false;  //all done, so report as loaded
		}
		if(serverManifest == null) {
			cb.onTrackingNeeded();
			trackedPaths.add(new PathAndCallback(path, cb));  //store for later
			return true;
		}
		else {
			ManifestItem loadedItem = serverManifest.objects.get(path);
			if(loadedItem != null) {
				//this is in fact an item in the manifest
				cb.onTrackingNeeded();
				ManifestItem newItem = new ManifestItem(loadedItem);
				newItem.dependentObjects.retainAll(pathsToLoad);
				trackedItems.put(path, new ItemAndCallback(newItem, cb));
				return true;
			}
			else {
				//not in the manifest
				cb.pathLoaded(path);
				return false;
			}
			
		}
	}
	
	private boolean isLoadedInner(String path) {
		if(serverManifest == null) return WebViewCache.loadingFinished;  //if not loaded yet, say No, if no manifest was found say Yes
		if(pathsToLoad.contains(path)) return false;
		return true;
	}
	
	private WebViewCache(Context _appContext) {
		appContext = _appContext;
		trackedPaths = new HashSet<PathAndCallback>();
		trackedItems = new HashMap<String, ItemAndCallback>();
		pathsToLoad = new HashSet<String>();
		prioritizedPaths = new HashSet<String>();
		
		mHandler = new Handler() {
			@Override
			@SuppressWarnings("unchecked")
			public void dispatchMessage(Message msg) {
				//the message will contain things like server manifest loaded and item finished
				//forwards to appropriate method
				//this will send callbacks to the registered delegate
				switch(msg.what) {
				case kServerManifestReady:
					OpenFeintInternal.log(TAG, "kServerManifestReady");
					serverManifest = (ManifestData)msg.obj;
					triggerUpdates();
					break;
				case kDataLoaded:
					finishItem((String) msg.obj, msg.arg1 > 0);
					break;
				case kClientManifestReady:
					clientManifest = (Map<String, String>)msg.obj;
					triggerUpdates();
					break;
				}
			}
		};
		updateExternalStorageState();
	}
	
	private static final String OPENFEINT_ROOT = "openfeint";
	
	private void updateExternalStorageState() {
	    String state = Environment.getExternalStorageState();
	    if (Environment.MEDIA_MOUNTED.equals(state)) {
	    	File sdcard = Environment.getExternalStorageDirectory();
	    	File feintRoot = new File(sdcard, OPENFEINT_ROOT);
	    	setRootUriSdcard(feintRoot);	
	    } else {
	    	OpenFeintInternal.log(TAG, state);
	    	setRootUriInternal();
	    }
	}
	
	// TODO: delay get clientManifest till we have server update
	private void sync() {
		OpenFeintInternal.log(TAG, "--- WebViewCache Sync ---");
		//start loading the server manifest on a thread, it will call back to the handle
		ManifestRequest req = new ManifestRequest(ManifestRequestKey);
		req.launch();
	}

	private static final String ManifestRequestKey = "manifest";
	private class ManifestRequest extends CacheRequest {
		public ManifestRequest(String key) {
			super(key);
		}
		@Override public boolean signed() { return false; }
		@Override public String path() {
			return WebViewCache.getManifestPath(appContext);
		}
		@Override public void onResponse(int responseCode, byte[] body) {
			ManifestData data = null;
			if(responseCode == 200) {
				try {
					data = new ManifestData(body);
					super.on200Response();
				} catch (Exception e) {
					OpenFeintInternal.log(TAG, e.toString());
					//anything goes wrong, we just return a null input
				}
			}
			
			if (data != null) {
				Message msg = Message.obtain(mHandler, kServerManifestReady, data);
				msg.sendToTarget();
			} else {
				finishWithoutLoading();
			}
		}
	}

	
	private void deleteAll() {
		File baseDir = appContext.getFilesDir();
		File webui = new File(baseDir, WEBUI);
		Util.deleteFiles(webui);
		appContext.getDatabasePath(DB.DBNAME).delete();
	}

	private void gatherDefaultItems(String path, Set<String> items) {
		try {
			String [] stuff = appContext.getAssets().list(path);
			for(String s : stuff) {
				String fullpath = path + "/" + s;
				try {
					InputStream check = appContext.getAssets().open(fullpath);
					items.add(fullpath);
					check.close();
				}
				catch (IOException e) {
					//must not have been a file
					gatherDefaultItems(fullpath, items);
				}
			}
		} catch (IOException e) {
			OpenFeintInternal.log(TAG, e.toString());
		}

	}

	private void copySingleItem(File baseDir, String path) {
//		OpenFeintInternal.log(TAG, "Copy:" + path);
		try {
			File filePath = new File(baseDir, path);
			InputStream  inputStream = appContext.getAssets().open(path);
			DataInputStream reader = new DataInputStream(inputStream);
			
			filePath.getParentFile().mkdirs();
			FileOutputStream fileStream = new FileOutputStream(filePath);
			DataOutputStream writer = new DataOutputStream(fileStream);
			Util.copyStream(reader, writer);
		}
		catch(Exception e) {
			OpenFeintInternal.log(TAG, e.toString());
		}
	}
	
	private Set<String> stripUnused(Set<String>table) {
		String currentDpi = Util.getDpiName(appContext);
		String test = currentDpi.equals("mdpi") ? ".hdpi." : ".mdpi.";
		Set<String> reducedSet = new HashSet<String>();
		for(String path : table) {
			if(!path.contains(test)) reducedSet.add(path);
		}
		return reducedSet;
	}
	
	private void copySpecific(File baseDir, String path, Set<String> items) {
		if(items.contains(path)) {
			copySingleItem(baseDir, path);
			items.remove(path);
		}
	}
	
	private void copyDirectory(File baseDir, String root, Set<String> items) {
		Set<String> dirItems = new HashSet<String>();
		for(String path : items) {
			if(path.startsWith(root)) dirItems.add(path);
		}
		for(String path : dirItems) copySpecific(baseDir, path, items);
	}
	
	//TODO: prioritize the manifest and introflow loading
	private void copyDefaultBackground(File baseDir) {
		Set<String> defaultItems = new HashSet<String>();
		gatherDefaultItems(WEBUI, defaultItems);
		defaultItems = stripUnused(defaultItems);
		copySpecific(baseDir, "webui/manifest.plist", defaultItems);
		copyDirectory(baseDir, "webui/javascripts/", defaultItems);
		copyDirectory(baseDir, "webui/stylesheets/", defaultItems);
		copyDirectory(baseDir, "webui/intro/", defaultItems);
		if(Util.getDpiName(appContext).equals("mdpi")) {
			copySpecific(baseDir, "webui/images/space.grid.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.gray.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.gray.hit.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.green.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.green.hit.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/logo.small.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/header_bg.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/loading.spinner.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/input.text.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/frame.small.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/icon.leaf.gray.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/tab.divider.mdpi.png", defaultItems);			
			copySpecific(baseDir, "webui/images/tab.active_indicator.mdpi.png", defaultItems);
			
			copySpecific(baseDir, "webui/images/logo.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/header_bg.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/loading.spinner.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/icon.user.male.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.leaderboards.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.friends.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.achievements.mdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.games.mdpi.png", defaultItems);

		}
		else {
			copySpecific(baseDir, "webui/images/space.grid.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.gray.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.gray.hit.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.green.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/button.green.hit.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/logo.small.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/header_bg.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/loading.spinner.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/input.text.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/frame.small.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/icon.leaf.gray.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/tab.divider.hdpi.png", defaultItems);			
			copySpecific(baseDir, "webui/images/tab.active_indicator.hdpi.png", defaultItems);			
			
			copySpecific(baseDir, "webui/images/logo.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/header_bg.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/loading.spinner.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/icon.user.male.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.leaderboards.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.friends.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.achievements.hdpi.png", defaultItems);
			copySpecific(baseDir, "webui/images/intro.games.hdpi.png", defaultItems);
		}
		clientManifestReady();
		
		for(String path : defaultItems) {
			copySingleItem(baseDir, path);
		}
	}
	
	private void clientManifestReady() {
		Object obj = getDefaultClientManifest();
		if (obj == null) return;
		Message msg = Message.obtain(mHandler, kClientManifestReady);
		msg.obj = obj;
		msg.sendToTarget();		
	}
	
	private class SaxHandler extends DefaultHandler {
		String loadingString;
		String key;
		Map<String, String> outputMap = new HashMap<String, String>();
		public Map<String, String> getOutputMap() { return outputMap; }
		@Override
		public void startElement(String uri, String name, String qName, Attributes attr) {
			loadingString = "";
		}
		@Override
		public void endElement(String uri, String name, String qName) {
			String clipped = name.trim();
			if(clipped.equals("key")) key = loadingString;
			else if(clipped.equals("string")) {
				outputMap.put(key, loadingString);
				DB.insertManifest(new String[]{ key, loadingString} );
			}
		}
		@Override
		public void characters(char ch[], int start, int length) {
			loadingString = new String(ch).substring(start, start + length);
		}
	}
	
	static boolean recover() {
		return sInstance.recoverInternal();
	}
	
	boolean recoverInternal() {
		boolean success = DB.recover(appContext);
		serverManifest = null;
		if (success) {
		    clientManifest = getDefaultClientManifestFromAsset();
		    success = clientManifest != null;
		}
		loadingFinished = false;
		sync();
		return success;
	}
	
	// This doesn't throw.  It'll return an empty manifest if there's a problem.
	private Map<String, String> getDefaultClientManifest() {
		Cursor result = null;
		SQLiteDatabase db = null;
		try {
			DB.createDB(appContext);
			db = DB.storeHelper.getReadableDatabase();
			result = db.rawQuery("SELECT * FROM manifest", null);
			if(result.getCount() > 0) {
				//database exists, use it
				final Map<String, String> outManifest =  new HashMap<String, String>();
				result.moveToFirst();
				do {
					String path = result.getString(0);
					String hash = result.getString(1);
					outManifest.put(path, hash);
				} while (result.moveToNext());
				result.close();
				OpenFeintInternal.log(TAG, "create client Manifest from db");
				return outManifest;
			}
		} catch (Exception e) {
			// Some SQLite exception, doesn't matter.  We'll fall through and return the asset manifest.
			OpenFeintInternal.log(TAG, "SQLite exception. " + e.toString()); // @TEMP
		} finally {
			OpenFeintInternal.log(TAG, "Closing db."); // @TEMP
			try { result.close(); } catch (Exception jeez) {}
			try { db.close(); } catch (Exception whatever_man) {}
		}
			
		return getDefaultClientManifestFromAsset();
	}
	
	// This doesn't throw.  It'll return an empty manifest if there's a problem.
	private Map<String, String> getDefaultClientManifestFromAsset() {
		//read from the file
		File manifestFile = new File(rootPath, "manifest.plist");
		if(manifestFile.isFile()) {
			try {
				SAXParserFactory spf = SAXParserFactory.newInstance();
				SAXParser sp = spf.newSAXParser();
				XMLReader xr = sp.getXMLReader();
				SaxHandler handler = new SaxHandler();
				xr.setContentHandler(handler);
				InputStream  inputStream = new FileInputStream(manifestFile.getPath());
				xr.parse(new InputSource(inputStream));
				return handler.getOutputMap();
			}
			catch(Exception e) {
				OpenFeintInternal.log(TAG, e.toString());
			}
		}
		return new HashMap<String, String>();
	}
	static private final URI getServerURI() {
		try {
			if(serverOverride != null) return serverOverride;
			return new URI(OpenFeintInternal.getInstance().getServerUrl());
		} catch(Exception e) {
			return null;
		}
	}
	
	
	static private final String getManifestPath(Context ctx) {
	  String prefix = "/webui/manifest/android";
	  
		if(manifestPrefixOverride != null) prefix = manifestPrefixOverride;
		
		return prefix + "." + Util.getDpiName(ctx);
	}
	
	
	private void triggerUpdates() {
		
		OpenFeintInternal.log(TAG, "loadedManifest");

		// If both the server and client manifest are ready, we'll go.  If not, we'll wait on the other.
		if(serverManifest != null && clientManifest != null) {
			//set up the itemsToLoad from the manifest 
			for(ManifestItem item : serverManifest.objects.values()) {
				if(!item.hash.equals(clientManifest.get(item.path))) {
					pathsToLoad.add(item.path);
				}
			}
			//now scan the trackedPath items and callback any that aren't being loaded
			//this is done second pass so it will find already loaded items or ones not in manifest
			HashSet<String> removedPaths = new HashSet<String>();
			for(PathAndCallback pathAndCb : trackedPaths) {
				if(!pathsToLoad.contains(pathAndCb.path)) {
					pathAndCb.callback.pathLoaded(pathAndCb.path);
					removedPaths.add(pathAndCb.path);
				}
				else {
					//still needs loading, move to the item tracking
					ManifestItem item = serverManifest.objects.get(pathAndCb.path);
					ManifestItem newItem = new ManifestItem(item);
					newItem.dependentObjects.retainAll(pathsToLoad);
					trackedItems.put(pathAndCb.path, new ItemAndCallback(newItem, pathAndCb.callback));
				}
			}
			trackedPaths.clear();	
			serverManifest.globals.retainAll(pathsToLoad);  //if they aren't loading, we don't care about the global
						
			//now check the prioritized items and add any dependencies
			Set<String> priorityDependents = new HashSet<String>();
			for(String path : prioritizedPaths) {
				if(!pathsToLoad.contains(path)) continue;
				ManifestItem item = serverManifest.objects.get(path);
				if(item != null) {
					priorityDependents.addAll(item.dependentObjects);
				}
			}
			priorityDependents.retainAll(pathsToLoad);  //keep only the ones we really want
			prioritizedPaths.addAll(priorityDependents);
			
			loadNextItem();
		}
	}
	
	private void finishWithoutLoading() {
		OpenFeintInternal.log(TAG, "finishWithoutLoading");

		//no manifest, so tell anyone waiting we are finished
		for(PathAndCallback pathAndCb : trackedPaths) {
			pathAndCb.callback.pathLoaded(pathAndCb.path);
		}
		trackedPaths.clear();
		finishLoading();
	}
	
	private void finishLoading() {
		WebViewCache.loadingFinished = true;
	}
	
	private void loadNextItem() {
		OpenFeintInternal.log(TAG, "loadNextItem");

		String path = null;
		serverManifest.globals.retainAll(pathsToLoad);  //cleanup of anything not in the loading item list
		prioritizedPaths.retainAll(pathsToLoad);  //technically, this should be redundant, but I'm being defensive
		
		if(serverManifest.globals.size() > 0) {
			path = serverManifest.globals.iterator().next();
		}
		else if(prioritizedPaths.size() > 0) {
			path = prioritizedPaths.iterator().next();
		}			
		else if(pathsToLoad.size() > 0) {
			path = pathsToLoad.iterator().next();
			//read path from the objectsToLoad list
		}
		else {
			finishLoading();
			return;
		}

	    final String finalPath = path;
	    OpenFeintInternal.log(TAG, "Syncing item: "+ finalPath);
	    
		new BaseRequest() {
			@Override public boolean signed() { return false; }
			@Override public String method() { return "GET"; }
			@Override public String path() { return "/webui/" + finalPath; }
			@Override public void onResponse(int responseCode, byte[] body) {
				if(responseCode != 200) {
					Message msg = Message.obtain(mHandler, kDataLoaded, 0, 0, finalPath); 
					msg.sendToTarget();
					return;					
				}
				try {
					Util.saveFile(body, rootPath + finalPath);
				} catch (Exception e) {
					//anything goes wrong, just fail out
					Message msg = Message.obtain(mHandler, kDataLoaded, 0, 0, finalPath); 
					msg.sendToTarget();
					return;
				}
				//TODO:  handle thread interruptions?
				Message msg = Message.obtain(mHandler, kDataLoaded, 1, 0, finalPath); 
				msg.sendToTarget();
			}
		}.launch();
	}


	private void finishItem(String path, boolean succeeded) {
		if (serverManifest == null) return;
		//first pass, remove from items to load, and dependencies
		for(ItemAndCallback itemAndCb : trackedItems.values()) {
			itemAndCb.item.dependentObjects.remove(path);
		}
		pathsToLoad.remove(path);
		serverManifest.globals.remove(path);
		prioritizedPaths.remove(path);

		//second pass, send callbacks if a tracked item doesn't have anything more to load
		if(serverManifest.globals.size() == 0) {
			HashSet<String> pathsToRemove = new HashSet<String>();		
			for(ItemAndCallback itemAndCb: trackedItems.values()) {
				if(!pathsToLoad.contains(itemAndCb.item.path) && itemAndCb.item.dependentObjects.size() == 0) {
					pathsToRemove.add(itemAndCb.item.path);
					itemAndCb.callback.pathLoaded(itemAndCb.item.path);
				}
			}
			for(String removePath: pathsToRemove) {
				trackedItems.remove(removePath);
			}
		}
		//update local manifest
		String hashValue;
		if(succeeded) {
			hashValue = serverManifest.objects.get(path).hash;
		}
		else {
			hashValue = "FAILED";
			}
			
		clientManifest.put(path, hashValue);
		final String[] params = new String[] { path, hashValue };		
		DB.insertManifest(params);
		loadNextItem();
	}
	
	private void prioritizeInner(String path) {
		if(loadingFinished) return;  
		prioritizedPaths.add(path);
		if(serverManifest != null) {
			//have the manifest, so add all the dependencies			
			ManifestItem item = serverManifest.objects.get(path);
			if(item != null) {				
				Set<String> loadingDependents = new HashSet<String>(item.dependentObjects);
//				OpenFeintInternal.log("WebViewCache", "Dep:" + loadingDependents.toString());
//				OpenFeintInternal.log("WebViewCache", "TOTAL:" + pathsToLoad.toString());
				loadingDependents.retainAll(pathsToLoad);
				prioritizedPaths.addAll(loadingDependents);
				OpenFeintInternal.log("WebViewCache", "Prioritizing " + path + " deps:" + loadingDependents.toString());
			}
		}

	}	
}
