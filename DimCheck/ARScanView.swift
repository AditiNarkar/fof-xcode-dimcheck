//
//  ARScanView.swift
//  DimCheck
//
//  Created by Aditi Narkar on 2/4/2026.
//
// This file does the heavy lifting. It bridges SwiftUI into Apple's AR framework, configures the LiDAR sensor, handles the tap gesture, walks the 3D mesh, and extracts the object's point cloud. There are two classes here: ARScanView (the bridge) and Coordinator (the logic handler).
// User taps → find surface → collect LiDAR points → isolate object → compute dimensions → send back to SwiftUI

import SwiftUI
import ARKit
import RealityKit

struct ARScanView: UIViewRepresentable {
    
    // results go back to SwiftUI
    // SIMD3<Float> = (width, height, depth)
    // Optional(?) → might not exist yet
    @Binding var scannedDimensions: SIMD3<Float>?
    
    // called ONCE on appear
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // ARKit configuration — what we tell LiDAR to do
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh          // LiDAR mesh
        config.planeDetection = [.horizontal]       // detect the table surface
        config.frameSemantics = .sceneDepth         // per-pixel depth map
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        // User taps → Coordinator handles it
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)
        
        // Pass References to Coordinator
        context.coordinator.arView = arView
        context.coordinator.scannedDimensions = $scannedDimensions
        
        return arView
    }
    
    // called on every SwiftUI redraw
    // Empty because: You don’t need dynamic UI updates here
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    // creates the event handler
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// Coordinator is a class (reference type) that lives as long as the AR session does.
// holds a weak reference to arView (to avoid a retain cycle — if both held strong references to each other, neither would ever be freed from memory). It holds the Binding so it can write results back to ContentView.

// ARKit → Coordinator → SwiftUI View

class Coordinator: NSObject, ARSessionDelegate {
    
    // weak prevents memory leak (retain cycle)
    weak var arView: ARView?
    var scannedDimensions: Binding<SIMD3<Float>?>?
    
    
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        
        //If AR not ready → exit
        guard let arView = arView,
              let frame = arView.session.currentFrame else { return }
        
        let tapLocation = gesture.location(in: arView)
        
        // step 1: Raycast to find the surface plane the object sits on
        let results = arView.raycast(
            from: tapLocation,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        guard let hit = results.first else { return }
        
        // worldTransform is a 4×4 matrix encoding position and rotation.
        // .columns.3 is the translation column of that matrix — the actual 3D position.
        // .y is the vertical coordinate. This becomes our "floor level" for the object.
        
        let surfaceY = hit.worldTransform.columns.3.y  // height (Y) of the surface
        let tapPoint = SIMD3<Float>(
            hit.worldTransform.columns.3.x,
            surfaceY,
            hit.worldTransform.columns.3.z
        ) // Center of your object search area
        
        // Gather LiDAR mesh vertices above the surface within 0.3m radius
        var objectPoints: [SIMD3<Float>] = []
        
        // for a small USB charger you'd use 0.10m
        let radius: Float = 0.30           // tune - within 30cm radius
        let minHeight: Float = 0.005       // above surface noise (5mm)
        let ceilHeight: Float = 0.5         // below 50cm ceiling
        
        guard let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor }) as? [ARMeshAnchor] else { return }
        
        // step 2: walk every LiDAR mesh vertex
        // ARKit divides the mesh into chunks called ARMeshAnchors
        
        for anchor in arView.session.currentFrame?.anchors ?? [] {
            guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
            
            // Get geometry
            let geometry = meshAnchor.geometry
            let transform = meshAnchor.transform
            
            // Iterate Vertices
            for i in 0..<geometry.vertices.count {
                let localVertex = geometry.vertex(at: UInt32(i))
                
                // Transform to world space: To compare them against the tap position we need world space
                // appending a 1 lets the 4×4 matrix apply both rotation and translation in a single multiply.
                
                let worldPos = (transform * SIMD4<Float>(localVertex, 1)).xyz
                
                // step 3: filter to object points only
                let dx = worldPos.x - tapPoint.x
                let dz = worldPos.z - tapPoint.z
                let dist = sqrt(dx*dx + dz*dz)          // horizontal distance
                let height = worldPos.y - surfaceY      //  how far above the table
                
                if dist < radius && height > minHeight && height < ceilHeight {
                    objectPoints.append(worldPos)       // store points
                }
            }
        }
        
        // Avoid noise / bad scans
        guard objectPoints.count > 20 else {
            print("Not enough points: \(objectPoints.count)")
            return
        }
        
        // Compute Dimensions
        let dims = computeOBB(points: objectPoints, surfaceY: surfaceY)
        
        // Send Result Back
        DispatchQueue.main.async {
            self.scannedDimensions?.wrappedValue = dims
        }
    }
}

// Helper: SIMD4 → SIMD3: Helper to pull xyz from a 4-component vector
extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3(x, y, z) }
}

// ARMeshGeometry vertex helper
// ARKit stores vertices in a raw MTLBuffer (Metal GPU memory) rather than a Swift array, because it needs to stream millions of points to the GPU efficiently.
// To read a single vertex in Swift we:
// (1) calculate the byte offset using the vertex index × stride (stride = bytes per vertex),
// (2) MOVE POINTER: get a raw pointer to that memory location,
// (3) tell Swift "treat these bytes as a SIMD3<Float>", and
// (4) Read value: dereference it with .pointee. This is called unsafe pointer arithmetic — fast but requires care.

extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        let vertexOffset = vertices.offset + Int(index) * vertices.stride // (1)
        return vertices.buffer.contents()
            .advanced(by: vertexOffset) // (2)
            .assumingMemoryBound(to: SIMD3<Float>.self) // (3)
            .pointee // (4)
    }
}
