#ifndef JNIFeintHelper_h__
#define JNIFeintHelper_h__

#include "s3eExt_JNI.h"
#include <jni.h>

#include "OpenFeint.h"
#include "LicenseChecker.h"

class JNIHelper
{
private:
	static JNIHelper* instance;

	JNIEnv* g_Env;
	jobject m_Activity;	
	jclass m_ActivityClass;

	bool init();

	// open feint
	OpenFeintDelegate* feintDelegate;
	jmethodID OpenFeintInit;
	jmethodID OpenFeintDashboard;	
	jmethodID OpenFeintAchievement;
	jmethodID OpenFeintScore;
	static void userLoggedInCallback(JNIEnv* env, jobject obj);
	static void userLoggedOutCallback(JNIEnv* env, jobject obj);
	static void dashboardDidAppearCallback(JNIEnv* env, jobject obj);
	static void dashboardDidDisappearCallback(JNIEnv* env, jobject obj);
	static void dashboardWillAppearCallback(JNIEnv* env, jobject obj);	

	// Google license
	LicenseCheckerCallback* licenseCheckerCallback;
	jmethodID licenseCheck;
	jmethodID licenseActivationRemaining;
	static void licenseResult(JNIEnv* env, jobject obj, int result);	

	// error handling
	char* lastError;
	void setLastError(const char* msg);

public:
	static JNIHelper* getInstance();
	static bool startup();
	static void shutdown();

	JNIHelper();
	~JNIHelper();	

	// feint
	void setFeintDelegate(OpenFeintDelegate* feintDelegate);
	void callFeintInitialize(const char* name, const char* key, const char* secret, const char* id);
	void callFeintDashboard();

	void callUnlockAchievement(const char* id);
	void callSetHighScore(int64 score, const char* leaderboard);

	// Google license
	void setLicenseCheckerCallback(LicenseCheckerCallback* licenseCallback);
	void callLicenseCheck(const char* publicKey);
	int callGetActivationRemaining();

	const char* getLastError();
};

#endif // JNIFeintHelper_h__