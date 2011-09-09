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

#pragma once

#include "OFInputSerializer.h"
#include <cstdio>

class OFBinaryReader : public OFInputSerializer
{
OFDeclareRTTI;
public:
	OFBinaryReader(const char* filePath);
	~OFBinaryReader();

	bool supportsKeys() const;
	
private:
	void nviIo(OFISerializerKey* keyName, bool& value)				{ if(mFileStream) fread(&value, sizeof(value), 1, mFileStream); } 
	void nviIo(OFISerializerKey* keyName, int& value)				{ if(mFileStream) fread(&value, sizeof(value), 1, mFileStream); }
	void nviIo(OFISerializerKey* keyName, unsigned int& value)	{ if(mFileStream) fread(&value, sizeof(value), 1, mFileStream); }
	void nviIo(OFISerializerKey* keyName, float& value)			{ if(mFileStream) fread(&value, sizeof(value), 1, mFileStream); }
	void nviIo(OFISerializerKey* keyName, double& value)			{ if(mFileStream) fread(&value, sizeof(value), 1, mFileStream); }
	void nviIo(OFISerializerKey* keyName, std::string& value)
	{
		if(mFileStream) 
		{
			int stringLength = 0;
			fread(&stringLength, sizeof(stringLength), 1, mFileStream);

			std::auto_ptr<char> byteStream(new char[stringLength + 1]);
			byteStream.get()[stringLength] = '\0';
			fread(byteStream.get(), stringLength, 1, mFileStream);
			
			value = std::string(byteStream.get());
		}	
	}

	void nviIo(OFISerializerKey* keyName, OFRetainedPtr<NSString>& value)
	{ 
		if(mFileStream) 
		{
			int stringLength = 0;
			fread(&stringLength, sizeof(stringLength), 1, mFileStream);

			std::auto_ptr<char> byteStream(new char[stringLength + 1]);
			byteStream.get()[stringLength] = '\0';
			fread(byteStream.get(), stringLength, 1, mFileStream);
			
			value.reset([NSString stringWithCString:byteStream.get() encoding:NSStringEncodingConversionExternalRepresentation]);
		}
	}

	const OFRTTI* beginDecodeType();
	void endDecodeType();	
	void beginEncodeType(const OFRTTI* typeToEncode);
	void endEncodeType();

	FILE* mFileStream;
};
