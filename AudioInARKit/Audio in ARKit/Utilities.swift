/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// MARK: - Collection extensions

extension Array where Iterator.Element == float3 {
	var average: float3? {
		guard !self.isEmpty else {
			return nil
		}
		
		let sum = self.reduce(float3(0)) { current, next in
			return current + next
		}
		return sum / Float(self.count)
	}
}

extension RangeReplaceableCollection where IndexDistance == Int {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - float4x4 extensions

extension float4x4 {
	/// Treats matrix as a (right-hand column-major convention) transform matrix
	/// and factors out the translation component of the transform.
	var translation: float3 {
		let translation = self.columns.3
		return float3(translation.x, translation.y, translation.z)
	}
}

// MARK: - Math

func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
	
	let direction = simd_normalize(direction)
	
	// Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}
	
	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal
	
	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y
	
	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}
	
	// Return the intersection point.
	return rayOrigin + (direction * dist)
}

func worldPositionFromScreenPosition(_ position: CGPoint,
                                     in sceneView: ARSCNView,
                                     objectPos: float3?,
                                     infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
	
	// -------------------------------------------------------------------------------
	// 1. Always do a hit test against exisiting plane anchors first.
	//    (If any such anchors exist & only within their extents.)
	
	let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
	if let result = planeHitTestResults.first {
		
		let planeHitTestPosition = result.worldTransform.translation
		let planeAnchor = result.anchor
		
		// Return immediately - this is the best possible outcome.
		return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
	}
	
	// -------------------------------------------------------------------------------
	// 2. Collect more information about the environment by hit testing against
	//    the feature point cloud, but do not return the result yet.
	
	var featureHitTestPosition: float3?
	var highQualityFeatureHitTestResult = false
	
	let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
	
	if !highQualityfeatureHitTestResults.isEmpty {
		let result = highQualityfeatureHitTestResults[0]
		featureHitTestPosition = result.position
		highQualityFeatureHitTestResult = true
	}
	
	// -------------------------------------------------------------------------------
	// 3. If desired or necessary (no good feature hit test result): Hit test
	//    against an infinite, horizontal plane (ignoring the real world).
	
	if infinitePlane || !highQualityFeatureHitTestResult {
		
		if let pointOnPlane = objectPos {
			let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
			if pointOnInfinitePlane != nil {
				return (pointOnInfinitePlane, nil, true)
			}
		}
	}
	
	// -------------------------------------------------------------------------------
	// 4. If available, return the result of the hit test against high quality
	//    features if the hit tests against infinite planes were skipped or no
	//    infinite plane was hit.
	
	if highQualityFeatureHitTestResult {
		return (featureHitTestPosition, nil, false)
	}
	
	// -------------------------------------------------------------------------------
	// 5. As a last resort, perform a second, unfiltered hit test against features.
	//    If there are no features in the scene, the result returned here will be nil.
	
	let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
	if !unfilteredFeatureHitTestResults.isEmpty {
		let result = unfilteredFeatureHitTestResults[0]
		return (result.position, nil, false)
	}
	
	return (nil, nil, false)
}

func setNewVirtualObjectPosition(_ object: SCNNode, to pos: float3, cameraTransform: matrix_float4x4) {
	let cameraWorldPos = cameraTransform.translation
	var cameraToPosition = pos - cameraWorldPos
	
	// Limit the distance of the object from the camera to a maximum of 10 meters.
	if simd_length(cameraToPosition) > 10 {
		cameraToPosition = simd_normalize(cameraToPosition)
		cameraToPosition *= 10
	}
	
	object.simdPosition = cameraWorldPos + cameraToPosition
}
