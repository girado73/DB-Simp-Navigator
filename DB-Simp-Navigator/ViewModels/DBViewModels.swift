//
//  DBViewModels.swift
//  test-todo-app
//
//  Created by Ricardo Güttner on 04.05.25.
//

// ViewModels/DBViewModel.swift

import SwiftUI
import Foundation

class DBViewModel: ObservableObject {
    @Published var connections: [Verbindung] = []
    @Published var errorMessage: String? = nil
    
    let bahnhofDict: [String: String] = [
        "Eilenburg": "A=1@O=Eilenburg@X=12637018@Y=51451855@U=80@L=8010095@B=1@p=1716406324@i=U×008023401@",
        "LeipzigHBF": "A=1@O=Leipzig Hbf@X=12382066@Y=51345467@U=80@L=8010205@B=1@p=1716406324@i=U×008023179@",
        "HTWK": "A=1@O=Richard-Lehmann-Str./HTWK, Leipzig@X=12373346@Y=51315363@U=80@L=958301@B=1@p=1716406324@",
        "KoelnHBF": "A=1@O=Köln Hbf",
    ]
    
    func tryDict(_ input: String) -> String {
        return bahnhofDict[input] ?? "A=1@O=\(input)"
    }
    
    func fetchConnection(from: String, to: String, time: Date) {
        guard let url = URL(string: "https://www.bahn.de/web/api/angebote/fahrplan") else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let day = dateFormatter.string(from: time)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeStr = timeFormatter.string(from: time)
        
        let payload: [String: Any] = [
            "abfahrtsHalt": tryDict(from),
            "anfrageZeitpunkt": "\(day)T\(timeStr):00",
            "ankunftsHalt": tryDict(to),
            "ankunftSuche": "ABFAHRT",
            "klasse": "KLASSE_2",
            "maxUmstiege": 5,  // Add this to get more connections
            "produktgattungen": [
                "ICE", "EC_IC", "IR", "REGIONAL", "SBAHN",
                "BUS", "SCHIFF", "UBAHN", "TRAM", "ANRUFPFLICHTIG"
            ],
            "reisende": [[
                "typ": "ERWACHSENER",
                "ermaessigungen": [["art": "KEINE_ERMAESSIGUNG", "klasse": "KLASSENLOS"]],
                "alter": [],
                "anzahl": 1
            ]],
            "schnelleVerbindungen": false,  // Set to false to get more alternatives
            "sitzplatzOnly": false,
            "bikeCarriage": false,
            "reservierungsKontingenteVorhanden": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let decoded = try JSONDecoder().decode(ApiResponse.self, from: data)
                        self?.connections = decoded.verbindungen
                        self?.errorMessage = nil
                    } catch {
                        print("Decoding error: \(error)")  // Debug print
                        self?.errorMessage = "Parsing Error: \(error.localizedDescription)"
                    }
                } else if let error = error {
                    print("Network error: \(error)")  // Debug print
                    self?.errorMessage = "Network Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
