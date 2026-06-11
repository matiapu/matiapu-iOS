//
//  PhotoLocationExtractor.swift
//  matiapu
//

import CoreLocation
import ImageIO
import UIKit

enum PhotoLocationExtractor {
    static func coordinate(from pickerInfo: [UIImagePickerController.InfoKey: Any]) -> CLLocationCoordinate2D? {
        if let metadata = pickerInfo[.mediaMetadata] as? [String: Any],
           let coordinate = coordinate(fromImageProperties: metadata) {
            return coordinate
        }

        if let image = pickerInfo[.originalImage] as? UIImage {
            return coordinate(from: image)
        }

        return nil
    }

    static func coordinate(from image: UIImage) -> CLLocationCoordinate2D? {
        guard let data = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        return coordinate(fromImageProperties: properties)
    }

    private static func coordinate(fromImageProperties properties: [String: Any]) -> CLLocationCoordinate2D? {
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }

        return parseGPSDictionary(gps)
    }

    private static func parseGPSDictionary(_ gps: [String: Any]) -> CLLocationCoordinate2D? {
        guard let latitude = parseGPSComponent(
            value: gps[kCGImagePropertyGPSLatitude as String],
            direction: gps[kCGImagePropertyGPSLatitudeRef as String]
        ),
        let longitude = parseGPSComponent(
            value: gps[kCGImagePropertyGPSLongitude as String],
            direction: gps[kCGImagePropertyGPSLongitudeRef as String]
        ) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private static func parseGPSComponent(value: Any?, direction: Any?) -> Double? {
        let numericValue: Double?
        if let number = value as? NSNumber {
            numericValue = number.doubleValue
        } else if let double = value as? Double {
            numericValue = double
        } else {
            return nil
        }

        guard var coordinate = numericValue else { return nil }

        if let direction = direction as? String {
            switch direction.uppercased() {
            case "S", "W":
                coordinate *= -1
            default:
                break
            }
        }

        return coordinate
    }
}
