//
//  Category.swift
//  CombineMenu
//
//  Created by Maximilian Alexander on 3/3/22.
//

import DittoSwift
import Foundation

struct Category: Identifiable, Equatable, Hashable, DittoDecodable {
    let _id: String
    let name: String

    var id: String { _id } // For Identifiable
}
