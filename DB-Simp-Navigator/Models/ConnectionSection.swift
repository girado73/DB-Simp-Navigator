//
//  ConnectionSection.swift
//  test-todo-app
//
//  Created by Ricardo Güttner on 04.05.25.
//
import Foundation

struct ConnectionSection: Codable, Identifiable {
    var id: UUID { UUID() }
    let abfahrtsOrt: String?
    let ankunftsOrt: String?
    let verkehrsmittel: Verkehrsmittel?
    let halte: [Halt]?
    let distanz: Int?
    let abfahrtsZeitpunkt: String?
    let ankunftsZeitpunkt: String?
    let abschnittsDauer: Int?
    let auslastungsmeldungen: [Auslastung]?
    let ezAbfahrtsZeitpunkt: String?
    let ezAnkunftsZeitpunkt: String?
}
