//
//  main.swift
//  LSSParse
//
//  Created by Bryan Huss on 4/16/22.
//

import ArgumentParser
import Foundation
//import OpenGL


struct LSSParse: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Parse flat LSS (League Standing Sheet) data from TEXT to JSON")
    
    @Option(name: [.short, .customLong("input")], help: "Input TXT file")
    var inputFile: String
    
    @Option(name: [.short, .customLong("output")], help: "Output JSON file")
    var outputFile: String
    
//    @Flag(name: .shortAndLong, help: "Input file is from a Split-Season")
//    var splitSeason: Bool = false
    
    @Flag(name: .shortAndLong, help: "Print status updates while parsing")
    var verbose: Bool = false
    
    // === MAIN ===
    func run() throws {
        isVerbose("=============== LLSParse ===============")
        
        guard let input = try? String(contentsOfFile: inputFile) else {
            throw RuntimeError("Couldn't read from '\(inputFile)'!")
        }
        isVerbose("> Read contents of \(inputFile)")
        
        let allLines = input.components(separatedBy: .newlines)
        
        var teams: [Team] = []
        var players: [Player] = []
        
        var tempTeamID: Int = 0
        var tempTeamName: String = ""
        
        // lines 1 & 2 are week# and date respectively
        isVerbose("> Starting to processes \(inputFile)...")
        for fileIndex in 2..<allLines.count {
            let currentLine = allLines[fileIndex].components(separatedBy: .whitespaces)
            
            // Step 1: check if current line is a TEAM
            if currentLine[1] == "-" {
                // if we already have processed one team, assign temps to object and clear values
                if tempTeamID > 0 {
                    isVerbose("> Assigning '\(tempTeamID) - \(tempTeamName)' to TEAMS")
                    teams.append(Team(id: tempTeamID, name: tempTeamName, members: players))
                    isVerbose("> Clearing temporary TEAM & PLAYER data")
                    players.removeAll()
                    tempTeamName = ""
                }
                
                // parse and assign current TEAM data
                tempTeamID = Int(currentLine[0]) ?? 0
                tempTeamName = currentLine[2]
                
                for lineIndex in 3..<currentLine.count {
                    tempTeamName = "\(tempTeamName) \(currentLine[lineIndex])"
                }
                isVerbose("[\(fileIndex):\(allLines.count)] TEAM started: '\(tempTeamID) - \(tempTeamName)'")
            } else {
                let tempPlayerID = Int(currentLine[0]) ?? 0 //Player ID's start at 1 and go upwards as they are entered into the league
                var tempPlayerName = currentLine[1] // Player names will start as second item in array
                var tempPlayerAverage = 0
                var tempIsBookAverage = false
                var tempPlayerHandicap = 0
                var tempYTDPinCount = 0
                var tempYTDGameCount = 0
                var tempSeriesGame1 = 0
                var tempSeriesGame1Absent = false
                var tempSeriesGame2 = 0
                var tempSeriesGame2Absent = false
                var tempSeriesGame3 = 0
                var tempSeriesGame3Absent = false
                var tempSeriesScratchTotal = 0
                var tempSeriesHandicapTotal = 0
                
                // keeps appending the name until it reaches an Int, which will be the start of the player's average
                var endOfNameIndex = 0
                for lineIndex in 2..<currentLine.count {
                    let tempString = currentLine[lineIndex]
                    
                    if tempString.hasPrefix("bk") { // check for prefix 'bk' which indicates a book average
                        let truncated = tempString.dropFirst(2)
                        tempPlayerAverage = Int(truncated) ?? 0
                        tempIsBookAverage = true
                        endOfNameIndex = lineIndex
                        break
                    }
                    
                    if let tempInt = Int(currentLine[lineIndex]) { // if parse fails, we are still handling PLAYER name
                        tempPlayerAverage = tempInt
                        endOfNameIndex = lineIndex
                        break
                    } else {
                        tempPlayerName = "\(tempPlayerName) \(currentLine[lineIndex])"
                    }
                }
                
                if tempPlayerAverage == 0 && Int(currentLine[endOfNameIndex+1]) == 0 { // additional team member, no recorded games
                    tempPlayerHandicap = 0
                    tempYTDPinCount = 0
                    tempYTDGameCount = 0
                    tempSeriesGame1 = 0
                    tempSeriesGame2 = 0
                    tempSeriesGame3 = 0
                    tempSeriesScratchTotal = 0
                    tempSeriesHandicapTotal = 0
                } else if currentLine.count - endOfNameIndex < 10 { // additional team member, did not bowl during this session
                    tempPlayerHandicap = Int(currentLine[endOfNameIndex+1]) ?? 0
                    tempYTDPinCount = Int(currentLine[endOfNameIndex+2]) ?? 0
                    tempYTDGameCount = Int(currentLine[endOfNameIndex+3]) ?? 0
                    tempSeriesGame1 = 0
                    tempSeriesGame2 = 0
                    tempSeriesGame3 = 0
                    tempSeriesScratchTotal = 0
                    tempSeriesHandicapTotal = 0
                } else { // assume this was a bowled game by an active player
                    tempPlayerHandicap = Int(currentLine[endOfNameIndex+1]) ?? 0
                    tempYTDPinCount = Int(currentLine[endOfNameIndex+2]) ?? 0
                    tempYTDGameCount = Int(currentLine[endOfNameIndex+3]) ?? 0
                    let game1 = getGame(forGame: currentLine[endOfNameIndex+6])
                    tempSeriesGame1 = game1.0
                    tempSeriesGame1Absent = game1.1
                    let game2 = getGame(forGame: currentLine[endOfNameIndex+7])
                    tempSeriesGame2 = game2.0
                    tempSeriesGame2Absent = game2.1
                    let game3 = getGame(forGame: currentLine[endOfNameIndex+8])
                    tempSeriesGame3 = game3.0
                    tempSeriesGame3Absent = game3.1
                    tempSeriesScratchTotal = Int(currentLine[endOfNameIndex+9]) ?? 0
                    tempSeriesHandicapTotal = Int(currentLine[endOfNameIndex+10]) ?? 0
                }
                
                players.append(Player(
                    id: tempPlayerID,
                    name: tempPlayerName,
                    average: tempPlayerAverage,
                    isBookAverage: tempIsBookAverage,
                    handicap: tempPlayerHandicap,
                    ytdPinCount: tempYTDPinCount,
                    ytdGameCount: tempYTDGameCount,
                    series: Series(
                        game1: tempSeriesGame1,
                        game1Absent: tempSeriesGame1Absent,
                        game2: tempSeriesGame2,
                        game2Absent: tempSeriesGame2Absent,
                        game3: tempSeriesGame3,
                        game3Absent: tempSeriesGame3Absent,
                        scratchTotal: tempSeriesScratchTotal,
                        handicapTotal: tempSeriesHandicapTotal)))
                
                isVerbose("[\(fileIndex):\(allLines.count)] \(tempPlayerID) - \(tempPlayerName): AVG: \(tempPlayerAverage), HDCP: \(tempPlayerHandicap), Series(S:\(tempSeriesScratchTotal), H:\(tempSeriesHandicapTotal), [\(tempSeriesGame1), \(tempSeriesGame2), \(tempSeriesGame3)])")
            }
        }
        
        // create BowlingEvent
        let bowlingEvent = BowlingEvent(id: allLines[0], date: allLines[1], teams: teams)
        isVerbose("> Created BowlingEvent object.")
        
        // write to outFile
        guard let output = URL(string: FileManager.default.currentDirectoryPath)?.appendingPathComponent(outputFile) else {
            throw RuntimeError("Couldn't create output file path! (CWD: \(FileManager.default.currentDirectoryPath)) , (OF: \(outputFile))")
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            try encoder.encode(bowlingEvent).write(to: URL(string: "file://\(output)")!)
        } catch {
            throw RuntimeError("Couldn't encode/write BowlingEvent object to JSON file: \(output)!")
        }
        
        isVerbose(">>> \(inputFile) completed!")
    }
    
    // prints passed string if verbose is set to true
    func isVerbose(_ description: String) {
        if verbose{ print(description) }
    }
    
    // parses passed game and checks if was absent or vacant game, returns tuple
    private func getGame(forGame game: String) -> (Int, Bool) {
        let tempInt: Int
        let isAbsent: Bool
        
        if game.hasPrefix("a") || game.hasPrefix("v") {
            tempInt = Int(game.dropFirst()) ?? 0
            isAbsent = true
        } else {
            tempInt = Int(game) ?? 0
            isAbsent = false
        }
        
        return (tempInt, isAbsent)
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

LSSParse.main()
