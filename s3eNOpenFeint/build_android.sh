#!/bin/sh
# works only on mac.

export NDK_ROOT=/Volumes/mac_hd_2/Developer/android-ndk-r6b
export S3E_DIR=/Volumes/Macintosh\ HD/Developer/Marmalade/5.2/s3e
echo "Running ant to compile jar file"
ant
#/Developer/Marmalade/5.2/s3e/bin/mkb s3eNOpenFeint_android_java.mkb
if [[ $? -ne 0 ]]; then 
echo "Error in compiling JAVA Code"
exit 
fi

echo ****BUILDING DEBUG EXTENSION*****
/Volumes/Macintosh\ HD//Developer/Marmalade/5.2/s3e/bin/mkb --arm --debug --buildenv=scons s3eNOpenFeint_android.mkb
if [[ $? -ne 0 ]]; then 
echo "Error in building debug version of library.....Ignoring"
fi

echo ****BUILDING RELEASE EXTENSION*****
/Volumes/Macintosh\ HD//Developer/Marmalade/5.2/s3e/bin/mkb --arm --release --buildenv=scons s3eNOpenFeint_android.mkb
if [[ $? -ne 0 ]]; then 
echo "Error in building release version of library"
exit
fi
cp -f source/android/OpenFeint.jar lib/android/OpenFeint.jar
echo "*****BUILD COMPLETE*****"
