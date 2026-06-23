//
//  FirestoreDateCodec.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreDateCodec {
    static func timestamp(from date: Date = .now) -> Timestamp {
        Timestamp(date: date)
    }

    static func date(from value: Any?) -> Date? {
        switch value {
        case let timestamp as Timestamp:
            return timestamp.dateValue()
        case let date as Date:
            return date
        case let string as String:
            return ISO8601DateFormatter().date(from: string)
        default:
            return nil
        }
    }

    static func isoString(from date: Date = .now) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
