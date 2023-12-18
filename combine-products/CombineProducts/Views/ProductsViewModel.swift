//
//  ProductsViewModel.swift
//  CombineProducts
//
//  Created by Eric Turner on 12/20/22.
//

import Combine
import DittoSwift
import Foundation

final class ProductsViewModel: ObservableObject {
    @Published var categorizedProducts = [CategoryWithProducts]()
    private var cancellables = Set<AnyCancellable>()

    private let store = DittoManager.shared.ditto.store
    @Published var isPresentingProductView = false
    var editingProductId: String?
    var editingCategoryId: String?

    init() {
        DittoManager.shared.startSync()

        let productsPublisher = store.observePublisher(query: "SELECT * FROM products", mapTo: Product.self)
        let categoriesPublisher = store.observePublisher(query: "SELECT * FROM categories", mapTo: Category.self)

        categoriesPublisher.combineLatest(productsPublisher)
            .map { categories, products in
                categories.map { category -> CategoryWithProducts in
                    let filteredProducts = products.filter { product in product.categoryId == category.id }
                    return CategoryWithProducts(category: category, products: filteredProducts)
                }
            }
            .catch { _ in
                Just([])
            }
            .assign(to: \.categorizedProducts, on: self)
            .store(in: &cancellables)
    }

    func presentProductEdit(productIdToEdit: String?, categoryIdForProductToAdd: String?) {
        isPresentingProductView = true
        editingProductId = productIdToEdit
        editingCategoryId = categoryIdForProductToAdd
    }

    func clearEditingData() {
        editingProductId = nil
        editingCategoryId = nil
        isPresentingProductView = false
    }

    func prepopulate() {
        Task {
            let powerTools = "Power Tools"
            let handTools = "Hand Tools"
            let shopTools = "Shop Tools"

            // Categories
            let insertCategoryQuery = "INSERT INTO \(Key.categories) DOCUMENTS (:category) ON ID CONFLICT DO NOTHING"
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": [Key.dbId: powerTools, Key.name: powerTools]])
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": [Key.dbId: handTools, Key.name: handTools]])
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": [Key.dbId: shopTools, Key.name: shopTools]])

            // Products
            let insertProductQuery = "INSERT INTO \(Key.products) DOCUMENTS (:product) ON ID CONFLICT DO NOTHING"
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Circular saw", Key.name: "Circular saw", Key.categoryId: powerTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Cordless drill", Key.name: "Cordless drill", Key.categoryId: powerTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Phillips screwdriver", Key.name: "Phillips screwdriver", Key.categoryId: handTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Crescent wrench", Key.name: "Crescent wrench", Key.categoryId: handTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Wire cutters", Key.name: "Wire cutters", Key.categoryId: handTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Drill press", Key.name: "Drill press", Key.categoryId: shopTools]])
            try! await store.execute(query: insertProductQuery, arguments: ["product": [Key.dbId: "Bench grinder", Key.name: "Bench grinder", Key.categoryId: shopTools]])
        }
    }
}
