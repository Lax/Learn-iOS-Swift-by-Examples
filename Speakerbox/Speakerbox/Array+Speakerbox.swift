/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Extension of Array for utility API
*/

extension Array {

    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows {
        guard let index = try index(where: predicate) else {
            return
        }

        remove(at: index)
    }

}
