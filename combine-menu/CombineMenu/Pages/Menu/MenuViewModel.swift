//
//  MenuViewModel.swift
//  CombineMenu
//
//  Created by Eric Turner on 12/16/22.
//

import Combine
import DittoSwift
import SwiftUI

class MenuViewModel: ObservableObject {
    @Published var categorizedProducts = [CategorizedProducts]()
    @Published var isPresentingProductView = false

    private let store = DittoManager.shared.ditto.store

    var productIdToEdit: String?
    var categoryIdForProductToAdd: String?

    init() {
        let productsPublisher = store.observePublisher(query: "SELECT * FROM products WHERE isDeleted == false", mapTo: Product.self)
        let categoriesPublisher = store.observePublisher(query: "SELECT * FROM categories", mapTo: Category.self)

        categoriesPublisher
            .combineLatest(productsPublisher)
            .receive(on: DispatchQueue.main)
            .map { categories, products in
                categories.map { category in
                    let filteredProducts = products.filter { product in product.categoryId == category.id }
                    return CategorizedProducts(category: category, products: filteredProducts)
                }
            }
            .catch { _ in
                Just([])
            }
            .assign(to: &$categorizedProducts)

    }

    func presentProductEdit(productIdToEdit: String?, categoryIdForProductToAdd: String?) {
        self.isPresentingProductView = true
        self.productIdToEdit = productIdToEdit
        self.categoryIdForProductToAdd = categoryIdForProductToAdd
    }

    func deleteProduct(categorizedProducts: CategorizedProducts, indexSet: IndexSet) {
        indexSet.map({ categorizedProducts.products[$0] }).forEach { [weak self] productToDelete in
            guard let self = self else { return }
            Task {
                try! await self.store.execute(query: "UPDATE products SET isDeleted = true WHERE _id = :_id", arguments: ["_id": productToDelete.id])
            }

        }
    }

    func clearEditingData() {
        self.productIdToEdit = nil
        self.categoryIdForProductToAdd = nil
        self.isPresentingProductView = false
    }

    func prepopulate() {
        Task {
            // Categories
            let insertCategoryQuery = "INSERT INTO categories DOCUMENTS (:category) ON ID CONFLICT DO NOTHING"
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": ["_id": "drinks", "name": "Drinks"]])
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": ["_id": "entrees", "name": "Entrees"]])
            try! await store.execute(query: insertCategoryQuery, arguments: ["category": ["_id": "dessert", "name": "Desserts"]])

            // Products
            let insertProductsQuery = "INSERT INTO products DOCUMENTS (:product) ON ID CONFLICT DO NOTHING"
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "coca-cola",
                                                                                            "name": "Coca Cola",
                                                                                            "detail": "Coca Cola soft drink",
                                                                                            "categoryId": "drinks",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "diet-pepsi",
                                                                                            "name": "Diet Pepsi",
                                                                                            "detail": "Diet Pepsi standard flavor",
                                                                                            "categoryId": "drinks",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "cappucino",
                                                                                            "name": "Cappucino",
                                                                                            "detail": "One shot of espresso and steamed milk",
                                                                                            "categoryId": "drinks",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "chicken-sandwich",
                                                                                            "name": "Chicken Sandwich",
                                                                                            "detail": "A grilled chicken sandwich with tomatoes, lettuce and mustard.",
                                                                                            "categoryId": "entrees",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "roast-beef",
                                                                                            "name": "Roast Beef",
                                                                                            "detail": "A roast beef sandwich with tomatoes, lettuce and mustard.",
                                                                                            "categoryId": "entrees",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "fettuccine-alfredo",
                                                                                            "name": "Fettuccine Alfredo",
                                                                                            "detail": "Fresh fettuccine tossed with butter and Parmesan cheese.",
                                                                                            "categoryId": "entrees",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "chocolate-chip-cookie",
                                                                                            "name": "Chocolate Chip Cookie",
                                                                                            "detail": "Chocolate Chip Cookie",
                                                                                            "categoryId": "dessert",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "vanilla-ice-cream",
                                                                                            "name": "Vanilla Ice Cream",
                                                                                            "detail": "Vanilla Ice Cream",
                                                                                            "categoryId": "dessert",
                                                                                            "isDeleted": false]])
            try! await store.execute(query: insertProductsQuery, arguments: ["product": ["_id": "caramel-candy",
                                                                                            "name": "Caramel Candy",
                                                                                            "detail": "Caramel Candy",
                                                                                            "categoryId": "dessert",
                                                                                            "isDeleted": false]])
        }
    }
}

