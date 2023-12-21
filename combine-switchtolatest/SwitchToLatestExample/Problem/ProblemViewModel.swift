//
//  ProblemViewModel.swift
//  SwitchToLatestExample
//
//  Created by Maximilian Alexander on 8/10/22.
//

import Foundation
import DittoSwift
import Combine

class ProblemViewModel: ObservableObject {

    @Published var carrier: String = DittoManager.carriers.randomElement()!
    @Published var flights: [Flight] = []

    private let store = DittoManager.shared.ditto.store
    var cancellables = Set<AnyCancellable>()

    init() {
        $carrier
            .removeDuplicates()
            .map { carrier in
                self.store.observePublisher(query: "SELECT * FROM flights WHERE carrier = :carrier", arguments: ["carrier": carrier], mapTo: Flight.self)
            }
            .switchToLatest()
            .catch { _ in Just([]) }
            .assign(to: \.flights, on: self)
            .store(in: &cancellables)
    }
}
