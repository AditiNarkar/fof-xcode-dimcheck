//
//  OBB.swift
//  DimCheck
//
//  Created by Aditi Narkar on 2/4/2026.
//

// Takes an array of 3D world-space points and returns three measurements: length, width, height. It uses PCA (Principal Component Analysis) to find the natural orientation of the point cloud — so it works correctly even if the box is sitting at an angle.

import simd

// Returns (length, width, height) in metres using PCA on the XZ plane
func computeOBB(points: [SIMD3<Float>], surfaceY: Float) -> SIMD3<Float> {
    
    // Height is simple: max Y above surface
    // .map transforms every point into just its height-above-surface value. .max() returns the biggest one. The ?? 0 provides a fallback if the array is empty
    let height = points.map { $0.y - surfaceY }.max() ?? 0
    
    // Work in XZ plane for footprint - flatten every point down to 2D by keeping only X and Z.
    let xz = points.map { SIMD2<Float>($0.x, $0.z) }
    
    // Centroid
    let cx = xz.map(\.x).reduce(0, +) / Float(xz.count)
    let cz = xz.map(\.y).reduce(0, +) / Float(xz.count)
    
    // 2×2 covariance matrix
    // c00 = variance in X (large if points span a wide X range). c11 = variance in Z. c01 = covariance — how much X and Z move together (large if the object is diagonal). This 2×2 matrix encodes the entire "shape" of the point cloud's spread.
    var c00: Float = 0; var c01: Float = 0; var c11: Float = 0
    for p in xz {
        let dx = p.x - cx; let dz = p.y - cz
        c00 += dx*dx; c01 += dx*dz; c11 += dz*dz
    }
    c00 /= Float(xz.count); c01 /= Float(xz.count); c11 /= Float(xz.count)
    
    // Principal axis (largest eigenvector of 2×2 sym matrix)
    let trace = c00 + c11
    let det   = c00*c11 - c01*c01
    let disc  = sqrt(max(0, trace*trace/4 - det))
    let lam1  = trace/2 + disc
    
    var axis = SIMD2<Float>(lam1 - c11, c01)
    let axisLen = sqrt(axis.x*axis.x + axis.y*axis.y)
    if axisLen > 0 { axis /= axisLen }
    let perp = SIMD2<Float>(-axis.y, axis.x)
    
    // Project all points onto axis and perp
    // The dot product of a point with a unit vector gives how far that point lies along that direction
    var minA = Float.infinity, maxA = -Float.infinity
    var minP = Float.infinity, maxP = -Float.infinity
    for p in xz {
        let dx = p.x - cx; let dz = p.y - cz
        let a = dx*axis.x + dz*axis.y
        let b = dx*perp.x + dz*perp.y
        minA = min(minA, a); maxA = max(maxA, a)
        minP = min(minP, b); maxP = max(maxP, b)
    }
    
    let dim1 = maxA - minA
    let dim2 = maxP - minP
    
    // Return as length (longest), width (shorter), height
    return SIMD3<Float>(
        max(dim1, dim2),
        min(dim1, dim2),
        height
    )
}
