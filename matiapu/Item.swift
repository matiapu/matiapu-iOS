//
//  Item.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
