//
//  BowlingEvent.swift
//  LSSParse
//
//  Created by Bryan Huss on 4/17/22.
//

import Foundation

struct BowlingEvent: Codable, Identifiable {
    let id: String
    let date: String
    let teams: [Team]
}
