//
//  EditProductView.swift
//  CombineProducts
//
//  Created by Eric Turner on 12/20/22.
//

import SwiftUI

struct EditProductView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EditProductViewModel

    @State var newCategoryName: String = ""
    @FocusState private var isNewCategoryFocused: Bool

    init(productIdToEdit: String?, categoryIdForProductToAdd: String?) {
        viewModel = EditProductViewModel(
            productIdToEdit: productIdToEdit,
            categoryIdForProductToAdd: categoryIdForProductToAdd
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(Key.categorySection) {
                    if viewModel.category == nil { // Adding a new category
                        TextField(Key.required, text: $newCategoryName)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: newCategoryName) { text in
                                viewModel.editingCategoryId = text
                            }
                    } else { // Editing an existing product
                        HStack {
                            Image(systemName: Key.circleFillImg)
                            Text(viewModel.category!.name)
                        }
                    }
                }
                Section(Key.productNameTitle) {
                    TextField(Key.required, text: $viewModel.productName)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                Section {
                    HStack {
                        Spacer()
                        Button(viewModel.saveButtonText) {
                            viewModel.save()
                            dismiss()
                        }
                        Spacer()
                    }
                    .disabled(
                        (newCategoryName.isEmpty && viewModel.category == nil) ||
                        viewModel.productName.isEmpty
                    )
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(Key.cancelTitle) {
                        dismiss()
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
        }
    }
}
