s3eNOFSettingVal *settings = (s3eNOFSettingVal*)s3eMalloc(sizeof(s3eNOFSettingVal) * 6);
		// Fill settings
		// UIOrientation value
		strncpy(settings[0].m_varName,
				"OpenFeintSettingDashboardOrientation",
					S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[0].m_intVal = s3eNOFUIInterfaceOrientationPortrait;
		
		
		// Shortdisplay name
		strncpy(settings[1].m_varName, 
				"OpenFeintSettingShortDisplayName", 
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		strncpy(settings[1].m_stringVal, 
				"FunkyRacers", 
				S3E_NOPENFEINT_STRING_MAX);
		
		// Push Notification Setting
		strncpy(settings[2].m_varName,
				"OpenFeintSettingEnablePushNotifications",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[2].m_intVal = 1; // TRUE/YES
		
		
		// Sandbox Notification Mode
		strncpy(settings[3].m_varName,
				"OpenFeintSettingUseSandboxPushNotificationServer",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[3].m_intVal = 1;
		

		// Disable User generated content
		strncpy(settings[4].m_varName,
				"OpenFeintSettingDisableUserGeneratedContent",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[4].m_intVal = 0;
		
		// Disable ask for approval in debug mode
		strncpy(settings[5].m_varName,
				"OpenFeintSettingAlwaysAskForApprovalInDebug",
				S3E_NOPENFEINT_SETTINGS_STRING_MAX);
		settings[5].m_intVal = 0;
		
		
		
		s3eNOFArray array;
		array.m_count = 6;
		array.m_items = settings;
		s3eNOFinitializeWithProductKey("TD5741bq5dsEWStKk3rdMA",
									   "HgjtDJBBRW8sBfASq9Iv6hDAfchXAHMYJvNU5gQ0",
									   "RacingGame",
									   &array);
		s3eFree(settings);
