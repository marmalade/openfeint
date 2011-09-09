//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#include "OFBinarySource.h"

OFImplementRTTI(OFBinarySource, OFSmartObject);
OFImplementRTTI(OFBinaryFileSource, OFBinaryMemorySource);
OFImplementRTTI(OFBinaryMemorySource, OFBinaryMemorySource);

OFBinaryFileSource::OFBinaryFileSource(const char* filePath)
{
	mFileStream = fopen(filePath, "rb+");
}

OFBinaryFileSource::~OFBinaryFileSource()
{
	fclose(mFileStream);
	mFileStream = NULL;
}

bool OFBinaryFileSource::isEmpty() const
{
	return feof(mFileStream);
}
	
void OFBinaryFileSource::read(void* data, unsigned int dataSize)
{
	fread(data, dataSize, 1, mFileStream);
}

// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------

OFBinaryMemorySource::OFBinaryMemorySource(const char* data, unsigned int dataSize)
: mData(data)
, mNumBytes(dataSize)
, mNextByte(0)
{
}

OFBinaryMemorySource::~OFBinaryMemorySource()
{
}

void OFBinaryMemorySource::read(void* data, unsigned int dataSize)
{
	unsigned int sizeToRead = dataSize;
	if(mNextByte + sizeToRead >= mNumBytes)
	{
		sizeToRead = mNumBytes - mNextByte;
	}
	
	memcpy(data, mData + mNextByte, sizeToRead);
	mNextByte += dataSize;
}

bool OFBinaryMemorySource::isEmpty() const
{
	return mNextByte >= mNumBytes;
}
