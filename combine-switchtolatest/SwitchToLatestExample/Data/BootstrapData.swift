//
//  BootstrapData.swift
//  SwitchToLatestExample
//
//  Created by Maximilian Alexander on 8/10/22.
//

import Foundation
import DittoSwift
import Combine

final class DittoManager {

    static let shared = DittoManager()
    let ditto: Ditto
    private var cancellables = Set<AnyCancellable>()

    static let carriers = ["BA", "LH", "UA", "AS", "JL", "DL", "AF"]

    private init() {
        ditto = Ditto()
        try! ditto.disableSyncWithV3()

        bootstrapData()
    }

    private func bootstrapData() {
        Task {
            let isEmpty = try! await ditto.store.execute(query: "SELECT * FROM flights").items.isEmpty
            guard isEmpty else {
                return // no need to bootstrap data if there are documents already in the store
            }

            ditto.store.write { transaction in
                self.defaultData.forEach { data in
                    try! transaction["flights"].upsert(data)
                }
            }
        }
    }

    private var defaultData: [[String: Any]] {
        let airports = ["JFK", "LHR", "ORD", "SEA", "LGA", "FRA", "CDG", "MEX", "ATL"]
        var dataSet = [[String: Any]]()

        for i in 1...1000 {
            let from = airports.randomElement()!
            let to = airports.filter({ $0 != from }).randomElement()!
            dataSet.append([
                "_id": "\(i)",
                "carrier": Self.carriers.randomElement()!,
                "number": Int.random(in: 1...9999),
                "from": from,
                "to": to
            ])
        }
        return dataSet
    }
}
