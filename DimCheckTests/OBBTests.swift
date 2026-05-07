//
//  OBBTests.swift
//  DimCheckTests
//
//  Created by Aditi Narkar on 7/4/2026.
//

import XCTest
@testable import DimCheck

class OBBTests: XCTestCase {

    // A perfect axis-aligned box: 200 × 100mm footprint, 50mm tall
    func testAxisAlignedBox() {
        var points: [SIMD3<Float>] = []
        // Generate points on the surface of a 0.2 × 0.1 × 0.05m box
        for x in stride(from: 0.0, through: 0.2, by: 0.01) {
            for z in stride(from: 0.0, through: 0.1, by: 0.01) {
                points.append(SIMD3<Float>(Float(x), 0.05, Float(z)))
            }
        }
        let result = computeOBB(points: points, surfaceY: 0.0)
        XCTAssertEqual(result.x, 0.2, accuracy: 0.005) // length
        XCTAssertEqual(result.y, 0.1, accuracy: 0.005) // width
        XCTAssertEqual(result.z, 0.05, accuracy: 0.005) // height
    }

    // A box rotated 45° — OBB should still return correct dimensions
    func testRotatedBox() {
        var points: [SIMD3<Float>] = []
        let angle: Float = .pi / 4  // 45 degrees
        for i in stride(from: -0.1, through: 0.1, by: 0.01) {
            for j in stride(from: -0.05, through: 0.05, by: 0.01) {
                let x = Float(i) * cos(angle) - Float(j) * sin(angle)
                let z = Float(i) * sin(angle) + Float(j) * cos(angle)
                points.append(SIMD3<Float>(x, 0.08, z))
            }
        }
        let result = computeOBB(points: points, surfaceY: 0.0)
        XCTAssertEqual(result.x, 0.2, accuracy: 0.01)
        XCTAssertEqual(result.y, 0.1, accuracy: 0.01)
        XCTAssertEqual(result.z, 0.08, accuracy: 0.005)
    }
}
