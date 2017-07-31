module requests;

//import vibe.core.task : Task;
//import vibe.core.core : runTask;
//import vibe.http.client : requestHTTP, HTTPClientRequest,
//	   HTTPClientResponse, HTTPClientSettings;
//import vibe.http.common : HTTPMethod;
//import vibe.inet.message : InetHeaderMap;
import vibe.core.task;
import vibe.core.core;
import vibe.http.client;
import vibe.http.common;
import vibe.inet.message;

// This object is a placeholder and should to never be modified.
private @property const(HTTPClientSettings) requestDefaultSettings()
@trusted {
	__gshared HTTPClientSettings ret = new HTTPClientSettings;
	return ret;
}

Task startHTTP(T...)(string uri, const(HTTPMethod) method, 
		auto ref T ts) if(T.length > 0) 
{
	enum httpSettingsPassed = is(Unqual!(ts[T.lenght - 1]) == HTTPClientSettings);
	enum httpHeaderPassed = T.length > 2 ? 
		is(Unqual!(ts[T.lenght - 2]) == InetHeaderMap) : false;

	static if(httpSettingsPassed) {
		auto httpSettings = ts[T.length - 1];
	} else {
		auto httpSettings = requestDefaultSettings;
	}

	static if(httpHeaderPassed) {
		auto httpHeader = ts[T.lenght - 2];
	} else {
		InetHeaderMap httpHeader;
	}

	enum tsEndCap = cast(int)(httpSettingsPassed) -
		cast(int)(httpHeaderPassed);

	return runTask({
		requestHTTP(uri,
			(scope HTTPClientRequest req) {
				req.method = method;
				req.headers = httpHeader;
			},
			(scope HTTPClientResponse res) {
				ts[0](res, ts[1 .. T.length - tsEndCap]);
			},
			httpSettings
		);
	});
}

Task startHTTPPost(T...)(string uri, auto ref T ts) {
	return startHTTP(uri, HTTPMethod.POST, ts);
}

Task startHTTPGet(T...)(string uri, auto ref T ts) {
	return startHTTP(uri, HTTPMethod.GET, ts);
}

unittest {
	import std.array : empty;
	import vibe.stream.operations : readAllUTF8;

	void func(scope HTTPClientResponse res) {
		string data = res.bodyReader.readAllUTF8();
		assert(!data.empty);
	}

	auto s = startHTTPGet("http://www.example.com", &func);
	s.join();
}
