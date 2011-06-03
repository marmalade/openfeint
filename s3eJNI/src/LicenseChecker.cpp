#include "LicenseChecker.h"
#include "JNIHelper.h"

LicenseChecker::LicenseChecker(LicenseCheckerCallback* licenseCallback) :
	licenseCallback(licenseCallback),
	licenseResult(LICENSE_RESULT_UNDEFINED)
{

}	

void LicenseChecker::checkLicense(const char* publicKey)
{
	JNIHelper* jniHelper = JNIHelper::getInstance();
	if (jniHelper != NULL)
	{
		jniHelper->setLicenseCheckerCallback(this);
		jniHelper->callLicenseCheck(publicKey);
	}
}

int LicenseChecker::getActivationRemaining()
{
	JNIHelper* jniHelper = JNIHelper::getInstance();
	if (jniHelper != NULL)
	{
		return jniHelper->callGetActivationRemaining();
	}
	return 0;
}

void LicenseChecker::update()
{
	// this is a dirty hack. s3e require no call to memory allocation while java function is called
	if (licenseResult != LICENSE_RESULT_UNDEFINED && licenseCallback != NULL)
	{
		switch (licenseResult)
		{		

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
				licenseCallback->licenseError(licenseResult);
				break;
			}
			default:
			{
				licenseCallback->licenseError(LICENSE_RESULT_ERROR_UNKNOWN);
				break;
			}
		}	
		
		licenseResult = LICENSE_RESULT_UNDEFINED;
	}
}

void LicenseChecker::allow()
{
	licenseResult = LICENSE_RESULT_ALLOWED;
}

void LicenseChecker::dontAllow()
{
	licenseResult = LICENSE_RESULT_BLOCKED;
}

void LicenseChecker::licenseError(LicenseResult errorCode)
{	
	licenseResult = errorCode;	
}