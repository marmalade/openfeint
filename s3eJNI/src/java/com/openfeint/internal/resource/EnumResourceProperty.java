package com.openfeint.internal.resource;

import java.io.IOException;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;

public abstract class EnumResourceProperty<T extends Enum<T>> extends PrimitiveResourceProperty {
	Class<T> mEnumClass;
	public EnumResourceProperty(Class<T> enumClass) {
		mEnumClass = enumClass;
	}

	@Override public void copy(Resource lhs, Resource rhs) {
		set(lhs, get(rhs));
	}

	abstract public void set(Resource obj, T val);
	public abstract T get(Resource obj);
	
	@Override
	public void parse(Resource obj, JsonParser jp) throws JsonParseException, IOException {
		set(obj, Enum.valueOf(mEnumClass, jp.getText()));
	}

	@Override public void generate(Resource obj, JsonGenerator generator) throws JsonGenerationException, IOException {
		T val = get(obj);
		generator.writeString(val.toString());
	}
}
