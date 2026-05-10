//
//  ProductDatabase.swift
//  DimCheck
//
//  Created by Aditi Narkar on 10/5/2026.
//
import Foundation

struct ProductDatabase {
    static let all: [Product] = [

        // ── Test box (your current Phase 1 object) ──
        Product(id: UUID(), name: "Test Box 200×150×100",
                brand: "Generic", category: .boxes,
                spec: .init(lengthMM: 200, widthMM: 150, heightMM: 100, toleranceMM: 5),
                modelFileName: nil),

        // ── Apple chargers ──
        Product(id: UUID(), name: "Apple 20W USB-C Power Adapter",
                brand: "Apple", category: .chargers,
                spec: .init(lengthMM: 66, widthMM: 30, heightMM: 29, toleranceMM: 3),
                modelFileName: nil),

        Product(id: UUID(), name: "Apple 30W USB-C Power Adapter",
                brand: "Apple", category: .chargers,
                spec: .init(lengthMM: 66, widthMM: 30, heightMM: 34, toleranceMM: 3),
                modelFileName: nil),

        Product(id: UUID(), name: "Apple 5W USB Power Adapter",
                brand: "Apple", category: .chargers,
                spec: .init(lengthMM: 52, widthMM: 52, heightMM: 28, toleranceMM: 3),
                modelFileName: nil),

        // ── Power banks ──
        Product(id: UUID(), name: "Anker PowerCore 10000",
                brand: "Anker", category: .powerBanks,
                spec: .init(lengthMM: 92, widthMM: 60, heightMM: 22, toleranceMM: 4),
                modelFileName: nil),

        Product(id: UUID(), name: "Anker PowerCore 20000",
                brand: "Anker", category: .powerBanks,
                spec: .init(lengthMM: 163, widthMM: 62, heightMM: 22, toleranceMM: 4),
                modelFileName: nil),
    ]

    static func products(in category: Product.Category) -> [Product] {
        all.filter { $0.category == category }
    }

    static func search(_ query: String) -> [Product] {
        guard !query.isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            $0.brand.lowercased().contains(q)
        }
    }
}
