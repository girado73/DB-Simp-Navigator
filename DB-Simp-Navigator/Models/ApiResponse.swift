//
//  ApiResponse.swift
//  test-todo-app
//
//  Created by Ricardo Güttner on 04.05.25.
//

import Foundation

struct ApiResponse: Codable {
    let verbindungen: [Verbindung]
    
    private enum CodingKeys: String, CodingKey {
        case verbindungen
    }
}

struct Verbindung: Codable, Hashable, Identifiable {
    let id: UUID
    let verbindungsAbschnitte: [ConnectionSection]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.verbindungsAbschnitte = try container.decode([ConnectionSection].self, forKey: .verbindungsAbschnitte)
    }
    
    static func == (lhs: Verbindung, rhs: Verbindung) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
