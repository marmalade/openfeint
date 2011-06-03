#include "OpenFeint.h"
#include "JNIHelper.h"
#include "IwDebug.h"

JNIHelper* OpenFeint::getJNI()
{
	return JNIHelper::getInstance();
}

bool OpenFeint::initialize(const char* name, const char* key, const char* secret, const char* id, OpenFeintDelegate* delegate)
{	
	JNIHelper* jniHelper = getJNI();
	if (jniHelper)
	{
		jniHelper->setFeintDelegate(delegate);
		jniHelper->callFeintInitialize(name, key, secret, id);
		return true;
	}
	return false;
}

void OpenFeint::launchDashboard()
{
	JNIHelper* jniHelper = getJNI();
	if (jniHelper)
	{
		jniHelper->callFeintDashboard();
	}
	else
	{
		IwDebugTraceLinePrintf("Feint dashboard cannot be launched\n");
	}	
}

void OpenFeint::unlockAchievement(const char* id)
{
	JNIHelper* jniHelper = getJNI();
	if (jniHelper)
	{
		jniHelper->callUnlockAchievement(id);
	}
	else
	{
		IwDebugTraceLinePrintf("Feint achievement cannot be unlocked\n");
	}	
}

void OpenFeint::setHighScore(int score, const char* leaderboard)
{
	JNIHelper* jniHelper = getJNI();
	if (jniHelper)
	{
		jniHelper->callSetHighScore(score, leaderboard);
	}
	else
	{
		IwDebugTraceLinePrintf("Cannot set highscore\n");
	}	
}