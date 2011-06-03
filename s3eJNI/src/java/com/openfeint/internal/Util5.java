package com.openfeint.internal;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.Context;

/*
 * class to store code will call sdk 5 or above
 */
public class Util5 {
	public static String getAccountNameEclair(Context ctx) {
	  try {
	    AccountManager accountManager = AccountManager.get(ctx);
	    Account[] accounts = accountManager.getAccountsByType("com.google");
	    if(accounts.length > 0) {
	      return accounts[0].name;
	    }
	  } catch (Exception e) {
		OpenFeintInternal.log("Util5", e.getMessage());
	  }
	  return null;
	}
}
