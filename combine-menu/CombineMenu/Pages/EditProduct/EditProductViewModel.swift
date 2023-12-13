//
//  EditProductViewModel.swift
//  CombineMenu
//
//  Created by Eric Turner on 12/16/22.
//

import Combine
import Foundation
import DittoSwift

final class EditProductViewModel: ObservableObject {
    @Published var selectedCategory: Category?
    @Published var categories: [Category] = []
    @Published var name: String = ""
    @Published var detail: String = ""

    private var productIdToEdit: String?
    private var categoryIdForProductToAdd: String?
    private let store = DittoManager.shared.ditto.store

    var navigationTitle: String
    var saveButtonText: String

    private var cancellables = Set<AnyCancellable>()

    init(productIdToEdit: String?, categoryIdForProductToAdd: String?) {
        self.productIdToEdit = productIdToEdit
        self.categoryIdForProductToAdd = categoryIdForProductToAdd
        self.navigationTitle = productIdToEdit != nil ? "Edit Product": "Create Product"
        self.saveButtonText = productIdToEdit != nil ? "Save Changes": "Create Product"

        let getCategories = store.observePublisher(query: "SELECT * FROM categories", mapTo: Category.self)

        // When showing view as edit
        if let productIdToEdit = productIdToEdit {
            let getEditingProduct = store.observePublisher(
                query: "SELECT * FROM products WHERE _id == :_id",
                arguments: ["_id": productIdToEdit],
                mapTo: Product.self,
                onlyFirst: true
            )

            getCategories
                .combineLatest(getEditingProduct)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        assertionFailure(error.localizedDescription)
                    }
                }) { [weak self] categories, product in
                    guard let self = self else { return }
                    self.categories = categories
                    self.name = product.name
                    self.detail = product.detail
                    self.selectedCategory = categories.first { $0._id == product.categoryId }
                }
                .store(in: &cancellables)
        }

        // When showing view as create
        if let categoryIdForProductToAdd = categoryIdForProductToAdd {
            Just(categoryIdForProductToAdd)
                .combineLatest(getCategories.first().catch { _ in Empty() })
                .receive(on: DispatchQueue.main)
                .map { categoryId, allCategories in
                    allCategories.first { $0.id == categoryId }
                }
                .assign(to: &$selectedCategory)
        }
    }

    func save() {
        Task {
            let product: [String: Any?] =  ["_id": productIdToEdit ?? UUID().uuidString,
                            "name": name,
                            "detail": detail,
                            "categoryId": self.selectedCategory?.id,
                            "isDeleted": false]
            try! await store.execute(query: "INSERT INTO products DOCUMENTS (:product) ON ID CONFLICT DO UPDATE", arguments: ["product": product])
        }
    }

    func changeSelectedCategory(_ category: Category) {
        self.selectedCategory = category
    }
}
