//
//  Player.swift
//  LSSParse
//
//  Created by Bryan Huss on 4/17/22.
//

import Foundation

struct Player: Codable, Identifiable {
    let id: Int
    let name: String
    let average: Int
    let isBookAverage: Bool
    let handicap: Int
    let ytdPinCount: Int
    let ytdGameCount: Int
    let series: Series
}
