package com.openfeint.internal;

import java.util.HashMap;

/**
 * Temporary stop-gap "optimization" until we have proper offline support.
 */
public class AchievementUnlockCache {
	static private HashMap<String, Boolean> cache;
	
	public static boolean isUnlocked(String achievementId) {
		if (cache == null) cache = new HashMap<String, Boolean>();
		Boolean bool = cache.get(achievementId);
		return bool != null && bool.booleanValue() == true;
	}

	public static void markAsUnlocked(String achievementId) {
		if (cache == null) cache = new HashMap<String, Boolean>();
		cache.put(achievementId, new Boolean(true));
	}
	
	public static void reset() {
		if (cache == null) cache = new HashMap<String, Boolean>();
		cache.clear();
	}
}
