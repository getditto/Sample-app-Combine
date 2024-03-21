import DittoSwift
import Foundation

struct Category: Identifiable, Equatable, Hashable, DittoDecodable {
    let _id: String
    let name: String
    var id: String { _id } // For Identifiable\
}

struct Product: Identifiable, Equatable, Hashable, DittoDecodable {
    let _id: String
    let name: String
    let categoryId: String
    var id: String { _id } // For Identifiable
}

struct CategoryWithProducts: Identifiable {
    let category: Category
    var products: [Product]
    var id: String { category.id }
}
