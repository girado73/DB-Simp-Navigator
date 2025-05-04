//
//  Verkehrsmittel.swift
//  test-todo-app
//
//  Created by Ricardo Güttner on 04.05.25.
//

struct Verkehrsmittel: Codable {
    let langText: String
    let kurzText: String?
    let mittelText: String?
    let produktGattung: String?
    let kategorie: String?
    let linienNummer: String?
    let zugattribute: [Zugattribut]?
}

struct Zugattribut: Codable {
    let kategorie: String?
    let key: String?
    let value: String?
    let teilstreckenHinweis: String?
}
