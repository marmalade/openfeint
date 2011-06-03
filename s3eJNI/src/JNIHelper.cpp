#include "JNIHelper.h"
#include "string.h"
#include "IwDebug.h"

JNIHelper* JNIHelper::instance = NULL;

JNIHelper* JNIHelper::getInstance()
{
	return instance;
}

bool JNIHelper::startup()
{
	IwDebugTraceLinePrintf("JNIHelper startup...");
	if (instance == NULL)
	{
		instance = new JNIHelper();
		if (!instance->init())
		{
			const char* lastError = instance->getLastError();
			IwDebugTraceLinePrintf("JNI failed: %s\n", lastError);
			shutdown();

			return false;
		}
	}
	return true;
}

void JNIHelper::shutdown()
{
	delete instance;
	instance = NULL;
}

JNIHelper::JNIHelper() :
	g_Env(0),
	OpenFeintInit(0),
	OpenFeintDashboard(0),		
	OpenFeintAchievement(0),
	OpenFeintScore(0),		
	m_Activity(0),
	m_ActivityClass(0),
	lastError(0),
	feintDelegate(0)
{
	instance = this;	
}

JNIHelper::~JNIHelper()
{
	if (g_Env && m_ActivityClass)
	{
		IwDebugTraceLinePrintf("Unregister feint helper native methods...");
		g_Env->UnregisterNatives(m_ActivityClass);
	}
	delete lastError;
}

void JNIHelper::setFeintDelegate(OpenFeintDelegate* feintDelegate)
{
	this->feintDelegate = feintDelegate;
}

