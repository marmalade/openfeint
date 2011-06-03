package com.openfeint.internal.resource;

import java.io.IOException;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;
import org.codehaus.jackson.JsonToken;

public abstract class StringResourceProperty extends PrimitiveResourceProperty {
	abstract public void set(Resource obj, String val);
	public abstract String get(Resource obj);

	@Override public void copy(Resource lhs, Resource rhs) {
		set(lhs, get(rhs));
	}

	public void parse(Resource obj, JsonParser jp) throws JsonParseException, IOException {
		if (jp.getCurrentToken() == JsonToken.VALUE_NULL) {
			set(obj, null);
		} else {
			set(obj, jp.getText());
		}
	}
	

	@Override public void generate(Resource obj, JsonGenerator generator) throws JsonGenerationException, IOException {
		String o = get(obj);
		if (null != o) {
			generator.writeString(o);
		} else {
			generator.writeNull();
		}
	}
}
