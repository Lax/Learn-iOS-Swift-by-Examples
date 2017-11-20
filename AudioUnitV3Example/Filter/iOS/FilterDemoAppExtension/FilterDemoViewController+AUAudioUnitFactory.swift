/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
FilterDemoViewController is the app extension's principal class,
            responsible for creating both the audio unit and its view.
*/

import CoreAudioKit
import FilterDemoFramework

extension FilterDemoViewController: AUAudioUnitFactory {
    /*
        This implements the required 'AUAudioUnitFactory' protocol method.
        When this view controller is instantiated in an extension process, it
        creates its audio unit.
    */
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try AUv3FilterDemo(componentDescription: componentDescription, options: [])
        audioUnit?.filterDemoViewController = self
        return audioUnit!
    }
}
