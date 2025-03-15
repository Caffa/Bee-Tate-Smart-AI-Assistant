//
//  Item.swift
//  Bee Tate AI Assistant
//
//  Created by Pamela on 15/3/25.
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
