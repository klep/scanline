//
//  UIImageExtensions.swift
//  scanline
//
//  Created by Florian Dreier on 12/26/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    
    
    /// A JPEG representation of the image.
    func jpgRepresentation(withCreationDate date: Date?) -> Data? {
        if let tiff = self.tiffRepresentation(withCreationDate: date), let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .jpeg, properties: [:])
        }
        
        return nil
    }
    
    /// A TIFF representation of the image
    func tiffRepresentation(withCreationDate date: Date?) -> Data? {
        guard let date = date else { return self.tiffRepresentation }
        guard let tiffData = self.tiffRepresentation else { return nil }
        
        // Create the image somehow, load from file, draw into it...
        let source: CGImageSource = CGImageSourceCreateWithData(tiffData as CFData, nil)!
        
        // Get all the metadata in the image
        let metadata = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [AnyHashable: Any]
        
        // Make the metadata dictionary mutable so we can add properties to it
        var metadataAsMutable = metadata
        
        // Get existing exif data dictionary
        // if the image does not have an EXIF dictionary (not all images do), then create one for us to use
        var EXIFDictionary = (metadataAsMutable?[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any] ?? [AnyHashable: Any]()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        // Set DateTimeOriginal exif data
        EXIFDictionary[(kCGImagePropertyExifDateTimeOriginal as String)] = dateString
        // Set DateCreated exif data
        EXIFDictionary[(kCGImagePropertyExifDateTimeDigitized as String)] = dateString
        
        EXIFDictionary[(kCGImagePropertyTIFFDateTime as String)] = dateString
        
        // Add our modified EXIF data back into the image’s metadata
        metadataAsMutable?[(kCGImagePropertyExifDictionary as String)] = EXIFDictionary
        
        let UTI: CFString = CGImageSourceGetType(source)!
        let destinationData = CFDataCreateMutable(nil, 0)!
        let destination: CGImageDestination = CGImageDestinationCreateWithData(destinationData, UTI, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, source, 0, (metadataAsMutable as CFDictionary?))
        CGImageDestinationFinalize(destination)
        return destinationData as Data
    }
}
