//
//  CatalogueView.swift
//  DimCheck
//
//  Created by Aditi Narkar on 10/5/2026.
//

import SwiftUI

struct CatalogueView: View {
    @State private var searchText = ""

    var grouped: [Product.Category: [Product]] {
        Dictionary(grouping: ProductDatabase.search(searchText), by: \.category)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Product.Category.allCases, id: \.self) { category in
                    if let products = grouped[category] {
                        Section(category.rawValue) {
                            ForEach(products) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductRow(product: product)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Product Catalogue")
            .searchable(text: $searchText, prompt: "Search products")
        }
    }
}

struct ProductRow: View {
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name).font(.body)
            Text("\(product.brand) · \(product.spec.lengthMM, specifier: "%.0f")×\(product.spec.widthMM, specifier: "%.0f")×\(product.spec.heightMM, specifier: "%.0f") mm")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
