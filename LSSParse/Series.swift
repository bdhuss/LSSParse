//
//  Series.swift
//  LSSParse
//
//  Created by Bryan Huss on 4/17/22.
//

import Foundation

struct Series: Codable {
    let game1: Int
    let game1Absent: Bool
    let game2: Int
    let game2Absent: Bool
    let game3: Int
    let game3Absent: Bool
    let scratchTotal: Int
    let handicapTotal: Int
}
