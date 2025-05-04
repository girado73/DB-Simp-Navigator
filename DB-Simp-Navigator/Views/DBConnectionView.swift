//
//  DBConnectionView.swift
//  test-todo-app
//
//  Created by Ricardo Güttner on 04.05.25.
//

// Views/DBConnectionView.swift
import SwiftUI

struct DBConnectionView: View {
    @StateObject private var viewModel = DBViewModel()
    @State private var currentPage = 0

    @State private var departure: String = "LeipzigHBF"
    @State private var arrival: String = "Eilenburg"
    @State private var selectedTime: Date = Date()

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Main content
                VStack {
                    Form {
                        Section(header: Text("Reiseinformationen")) {
                            TextField("Abfahrtsbahnhof", text: $departure)
                            TextField("Ankunftsbahnhof", text: $arrival)
                            DatePicker("Zeit", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            Button("Verbindung suchen") {
                                viewModel.fetchConnection(from: departure, to: arrival, time: selectedTime)
                                currentPage = 0
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if viewModel.connections.isEmpty && viewModel.errorMessage == nil {
                        Text("Keine Verbindungen gefunden")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    
                    if !viewModel.connections.isEmpty {
                        GeometryReader { geometry in
                            TabView(selection: $currentPage) {
                                ForEach(Array(viewModel.connections.enumerated()), id: \.element.id) { index, connection in
                                    ConnectionCard(connection: connection)
                                        .tag(index)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }
                
                // Page indicator dots on the right side
                if !viewModel.connections.isEmpty {
                    VStack {
                        Spacer()
                        ForEach(0..<viewModel.connections.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray)
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                                .padding(.vertical, 2)
                        }
                        Spacer()
                    }
                    .padding(.trailing, 8)
                    .padding(.vertical)
                }
            }
            .navigationTitle("DB Simp Navigator")
        }
    }
}

struct ConnectionCard: View {
    let connection: Verbindung
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(connection.verbindungsAbschnitte) { section in
                    ConnectionSectionView(section: section)
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// Extracted subview for better organization
struct ConnectionSectionView: View {
    let section: ConnectionSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let from = section.abfahrtsOrt,
               let to = section.ankunftsOrt {
                Text("Von \(from) nach \(to)")
                    .font(.headline)
            }
            
            if let type = section.verkehrsmittel?.langText {
                HStack {
                    Image(systemName: "tram.fill")
                    Text(type)
                }
                .foregroundColor(.secondary)
            }
            
            if let departure = section.ezAbfahrtsZeitpunkt{
                HStack {
                    Image(systemName: "arrow.up.circle")
                    Text("Echtzeit Abfahrt: \(formatDateTime(departure))")
                }
            }else{
                if let departure = section.abfahrtsZeitpunkt{
                    HStack {
                        Image(systemName: "arrow.up.circle")
                        Text("Abfahrt: \(formatDateTime(departure))")
                    }
                }
            }
            
            if let planned = section.abfahrtsZeitpunkt,
                let realtime = section.ezAbfahrtsZeitpunkt {
                if let delay = calculateDelay(planned: planned, realtime: realtime) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        if(delay == 1){
                            Text("Verspätung: \(delay) Minute")
                        }else{
                            Text("Verspätung: \(delay) Minuten")
                        }
                    }
                    .foregroundColor(delay <= 0 ? .green :
                                    delay <= 5 ? .yellow :
                                    delay <= 10 ? .orange : .red)
                    }
            }
            
            
            if let arrival = section.ezAnkunftsZeitpunkt{
                HStack {
                    Image(systemName: "arrow.down.circle")
                    Text("Echtzeit Abfahrt: \(formatDateTime(arrival))")
                }
            }else{
                if let arrival = section.ankunftsZeitpunkt{
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Abfahrt: \(formatDateTime(arrival))")
                    }
                }
            }
            
            if let duration = section.abschnittsDauer {
                HStack {
                    Image(systemName: "clock")
                    Text("Dauer: \(duration / 60) Minuten")
                }
            }
            
            if let halte = section.halte,
               let firstHalt = halte.first,
               let gleis = firstHalt.gleis {
                HStack {
                    Image(systemName: "train.side.front.car")
                    Text("Gleis: \(gleis)")
                }
            }
            
            if let auslastung = section.auslastungsmeldungen?.first {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Auslastung: \(getAuslastungText(stufe: auslastung.stufe ?? 0))")
                }
                .foregroundColor(getAuslastungColor(stufe: auslastung.stufe ?? 0))
            }
            
            if let verkehrsmittel = section.verkehrsmittel,
               let attributes = verkehrsmittel.zugattribute {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(attributes, id: \.key) { attribute in
                        if let value = attribute.value {
                            HStack {
                                Image(systemName: getAttributeIcon(attribute: attribute))
                                Text(value)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func getAuslastungText(stufe: Int) -> String {
        switch stufe {
        case 0: return "Gering"
        case 1: return "Mittel"
        case 2: return "Hoch"
        default: return "Unbekannt"
        }
    }
    
    private func getAuslastungColor(stufe: Int) -> Color {
        switch stufe {
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .gray
        }
    }
    
    private func getAttributeIcon(attribute: Zugattribut) -> String {
        switch attribute.key {
        case "FB": return "bicycle"
        case "EH": return "figure.roll"
        case "LS": return "powerplug"
        case "WV": return "wifi"
        case "BEF": return "train.side.front.car"
        default: return "info.circle"
        }
    }
    private func calculateDelay(planned: String, realtime: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let plannedDate = dateFormatter.date(from: planned),
              let realtimeDate = dateFormatter.date(from: realtime) else {
            print("Failed to parse dates - planned: \(planned), realtime: \(realtime)")
            return nil
        }
        
        return Int(realtimeDate.timeIntervalSince(plannedDate) / 60)
    }
}
