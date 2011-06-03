#ifndef LicenseCheckerCallback_h__
#define LicenseCheckerCallback_h__

enum LicenseResult
{	
	/* No result yet */
	LICENSE_RESULT_UNDEFINED = -1,
	/* Application is licensed */
	LICENSE_RESULT_ALLOWED = 0,
	/* User must activate application withing some period */
	LICENSE_RESULT_ACTIVATION_TRIAL_ALLOWED = 1,
	/* Activation trial expired, user cannot access application */
	LICENSE_RESULT_ACTIVATION_TRIAL_EXPIRED = 2,
	/* Offline period expired, user must access network to check license */
	LICENSE_RESULT_OFFLINE_PERIOD_EXPRIES = 3,
	/* Don't allow license */
	LICENSE_RESULT_BLOCKED = 4,
	/* Package is not installed. */
	LICENSE_RESULT_ERROR_INVALID_PACKAGE_NAME = 5,
	/* Requested for a package that is not the current app. */
	LICENSE_RESULT_ERROR_NON_MATCHING_UID = 6,
	/* Market does not know about the package. */
	LICENSE_RESULT_ERROR_NOT_MARKET_MANAGED = 7,
	/* A previous check request is already in progress.
     * Only one check is allowed at a time. */
	LICENSE_RESULT_ERROR_CHECK_IN_PROGRESS = 8,
	/* Supplied public key is invalid. */
	LICENSE_RESULT_ERROR_INVALID_PUBLIC_KEY = 9,
	/* App must request com.android.vending.CHECK_LICENSE permission. */
	LICENSE_RESULT_ERROR_MISSING_PERMISSION = 10,
	/* Unknown error. */
	LICENSE_RESULT_ERROR_UNKNOWN = 11    
};

class LicenseCheckerCallback
{
public:
	virtual ~LicenseCheckerCallback() {}
	virtual void allow() = 0;
	virtual void dontAllow() = 0;
	virtual void licenseError(LicenseResult errorCode) = 0;
};

class LicenseChecker : public LicenseCheckerCallback
{
private:	
	LicenseResult licenseResult;	
	LicenseCheckerCallback* licenseCallback;

public:	
	LicenseChecker(LicenseCheckerCallback* licenseCallback);

	void checkLicense(const char* publicKey);
	int getActivationRemaining();
	void update();

	void allow();
	void dontAllow();
	void licenseError(LicenseResult errorCode);
};

#endif // LicenseCheckerCallback_h__