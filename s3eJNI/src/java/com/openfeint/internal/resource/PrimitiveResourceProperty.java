package com.openfeint.internal.resource;

import java.io.IOException;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;

public abstract class PrimitiveResourceProperty extends ResourceProperty {
	abstract public void parse(Resource obj, JsonParser jp) throws JsonParseException, IOException;
	abstract public void generate(Resource obj, JsonGenerator generator) throws JsonGenerationException, IOException;
	abstract public void copy(Resource lhs, Resource rhs);
}
