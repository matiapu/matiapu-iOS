//
//  MockImages.swift
//  matiapu
//

import Foundation

enum MockImages {
    static let postSamples: [String] = [
        "MockCity1",
        "MockCity2",
        "MockCity3",
        "MockCity4",
        "MockCity5",
    ]

    static func postImage(at index: Int) -> String {
        postSamples[index % postSamples.count]
    }
}
