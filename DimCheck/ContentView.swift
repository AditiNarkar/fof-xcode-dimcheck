//
//  ContentView.swift
//  DimCheck
//
//  Created by Aditi Narkar on 2/4/2026.
//


import SwiftUI

// Hardcoded spec for Phase 1 — a standard cardboard box (mm)
let boxSpec = SIMD3<Float>(0.200, 0.150, 0.100)   // metres   // L × W × H
let tolerance: Float = 0.005                  // ±5 mm

struct ContentView: View {
//    @State means "this variable controls the UI".
    @State private var scannedDimensions: SIMD3<Float>? = nil
    @State private var showAR = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Spec card
                GroupBox("Official spec — test box") {
                    DimRow(label: "Length", value: boxSpec.x)
                    DimRow(label: "Width",  value: boxSpec.y)
                    DimRow(label: "Height", value: boxSpec.z)
                    Text("Tolerance ±\(Int(tolerance)) mm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Scan button
                Button {
                    showAR = true
                } label: {
                    Label("Scan this product", systemImage: "viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                // Add this inside your VStack in ContentView, below the real scan button
                #if targetEnvironment(simulator)
                Button("Simulate scan (Simulator)") {
                    let (pts, surfaceY) = MockLiDAR.generateBox(
                        lengthMM: 200, widthMM: 150, heightMM: 100,
                        noiseMM: 1.5, rotationDeg: 23.0
                    )
                    // surfaceY known — same as ARKit would give via raycast
                    let tap = estimateTapPosition(points: pts, surfaceY: surfaceY)
                    let filtered = extractObjectPoints(pts, surfaceY: surfaceY, tapXZ: tap)
                    scannedDimensions = computeOBB(points: filtered, surfaceY: surfaceY)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                #endif
                
                // Result card
                if let dims = scannedDimensions {
//                    ResultCard(scanned: dims, spec: boxSpec, tolerance: tolerance)
                    ResultCard(scanned: dims, spec: .init(lengthMM: 200, widthMM: 150, heightMM: 100, toleranceMM: 5))
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("DimCheck")
            .sheet(isPresented: $showAR) {
                ARSheetView(scannedDimensions: $scannedDimensions, isPresented: $showAR)
            }
        }
    }
}

struct DimRow: View {
    let label: String
    let value: Float
    var prefix: String = ""      // optional, defaults to empty

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text("\(prefix)\(String(format: "%.1f", value * 1000)) mm")
                .monospacedDigit()
        }
    }
}

//struct ResultCard: View {
//    let scanned: SIMD3<Float>
//    let spec: SIMD3<Float>
//    let tolerance: Float
//    
//    var pass: Bool {
//        abs(scanned.x - spec.x) <= tolerance &&
//        abs(scanned.y - spec.y) <= tolerance &&
//        abs(scanned.z - spec.z) <= tolerance
//    }
//    
//    var body: some View {
//        GroupBox {
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("Scan result")
//                        .font(.headline)
//                    Spacer()
//                    Label(pass ? "Pass" : "Fail",
//                          systemImage: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
//                        .foregroundStyle(pass ? .green : .red)
//                        .font(.headline)
//                }
//                Divider()
//                CompareRow(label: "Length", scanned: scanned.x, spec: spec.x, tol: tolerance)
//                CompareRow(label: "Width",  scanned: scanned.y, spec: spec.y, tol: tolerance)
//                CompareRow(label: "Height", scanned: scanned.z, spec: spec.z, tol: tolerance)
//            }
//        }
//    }
//}

struct ResultCard: View {
    let scanned: SIMD3<Float>          // metres from OBB
    let spec: Product.DimensionSpec    // has .lengthM, .widthM, .heightM, .toleranceM

    var pass: Bool {
        abs(scanned.x - spec.lengthM) <= spec.toleranceM &&
        abs(scanned.y - spec.widthM)  <= spec.toleranceM &&
        abs(scanned.z - spec.heightM) <= spec.toleranceM
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Scan result").font(.headline)
                    Spacer()
                    Label(pass ? "Pass" : "Fail",
                          systemImage: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(pass ? .green : .red)
                        .font(.headline)
                }
                Divider()
                CompareRow(label: "Length", scanned: scanned.x, spec: spec.lengthM, tol: spec.toleranceM)
                CompareRow(label: "Width",  scanned: scanned.y, spec: spec.widthM,  tol: spec.toleranceM)
                CompareRow(label: "Height", scanned: scanned.z, spec: spec.heightM, tol: spec.toleranceM)
            }
        }
    }
}

struct CompareRow: View {
    let label: String
    let scanned: Float; let spec: Float; let tol: Float
    var delta: Float { scanned - spec }
    var ok: Bool { abs(delta) <= tol }
    
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
            Text(String(format: "%.1f mm", scanned * 1000)).monospacedDigit()
            Spacer()
            Text(String(format: "%+.1f mm", delta * 1000))
                .monospacedDigit()
                .foregroundStyle(ok ? .green : .red)
        }
    }
}

struct ARSheetView: View {
    @Binding var scannedDimensions: SIMD3<Float>?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARScanView(scannedDimensions: $scannedDimensions)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("Place box on a flat surface, then tap it")
                    .font(.subheadline)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                
                if scannedDimensions != nil {
                    Button("Done") { isPresented = false }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.bottom, 40)
        }
    }
}
