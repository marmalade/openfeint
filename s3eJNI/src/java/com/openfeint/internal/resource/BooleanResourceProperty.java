package com.openfeint.internal.resource;

import java.io.IOException;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;
import org.codehaus.jackson.JsonToken;

public abstract class BooleanResourceProperty extends PrimitiveResourceProperty {
	public abstract void set(Resource obj, boolean val);
	public abstract boolean get(Resource obj);

	@Override public void copy(Resource lhs, Resource rhs) {
		set(lhs, get(rhs));
	}

	@Override
	public void parse(Resource obj, JsonParser jp) throws JsonParseException, IOException {
		if (jp.getCurrentToken() == JsonToken.VALUE_TRUE || jp.getText().equalsIgnoreCase("true") || jp.getText().equalsIgnoreCase("1")  || jp.getText().equalsIgnoreCase("YES"))
			set(obj, true);
		else
			set(obj, false);
	}
	
	@Override public void generate(Resource obj, JsonGenerator generator) throws JsonGenerationException, IOException {
		generator.writeBoolean(get(obj));
	}

}
