//
//  MapCategoryStyle.swift
//  matiapu
//

import SwiftUI
import UIKit

extension MapFilter {
    var glyph: String {
        switch self {
        case .disaster: return "🔥"
        case .road: return "🚗"
        case .shop: return "🏪"
        case .bulletin: return "📞"
        }
    }

    var pinUIColor: UIColor {
        switch self {
        case .disaster: return UIColor(red: 0.545, green: 0.271, blue: 0.075, alpha: 1)
        case .road: return UIColor(red: 1.0, green: 0.549, blue: 0.0, alpha: 1)
        case .shop: return UIColor(red: 0.180, green: 0.545, blue: 0.341, alpha: 1)
        case .bulletin: return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
        }
    }

    var pinColor: Color {
        Color(pinUIColor)
    }

    static func from(tag: String) -> MapFilter? {
        allCases.first { $0.title == tag }
    }

    static func resolved(for tag: String) -> MapFilter {
        from(tag: tag) ?? .disaster
    }
}

enum MapCategoryStyle {
    static let defaultPinUIColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
    static let defaultPinColor = Color(defaultPinUIColor)
    static let defaultGlyph = "？"
    static let allFilterUIColor = defaultPinUIColor
    static let allFilterColor = defaultPinColor
}

enum MapPinMarkerFactory {
    static let markerSize = CGSize(width: 44, height: 52)
    static let selectedScale: CGFloat = 1.28
    static let selectionAnimationDuration: TimeInterval = 0.28

    static func makeIcon(for filter: MapFilter, isSelected: Bool = false) -> UIImage {
        makeIcon(backgroundColor: filter.pinUIColor, glyph: filter.glyph, isSelected: isSelected)
    }

    static func makeIcon(forTag tag: String, isSelected: Bool = false) -> UIImage {
        if let filter = MapFilter.from(tag: tag) {
            return makeIcon(for: filter, isSelected: isSelected)
        }

        return makeIcon(
            backgroundColor: MapCategoryStyle.defaultPinUIColor,
            glyph: MapCategoryStyle.defaultGlyph,
            isSelected: isSelected
        )
    }

    private static func makeIcon(backgroundColor: UIColor, glyph: String, isSelected: Bool) -> UIImage {
        drawIcon(backgroundColor: backgroundColor, glyph: glyph, isSelected: isSelected)
    }

    private static func drawIcon(backgroundColor: UIColor, glyph: String, isSelected: Bool) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: markerSize)

        return renderer.image { _ in
            let headRect = CGRect(x: 2, y: 2, width: 40, height: 40)
            let headPath = UIBezierPath(ovalIn: headRect)
            backgroundColor.setFill()
            headPath.fill()

            UIColor.white.setStroke()
            headPath.lineWidth = isSelected ? 3 : 2
            headPath.stroke()

            let pointPath = UIBezierPath()
            pointPath.move(to: CGPoint(x: markerSize.width / 2, y: markerSize.height - 1))
            pointPath.addLine(to: CGPoint(x: 14, y: 36))
            pointPath.addLine(to: CGPoint(x: 30, y: 36))
            pointPath.close()
            backgroundColor.setFill()
            pointPath.fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
            ]
            let text = glyph as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (markerSize.width - textSize.width) / 2,
                y: 12,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
