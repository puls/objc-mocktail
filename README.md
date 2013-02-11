# Mocktail

A simple(r) way to stub out HTTP servers in your Objective-C app.

## Features

- Only a hundred lines of code
- As simple as possible
- Slow!
	- Performance is `O(N)` for serving N mock responses!
	- Loads entire—potentially very large—files in to memory!
- Poorly tested
- Might crash on malformed input
- Kind of a hack

You shouldn't ship Mocktail with your code. It's a development tool.

## Usage

No, really, it's cool, you can still use it! You can read the entire source code in about five minutes to see what's going on. The entire API is a single method:

    + (void)startWithContentsOfDirectoryAtURL:(NSURL *)url;

All you do is put a bunch of files in a particular format (more on that later) and a `.tail` file extension in a directory and pass the URL of that directory to Mocktail. Et voilà.

The directory could be inside your app bundle (if you're supporting a test suite, say) or you could be really lazy about it if you're running in the simulator and just set the directory URL to a folder on your desktop.

## File format

I wish there were a standard for this, but alas, that's not to be the case. ([HAR](http://www.softwareishard.com/blog/har-12-spec/) thought it was going to be up to the task, but it's for forensic analysis of what happened during requests, not what came back.)

So we made one up. It's newline-delimited.

**Line 1** is a regular expression that matches the HTTP method. Something like `GET` or `GET|POST` or `.*` will work.

**Line 2** is a regular expression that matches the full URL of the HTTP request. So something like `http://yourserver.com:1234/very/specific/path\?param1=value1` or maybe just `/partial/path/to/something/.*` is fine too.

**Line 3** is the HTTP status code of the response. Probably `200`.

**Line 4** is the HTTP/MIME content type of the content. `application/json; charset=utf-8` is a nice value for this line, as is `text/html`. Various types of images might work, I haven't tried them.

**Line 5** is blank.

Everything after the newline ending line 5 (that is to say, line 6 and on) is sent back as the response body, verbatim. It doesn't even matter what the filename is. You just use one of these files per mock response "endpoint" and Mocktail loads them all in.

## Mad props

While `NSURLProtocol` has been around forever, its uses aren't obvious unless you read things like [@mattt](http://github.com/mattt)'s awesome [NSHipster blog post on the subject](http://nshipster.com/nsurlprotocol/). If you don't read NSHipster, you're missing out. It's great.

## Contributing

Your pull requests are welcome, but please don't take this too seriously. Remember, one of Mocktail's greatest features is its simplicity. Our lawyers want you to [sign this form](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1) first, too.