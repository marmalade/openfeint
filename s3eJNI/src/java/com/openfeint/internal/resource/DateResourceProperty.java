package com.openfeint.internal.resource;

import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.JsonParser;

public abstract class DateResourceProperty extends PrimitiveResourceProperty {
	public abstract void set(Resource obj, Date val);
	public abstract Date get(Resource obj);

	@Override public void copy(Resource lhs, Resource rhs) {
		set(lhs, get(rhs));
	}

	static DateFormat sDateParser = makeDateParser();
	
	static DateFormat makeDateParser()
	{ 
		DateFormat p = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		p.setTimeZone(TimeZone.getTimeZone("UTC"));
		return p;
	}

	@Override
	public void parse(Resource obj, JsonParser jp) throws JsonParseException, IOException {
		final String text = jp.getText();
		if (text.equals("null")) {
			set(obj, null);
		} else try {
			set(obj, sDateParser.parse(text));
		} catch (ParseException e) {
			set(obj, null);
		}
	}
	
	@Override public void generate(Resource obj, JsonGenerator generator) throws JsonGenerationException, IOException {
		Date o = get(obj);
		if (null != o) {
			generator.writeString(sDateParser.format(o));
		} else {
			generator.writeNull();
		}
	}
}
