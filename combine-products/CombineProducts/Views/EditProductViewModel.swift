//
//  EditProductViewModel.swift
//  CombineProducts
//
//  Created by Eric Turner on 12/20/22.
//

import Combine
import DittoSwift
import Foundation

final class EditProductViewModel: ObservableObject {
    @Published var category: Category?
    @Published var productName: String = ""
    private var cancellables = Set<AnyCancellable>()

    var navigationTitle: String
    var saveButtonText: String

    var editingProductId: String?
    var editingCategoryId: String?
    private let store = DittoManager.shared.ditto.store

    init(productIdToEdit: String?, categoryIdForProductToAdd: String?) {
        self.editingProductId = productIdToEdit
        self.editingCategoryId = categoryIdForProductToAdd

        self.navigationTitle = productIdToEdit != nil ? Key.editProductTitle: Key.createProductTitle
        self.saveButtonText = productIdToEdit != nil ? Key.saveChangesTitle: Key.createProductTitle


        if let categoryIdForProductToAdd = categoryIdForProductToAdd {
            getCategory(id: categoryIdForProductToAdd)
        }
        if let productIdToEdit = productIdToEdit {
            getProductName(id: productIdToEdit)
        }
    }

    deinit {
        cancellables = []
        print(#file, #line, #function)
    }

    private func getCategory(id: String) {
        store.executePublisher(query: "SELECT * FROM \(Key.categories)", mapTo: Category.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    assertionFailure(error.localizedDescription)
                }
            }, receiveValue: { [weak self] categories in
                self?.category = categories.first { $0.id == id }
            })
            .store(in: &cancellables)
    }

    private func getProductName(id: String) {
        store.executePublisher(query: "SELECT * FROM \(Key.products)", mapTo: Product.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    assertionFailure(error.localizedDescription)
                }
            }, receiveValue: { [weak self] products in
                self?.productName = products.first { $0.id == id }?.name ?? ""
            })
            .store(in: &cancellables)
    }

    func save() {
        let categoryId = (category != nil) ? category!.id : editingCategoryId
        let categoryName = (category != nil) ? category!.name : editingCategoryId

        // Saving product
        Task {
            let product = [
                Key.dbId: editingProductId ?? UUID().uuidString,
                Key.name: productName,
                Key.categoryId: categoryId
            ]
            try! await store.execute(query: "INSERT INTO \(Key.products) DOCUMENTS (:product) ON ID CONFLICT DO UPDATE", arguments: ["product": product])
        }

        // Saving category
        Task {
            let category = [
                Key.dbId: categoryId,
                Key.name: categoryName
            ]
            try! await store.execute(query: "INSERT INTO \(Key.categories) DOCUMENTS (:category) ON ID CONFLICT DO UPDATE", arguments: ["category": category])
        }
    }
}
