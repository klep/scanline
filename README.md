scanline
========

scanline is a command-line scanning utility for MacOS X. It was originally built for my own quirky archiving system, where I scan every document (bills, tax forms, etc.) and categorize them into folders. Rather than use a traditional scanning program that requires time consuming pointing and clicking, I wanted something where I could easily scan from a command prompt.

scanline has evolved to support many different purposes and options. Some of the things you can do with scanline are:

* Run scanline as part of a script
* Scan batches of documents
* Scan from the document feeder or flatbed
* Scan in various formats, sizes, and modes all driven from command line options
* Provide defaults in a config file (~/.scanline.conf)

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

## Swift Rewrite

In December, 2017, the Swift rewrite of scanline was merged into `master`. Let me know if you experience any new issues.

## Installing scanline

You can download a signed, notarized installer from:

https://github.com/klep/scanline/blob/master/scanline-1.0.pkg?raw=true


## Contributing to scanline

scanline was a quick and dirty first project. While portions of the code have been rewritten more recently, a lot of it displays some pretty unevolved style. I welcome your pull requests, but please know what you're getting yourself into!

You can also contact me with any questions or suggestions and I'll do my best to work them in eventually.




