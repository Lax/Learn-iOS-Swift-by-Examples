/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Convenience extensions on ARSCNView for hit testing
*/

import ARKit

extension ARSCNView {
	
	// MARK: - Types
	
	struct HitTestRay {
		let origin: float3
		let direction: float3
	}
	
	struct FeatureHitTestResult {
		let position: float3
		let distanceToRayOrigin: Float
		let featureHit: float3
		let featureDistanceToHitResult: Float
	}
	
	func unprojectPoint(_ point: float3) -> float3 {
		return float3(self.unprojectPoint(SCNVector3(point)))
	}
	
	// MARK: - Hit Tests
	
	func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
		
		guard let frame = self.session.currentFrame else {
			return nil
		}
		
		let cameraPos = frame.camera.transform.translation
		
		// Note: z: 1.0 will unproject() the screen position to the far clipping plane.
		let positionVec = float3(x: Float(point.x), y: Float(point.y), z: 1.0)
		let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
		
		let rayDirection = simd_normalize(screenPosOnFarClippingPlane - cameraPos)
		return HitTestRay(origin: cameraPos, direction: rayDirection)
	}
	
	func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return nil
		}
		
		// Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
		if ray.direction.y > -0.03 {
			return nil
		}
		
		// Return the intersection of a ray from the camera through the screen position with a horizontal plane
		// at height (Y axis).
		return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
	}
	
	func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
	                         minDistance: Float = 0,
	                         maxDistance: Float = Float.greatestFiniteMagnitude,
	                         maxResults: Int = 1) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return results
		}
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
		let maxAngle = (maxAngleInDeg / 180) * .pi
		
		let points = features.__points
		
		for i in 0...features.__count {
			
			let feature = points.advanced(by: Int(i))
			let featurePos = feature.pointee
			
			let originToFeature = featurePos - ray.origin
			
			let crossProduct = simd_cross(originToFeature, ray.direction)
			let featureDistanceFromResult = simd_length(crossProduct)
			
			let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
			let hitTestResultDistance = simd_length(hitTestResult - ray.origin)
			
			if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
				// Skip this feature - it is too close or too far away.
				continue
			}
			
			let originToFeatureNormalized = simd_normalize(originToFeature)
			let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))
			
			if angleBetweenRayAndFeature > maxAngle {
				// Skip this feature - is is outside of the hit test cone.
				continue
			}
			
			// All tests passed: Add the hit against this feature to the results.
			results.append(FeatureHitTestResult(position: hitTestResult,
			                                    distanceToRayOrigin: hitTestResultDistance,
			                                    featureHit: featurePos,
			                                    featureDistanceToHitResult: featureDistanceFromResult))
		}
		
		// Sort the results by feature distance to the ray.
		results = results.sorted(by: { (first, second) -> Bool in
			return first.distanceToRayOrigin < second.distanceToRayOrigin
		})
		
		// Cap the list to maxResults.
		var cappedResults = [FeatureHitTestResult]()
		var i = 0
		while i < maxResults && i < results.count {
			cappedResults.append(results[i])
			i += 1
		}
		
		return cappedResults
	}
	
	func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
			results.append(result)
		}
		
		return results
	}
	
	func hitTestFromOrigin(origin: float3, direction: float3) -> FeatureHitTestResult? {
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return nil
		}
		
		let points = features.__points
		
		// Determine the point from the whole point cloud which is closest to the hit test ray.
		var closestFeaturePoint = origin
		var minDistance = Float.greatestFiniteMagnitude
		
		for i in 0...features.__count {
			let feature = points.advanced(by: Int(i))
			let featurePos = feature.pointee
			
			let originVector = origin - featurePos
			let crossProduct = simd_cross(originVector, direction)
			let featureDistanceFromResult = simd_length(crossProduct)
			
			if featureDistanceFromResult < minDistance {
				closestFeaturePoint = featurePos
				minDistance = featureDistanceFromResult
			}
		}
		
		// Compute the point along the ray that is closest to the selected feature.
		let originToFeature = closestFeaturePoint - origin
		let hitTestResult = origin + (direction * simd_dot(direction, originToFeature))
		let hitTestResultDistance = simd_length(hitTestResult - origin)
		
		return FeatureHitTestResult(position: hitTestResult,
		                            distanceToRayOrigin: hitTestResultDistance,
		                            featureHit: closestFeaturePoint,
		                            featureDistanceToHitResult: minDistance)
	}
}