bool JNIHelper::init()
{
	if (!s3eExtJNIAvailable())
    {
        setLastError("JNI Extension is not available");
        return false;
    }

	IwDebugTraceLinePrintf("s3eExtJNI available\n");

    //Get a pointer to the JVM using the JNI extension
    JavaVM* jvm = (JavaVM*)s3eJNIGetVM();

    if (!jvm)
    {
        setLastError("Unable to get JVM");
        return false;
    }

	IwDebugTraceLinePrintf("JVM available\n");

    //Get the environment from the pointer
    jvm->GetEnv((void**)&g_Env, JNI_VERSION_1_6);

    //Find the MainActivity class using the environment
    m_ActivityClass = g_Env->FindClass("com/mycompany/s3ejni/MainActivity");

    if (!m_ActivityClass)
    {
		setLastError("Unable to find the MainActivity class");
        return false;
    }

	IwDebugTraceLinePrintf("Activity class available\n");

    jfieldID fid = g_Env->GetStaticFieldID(m_ActivityClass, "m_Activity", "Lcom/mycompany/s3ejni/MainActivity;");
    if (!fid)
    {
		setLastError("Unable to get activity field m_Activity");
        return false;
    }

	IwDebugTraceLinePrintf("Activity static field available\n");

    m_Activity = g_Env->GetStaticObjectField(m_ActivityClass, fid);
    if (!m_Activity)
    {
        setLastError("Unable to get activity object m_Activity");
        return false;
    }

	IwDebugTraceLinePrintf("Activity object available\n");
	
	OpenFeintInit = g_Env->GetMethodID(m_ActivityClass, "initOpenFeint", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
	OpenFeintDashboard = g_Env->GetMethodID(m_ActivityClass, "openDashboard", "()V");
	OpenFeintAchievement = g_Env->GetMethodID(m_ActivityClass, "unlockAchievement", "(Ljava/lang/String;)V");
	OpenFeintScore = g_Env->GetMethodID(m_ActivityClass, "submitScore", "(Ljava/lang/String;J)V");
	licenseCheck = g_Env->GetMethodID(m_ActivityClass, "checkLicense", "(Ljava/lang/String;)V");	
	licenseActivationRemaining = g_Env->GetMethodID(m_ActivityClass, "getActivationRemainingTime", "()J");

	//Register the callback methods on the object
	const int nativeMethodsCount = 6;
    static const JNINativeMethod jnm[nativeMethodsCount] = 
	{
		{ "userLoggedIn", "()V", (void*)&userLoggedInCallback },
		{ "userLoggedOut", "()V", (void*)&userLoggedOutCallback },
		{ "dashboardWillAppear", "()V", (void*)&dashboardWillAppearCallback },
		{ "dashboardDidAppear", "()V", (void*)&dashboardDidAppearCallback },
		{ "dashboardDidDisappear", "()V", (void*)&dashboardDidDisappearCallback },
		{ "licenseResult", "(I)V", (void*)&licenseResult }
	};

    if (g_Env->RegisterNatives(m_ActivityClass, jnm, nativeMethodsCount))
    {
        setLastError("Could not register native methods");
        return false;
    }

	IwDebugTraceLinePrintf("Native methods registered\n");

	return true;
}

const char* JNIHelper::getLastError()
{
	return lastError == NULL ? "" : lastError;
}

void JNIHelper::setLastError(const char* msg)
{
	delete lastError;

	lastError = new char[strlen(msg) + 1];
	strcpy(lastError, msg);
}

void JNIHelper::callFeintInitialize(const char* name, const char* key, const char* secret, const char* id)
{
	jstring jAppName = g_Env->NewStringUTF(name);
	jstring jAppKey = g_Env->NewStringUTF(key);
	jstring jAppSecret = g_Env->NewStringUTF(secret);
	jstring jAppId = g_Env->NewStringUTF(id);

	g_Env->CallVoidMethod(m_Activity, OpenFeintInit, jAppName, jAppKey, jAppSecret, jAppId);

	g_Env->DeleteLocalRef(jAppName);
	g_Env->DeleteLocalRef(jAppKey);
	g_Env->DeleteLocalRef(jAppSecret);
	g_Env->DeleteLocalRef(jAppId);
}

void JNIHelper::callFeintDashboard()
{
	g_Env->CallVoidMethod(m_Activity, OpenFeintDashboard);
}

void JNIHelper::callUnlockAchievement(const char* id)
{
	jstring jAchievementId = g_Env->NewStringUTF(id);	
	g_Env->CallVoidMethod(m_Activity, OpenFeintAchievement, jAchievementId);
	g_Env->DeleteLocalRef(jAchievementId);
}

void JNIHelper::callSetHighScore(int64 score, const char* leaderboard)
{
	jlong jScore = jlong(score);
	jstring jLeaderboardId = g_Env->NewStringUTF(leaderboard);

	g_Env->CallVoidMethod(m_Activity, OpenFeintScore, jLeaderboardId, jScore);
	g_Env->DeleteLocalRef(jLeaderboardId);
}

void JNIHelper::userLoggedInCallback(JNIEnv* env, jobject obj)
{
	if (instance != NULL && instance->feintDelegate != NULL)
	{
		instance->feintDelegate->userLoggedIn();
	}	
}

void JNIHelper::userLoggedOutCallback(JNIEnv* env, jobject obj)
{
	if (instance != NULL && instance->feintDelegate != NULL)
	{
		instance->feintDelegate->userLoggedOut();
	}	
}

void JNIHelper::dashboardDidAppearCallback(JNIEnv* env, jobject obj)
{
	if (instance != NULL && instance->feintDelegate != NULL)
	{
		instance->feintDelegate->dashboardDidAppear();
	}	
}

void JNIHelper::dashboardDidDisappearCallback(JNIEnv* env, jobject obj)
{
	if (instance != NULL && instance->feintDelegate != NULL)
	{
		instance->feintDelegate->dashboardDidDisappear();
	}	
}

void JNIHelper::dashboardWillAppearCallback(JNIEnv* env, jobject obj)
{
	if (instance != NULL && instance->feintDelegate != NULL)
	{
		instance->feintDelegate->dashboardWillAppear();
	}	
}

void JNIHelper::licenseResult(JNIEnv* env, jobject obj, int result)
{
	if (instance != NULL && instance->licenseCheckerCallback != NULL)
	{
		LicenseCheckerCallback* licenseCallback = instance->licenseCheckerCallback;
		if (!result)
		{
			licenseCallback->allow();
			return;
		}			

		LicenseResult licenseRes = (LicenseResult) result;
		switch (licenseRes)
		{			
			case LICENSE_RESULT_UNDEFINED:
				break;

			case LICENSE_RESULT_ALLOWED:
			{
				licenseCallback->allow();
				break;
			}
			case LICENSE_RESULT_BLOCKED:
			{				
				licenseCallback->dontAllow();
				break;
			}
						
			case LICENSE_RESULT_ACTIVATION_TRIAL_ALLOWED:			
			case LICENSE_RESULT_ACTIVATION_TRIAL_EXPIRED:			
			case LICENSE_RESULT_OFFLINE_PERIOD_EXPRIES:			
			case LICENSE_RESULT_ERROR_INVALID_PACKAGE_NAME:			
			case LICENSE_RESULT_ERROR_NON_MATCHING_UID:			
			case LICENSE_RESULT_ERROR_NOT_MARKET_MANAGED:			
			case LICENSE_RESULT_ERROR_CHECK_IN_PROGRESS:			
			case LICENSE_RESULT_ERROR_INVALID_PUBLIC_KEY:			
			case LICENSE_RESULT_ERROR_MISSING_PERMISSION:		
			{				
				licenseCallback->licenseError(licenseRes);
				break;
			}
			default:
			{
				licenseCallback->licenseError(LICENSE_RESULT_ERROR_UNKNOWN);
				break;
			}
		}		
	}
}

int JNIHelper::callGetActivationRemaining()
{
	jlong jRemaining = g_Env->CallLongMethod(m_Activity, licenseActivationRemaining);
	return int(jRemaining);
}

void JNIHelper::setLicenseCheckerCallback(LicenseCheckerCallback* licenseCallback)
{
	licenseCheckerCallback = licenseCallback;
}

void JNIHelper::callLicenseCheck(const char* publicKey)
{
	jstring jPublicKey = g_Env->NewStringUTF(publicKey);
	g_Env->CallVoidMethod(m_Activity, licenseCheck, jPublicKey);

	jthrowable exc = g_Env->ExceptionOccurred();
	if (exc)
	{
		g_Env->ExceptionClear();		
	}
	g_Env->DeleteLocalRef(jPublicKey);
}