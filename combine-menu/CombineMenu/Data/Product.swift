//
//  Product.swift
//  CombineMenu
//
//  Created by Maximilian Alexander on 3/3/22.
//

import DittoSwift
import Foundation

struct Product: Identifiable, Equatable, Hashable, DittoDecodable {
    let _id: String
    let name: String
    let detail: String
    let categoryId: String
    let isDeleted: Bool

    var id: String { _id } // For Identifiable
}
