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

#import "OFRetainedPtr.h"

class OFResourceDataMap : public OFSmartObject
{
public:
	struct FieldDescription
	{
		OFRetainedPtr<NSString> dataFieldName;
		SEL setter;
		SEL getter;
		Class resourceClass;
		bool isResourceArray;
		
		bool operator==(NSString* nameString) const
		{
			return [dataFieldName.get() isEqualToString:nameString];
		}
	};
	typedef std::vector<FieldDescription> FieldDescriptionSeries;
	
	void addField(NSString* name, SEL setter, SEL getter = nil);
	void addNestedResourceField(NSString* name, SEL setter, SEL getter, Class resourceClass);
	void addNestedResourceArrayField(NSString* name, SEL setter, SEL getter = nil);
	const OFResourceDataMap::FieldDescription* getFieldDescription(NSString* name) const;
	const OFResourceDataMap::FieldDescriptionSeries& getFieldDescriptions() const { return mFields; }
private:
	
	FieldDescriptionSeries mFields;
};
