//
//  Product.swift
//  DimCheck
//
//  Created by Aditi Narkar on 10/5/2026.
//
import Foundation

struct Product: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String
    let category: Category
    let spec: DimensionSpec
    let modelFileName: String?   // USDZ filename — nil until Phase 2

    enum Category: String, CaseIterable, Codable {
        case chargers     = "Chargers"
        case powerBanks   = "Power Banks"
        case cables       = "Cables"
        case electronics  = "Electronics"
        case boxes        = "Boxes"         // your current test case
    }

    struct DimensionSpec: Codable {
        let lengthMM: Float
        let widthMM:  Float
        let heightMM: Float
        let toleranceMM: Float

        // Convenience: in metres for ARKit comparison
        var lengthM: Float { lengthMM / 1000 }
        var widthM:  Float { widthMM  / 1000 }
        var heightM: Float { heightMM / 1000 }
        var toleranceM: Float { toleranceMM / 1000 }
    }
}
