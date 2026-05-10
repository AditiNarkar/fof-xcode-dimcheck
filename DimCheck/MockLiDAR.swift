// MockLiDAR.swift
// Generates synthetic LiDAR point clouds in Swift.
// Used in Simulator. Replaced by real ARKit mesh on device.
// Zero changes needed to OBB.swift or ContentView.swift.

import Foundation
import simd

struct MockLiDAR {

    /// Generates a synthetic box point cloud matching what iPad LiDAR produces:
    /// - Points on visible surfaces only (top + sides, not bottom)
    /// - Gaussian noise matching iPad LiDAR accuracy (~1.5mm)
    /// - Random Y-axis rotation so box isn't axis-aligned
    /// - Ground plane points surrounding the object
    static func generateBox(
        lengthMM: Float = 200,
        widthMM:  Float = 150,
        heightMM: Float = 100,
        noiseMM:  Float = 1.5,
        rotationDeg: Float = 23.0
    ) -> (points: [SIMD3<Float>], surfaceY: Float) {

        let L = lengthMM / 1000
        let W = widthMM  / 1000
        let H = heightMM / 1000
        let noise = noiseMM / 1000
        let surfaceY: Float = 0.0

        var points: [SIMD3<Float>] = []

        // ── Sample a rectangular face ──────────────────────────────────────
        func sampleFace(corner: SIMD3<Float>,
                        uVec: SIMD3<Float>, uLen: Float,
                        vVec: SIMD3<Float>, vLen: Float,
                        density: Float = 1.0) {
            let areaCM2 = uLen * 100 * vLen * 100
            let count = Int(areaCM2 * 8 * density)
            for _ in 0..<max(10, count) {
                let u = Float.random(in: 0...uLen)
                let v = Float.random(in: 0...vLen)
                let pt = corner + uVec * u + vVec * v
                let noisy = pt + SIMD3<Float>(
                    gaussianNoise(std: noise),
                    gaussianNoise(std: noise),
                    gaussianNoise(std: noise)
                )
                points.append(noisy)
            }
        }

        let hL = L / 2, hW = W / 2
        let xAxis = SIMD3<Float>(1, 0, 0)
        let yAxis = SIMD3<Float>(0, 1, 0)
        let zAxis = SIMD3<Float>(0, 0, 1)

        // Top face — fully visible
        sampleFace(corner: SIMD3(-hL, H, -hW), uVec: xAxis, uLen: L, vVec: zAxis, vLen: W)
        // Front face
        sampleFace(corner: SIMD3(-hL, 0, hW),  uVec: xAxis, uLen: L, vVec: yAxis, vLen: H)
        // Right face
        sampleFace(corner: SIMD3(hL,  0, -hW), uVec: zAxis, uLen: W, vVec: yAxis, vLen: H)
        // Left face — partially occluded, 50% density
        sampleFace(corner: SIMD3(-hL, 0, -hW), uVec: zAxis, uLen: W, vVec: yAxis, vLen: H, density: 0.5)
        // Back face — barely visible, 20% density
        sampleFace(corner: SIMD3(-hL, 0, -hW), uVec: xAxis, uLen: L, vVec: yAxis, vLen: H, density: 0.2)

        // Apply Y-axis rotation
        let angle = rotationDeg * .pi / 180
        points = points.map { rotateY($0, by: angle) }

        // Translate to a realistic scan position
        points = points.map { $0 + SIMD3<Float>(0.3, 0, 0.2) }

        // Ground plane points
        for _ in 0..<300 {
            let gx = Float.random(in: 0.0...0.8)
            let gz = Float.random(in: 0.0...0.6)
            let gy = gaussianNoise(std: noise * 0.5)
            points.append(SIMD3<Float>(gx, surfaceY + gy, gz))
        }

        return (points, surfaceY)
    }

    // ── Box-Muller Gaussian noise ──────────────────────────────────────────
    static func gaussianNoise(std: Float) -> Float {
        let u1 = Float.random(in: .ulpOfOne...1)
        let u2 = Float.random(in: 0...1)
        return std * sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }

    static func rotateY(_ p: SIMD3<Float>, by angle: Float) -> SIMD3<Float> {
        SIMD3<Float>(
             p.x * cos(angle) + p.z * sin(angle),
             p.y,
            -p.x * sin(angle) + p.z * cos(angle)
        )
    }
}
