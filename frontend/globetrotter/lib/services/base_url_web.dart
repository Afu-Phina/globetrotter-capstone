// Used when compiling for web (browser). The browser runs on the same
// machine as the Flask dev server during development, so localhost works.
String resolveBaseUrl() => 'http://127.0.0.1:5000/api';
