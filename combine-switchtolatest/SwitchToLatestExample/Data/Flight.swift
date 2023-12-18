//
//  Flight.swift
//  SwitchToLatestExample
//
//  Created by Maximilian Alexander on 8/10/22.
//

import Foundation
import DittoSwift

struct Flight: Identifiable, Equatable, Hashable, DittoDecodable {
    let _id: String
    let from: String
    let to: String
    let number: Int
    let carrier: String
    var id: String { _id }
}
