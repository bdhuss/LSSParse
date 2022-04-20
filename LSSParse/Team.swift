//
//  Team.swift
//  LSSParse
//
//  Created by Bryan Huss on 4/17/22.
//

import Foundation

struct Team: Codable, Identifiable {
    let id: Int
    let name: String
    let members: [Player]
}
