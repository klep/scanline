scanline
========

scanline is a command-line scanning utility for MacOS X. It was originally built for my own quirky archiving system, where I scan every document (bills, tax forms, etc.) and categorize them into folders. Rather than use a traditional scanning program that requires time consuming pointing and clicking, I wanted something where I could easily scan from a command prompt.

scanline has evolved to support many different purposes and options. Some of the things you can do with scanline are:

* Run scanline as part of a script
* Scan batches of documents
* Scan from the document feeder or flatbed
* Scan in various formats, sizes, and modes all driven from command line options
* Provide defaults in a config file (~/.scanline.conf)
* Convert the scanned document to text (-ocr)
* Summarize and automatically name scans using on-device AI (-autoname and -summarize)

Here are some example command lines:

```
scanline -duplex taxes
   ^-- Scan 2-sided and place in /Users/klep/Documents/Archive/taxes/
scanline bills dental
   ^-- Scan and place in /Users/klep/Documents/Archive/bills/ with alias in /Users/klep/Documents/Archive/dental/
```
   
You can see all of scanline's options by typing:

```
scanline -help
```

## Installing scanline

You can download a signed, notarized installer from:

https://github.com/klep/scanline/blob/master/scanline-2.2.pkg?raw=true

## Building Your Own Installer

The bundled installer is signed and notarized by Boat Launch, Inc., a company founded by the author and maintainer of scanline. This is provided merely a convenience, and you are welcome to build and sign your own installer if you wish. 

I used the instructions at https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/ 

Note that, of course, you'll need to set your own Team / Bundle ID / Certificate

## libscanline

In early 2022, scanline was refactored to separate out the core functionality from the command line interface. libscanline is a macOS framework that can be embedded in any application that wants to easily support the functionality of scanline. 

To build libscanline:

xcodebuild clean build -project scanline.xcodeproj -scheme libscanline -configuration Release -sdk macosx11.3 -derivedDataPath derived_data BUILD_LIBRARY_FOR_DISTRIBUTION=YES

The project is structured so that the command line tool is a separate target that also includes all of the source files from libscanline. Ideally, it would simply embed libscanline, but that would require making the command line tool part of an app bundle, or dynamically linking to libscanline.


## Contributing to scanline

If you're interested in making a change, fix, or enhancement to scanline, please do! I'd appreciate a heads up on any bigger changes, and I'm happy to review any PRs.

You can also contact me with any questions or suggestions and I'll do my best to work them in eventually.




