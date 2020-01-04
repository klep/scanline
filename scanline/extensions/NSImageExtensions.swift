//
//  This code is part of scanline and published under MIT license.
//

import Foundation
import Cocoa

extension NSImage {
    
    /// The width of the image.
    var width: CGFloat {
        return size.width
    }
    
    /// The height of the image.
    var height: CGFloat {
        return size.height
    }
    
    /// Creates a new version of the image where the white right and bottom areas are removed
    func trimmed(withInsets insets: Insets?) -> NSImage {
        var rect = self.cropRect
        if let insets = insets {
            rect = rect.insetted(with: insets)
        }
        if let imageRef = self.crop(toRect: rect) {
            return imageRef
        }
        return self
    }
    
    /// Determines the rectangle that contains the actual image (ignoring white areas in the right and bottom areas)
    private var cropRect: CGRect {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        guard let provider = cgImage.dataProvider, let rawData = provider.data else { return CGRect.zero }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(rawData)
        
        let widthInt = Int(cgImage.width)
        let heightInt = Int(cgImage.height)
        
        var nonWhiteXCounter = Array(repeating: 0, count: widthInt)
        var nonWhiteYCounter = Array(repeating: 0, count: heightInt)
        
        // Filter through data and look for non-transparent pixels.
        for y in (0 ..< heightInt) {
            for x in (0 ..< widthInt) {
                let pixelIndex = (widthInt * y + x) * 4 /* 4 for A, R, G, B */
                
                if data[Int(pixelIndex)] == 0  { continue } // crop transparent
                
                if data[Int(pixelIndex+1)] > 0xD0 && data[Int(pixelIndex+2)] > 0xD0 && data[Int(pixelIndex+3)] > 0xD0 { continue } // crop white
                
                nonWhiteXCounter[x] = nonWhiteXCounter[x] + 1;
                nonWhiteYCounter[y] = nonWhiteYCounter[y] + 1;
            }
        }
        
        var highX = widthInt
        var highY = heightInt
        for x in (0 ..< widthInt).reversed() {
            if (nonWhiteXCounter.doesValueAroundIndexPassFivePercent(index: x, total: heightInt)) {
                highX = x
                break
            }
        }
        for y in (0 ..< heightInt).reversed() {
            if (nonWhiteYCounter.doesValueAroundIndexPassFivePercent(index: y, total: widthInt)) {
                highY = y
                break
            }
        }
        return CGRect(x: 0, y: 0, width: highX, height: highY)
    }
    
    /// Resize the image, to nearly fit the supplied cropping size
    /// and return a cropped copy the image.
    ///
    /// - Parameter size: The size of the new image.
    /// - Returns: The cropped image.
    func crop(toRect targetSize: CGRect) -> NSImage? {
        guard let imageRef = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let drawImage = imageRef.cropping(to: targetSize)
        return NSImage(cgImage: drawImage!, size: targetSize.size)
    }
    
    /// A JPEG representation of the image.
    func jpgRepresentation(withCreationDate date: Date?, quality: Double) -> Data? {
        if let tiff = self.tiffRepresentation(withCreationDate: date), let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .jpeg, properties: [.compressionFactor: quality])
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
