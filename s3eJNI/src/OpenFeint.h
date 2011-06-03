#ifndef OpenFeint_h__
#define OpenFeint_h__

class OpenFeintDelegate
{
public:
	virtual ~OpenFeintDelegate() {}
	virtual void userLoggedIn() = 0;
	virtual void userLoggedOut() = 0;

	virtual void dashboardWillAppear() = 0;	
	virtual void dashboardDidAppear() = 0;
	virtual void dashboardDidDisappear() = 0;	
};

class JNIHelper;

class OpenFeint
{
private:
	static JNIHelper* getJNI();

public:
	static bool initialize(const char* name, const char* key, const char* secret, const char* id, OpenFeintDelegate* delegate);	
	static void launchDashboard();

	static void unlockAchievement(const char* id);
	static void setHighScore(int score, const char* leaderboard);
};

#endif // OpenFeint_h__