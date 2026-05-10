//
//  ProductDetailView.swift
//  DimCheck
//
//  Created by Aditi Narkar on 10/5/2026.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var scannedDimensions: SIMD3<Float>? = nil
    @State private var showAR = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Spec card
                GroupBox("Official Spec") {
                    DimRow(label: "Length", value: product.spec.lengthMM)
                    DimRow(label: "Width",  value: product.spec.widthMM)
                    DimRow(label: "Height", value: product.spec.heightMM)
                    DimRow(label: "Tolerance", value: product.spec.toleranceMM, prefix: "±")
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

                // Simulator mock button
                #if targetEnvironment(simulator)
                Button("Simulate scan") {
                    let (pts, surfaceY) = MockLiDAR.generateBox(
                        lengthMM: product.spec.lengthMM,
                        widthMM:  product.spec.widthMM,
                        heightMM: product.spec.heightMM
                    )
                    let tap = estimateTapPosition(points: pts, surfaceY: surfaceY)
                    let filtered = extractObjectPoints(pts, surfaceY: surfaceY, tapXZ: tap)
                    scannedDimensions = computeOBB(points: filtered, surfaceY: surfaceY)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                #endif

                // Result
                if let dims = scannedDimensions {
                    ResultCard(scanned: dims, spec: product.spec)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAR) {
            ARSheetView(scannedDimensions: $scannedDimensions,
                        isPresented: $showAR)
        }
    }
}
