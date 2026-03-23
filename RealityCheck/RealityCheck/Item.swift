//
//  Item.swift
//  RealityCheck
//
//  Created by Nguyễn Hồng Quân on 23/3/26.
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
