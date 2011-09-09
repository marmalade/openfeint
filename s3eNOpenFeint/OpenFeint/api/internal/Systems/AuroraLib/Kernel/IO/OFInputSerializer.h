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

#include "OFISerializer.h"

class OFInputSerializer : public OFISerializer
{
OFDeclareRTTI;
public:
	template <typename OtherType>
	std::auto_ptr<OtherType> loadInstance(const char* keyName)
	{
		Scope scope(this, keyName);
		std::auto_ptr<OtherType> instance(new OtherType(this));
		return instance;
	}

	bool isReading() const { return true; }
};
