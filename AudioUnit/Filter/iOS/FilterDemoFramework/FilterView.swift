/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View for the FilterDemo audio unit. This lets the user adjust the
            filter cutoff frequency and resonance on an X-Y grid.
*/

import UIKit

/*
    The `FilterViewDelegate` protocol is used to notify a delegate (`FilterDemoViewController`)
    when the user has changed the frequency or resonance by tapping and dragging
    in the graph.

    `filterViewDataDidChange(_:)` is called when the view size changes and new
    frequency data is available.
 */
protocol FilterViewDelegate: class {
    func filterView(_ filterView: FilterView, didChangeResonance resonance: Float)

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float)

    func filterView(_ filterView: FilterView, didChangeFrequency frequency: Float, andResonance resonance: Float)

    func filterViewDataDidChange(_ filterView: FilterView)
}

class FilterView: UIView {
    // MARK: Properties

    static let defaultMinHertz: Float = 12.0
    static let defaultMaxHertz: Float = 22_050.0

    let logBase = 2
    let leftMargin: CGFloat = 54.0
    let rightMargin: CGFloat = 10.0
    let bottomMargin: CGFloat = 40.0
    let numDBLines = 4
    let defaultGain = 20
    let gridLineCount = 11
    let labelWidth: CGFloat = 40.0
    let maxNumberOfResponseFrequencies = 1024

    var frequencies: [Double]?
    var dbLabels = [CATextLayer]()
    var frequencyLabels = [CATextLayer]()
    var dbLines = [CALayer]()
    var freqLines = [CALayer]()
    var controls = [CALayer]()

    var containerLayer = CALayer()
    var graphLayer = CALayer()
    var curveLayer: CAShapeLayer?

    // The delegate to notify of paramater and size changes.
    weak var delegate: FilterViewDelegate?

    var editPoint = CGPoint.zero
    var touchDown = false

    var resonance: Float = 0.0 {
        didSet {
            // Clamp the resonance to min/max values.
            if resonance > Float(defaultGain) {
                resonance = Float(defaultGain)
            } else if resonance < Float(-defaultGain) {
                resonance = Float(-defaultGain)
            }

            editPoint.y = floor(locationForDBValue(resonance))

            // Do not notify delegate that the resonance changed; that would create a feedback loop.
        }
    }

    var frequency: Float = FilterView.defaultMinHertz {
        didSet {
            if frequency > FilterView.defaultMaxHertz {
                frequency = FilterView.defaultMaxHertz
            } else if frequency < FilterView.defaultMinHertz {
                frequency = FilterView.defaultMinHertz
            }

            editPoint.x = floor(locationForFrequencyValue(frequency))

            // Do not notify delegate that the frequency changed; that would create a feedback loop.
        }
    }

    /*
		The frequencies are plotted on a logorithmic scale. This method returns a
		frequency value based on a fractional grid position.
	 */
    func valueAtGridIndex(_ index: Float) -> Float {
        return FilterView.defaultMinHertz * powf(Float(logBase), index)
    }

    func logValueForNumber(_ number: Float, base: Float) -> Float {
        return logf(number) / logf(base)
    }

	/*
		Prepares an array of frequencies that the AU needs to supply magnitudes for.
		This array is cached until the view size changes (on device rotation, etc).
	 */
	func frequencyDataForDrawing() -> [Double] {
        guard frequencies == nil else { return frequencies! }

        let width = graphLayer.bounds.width
        let rightEdge = width + leftMargin

        var pixelRatio = Int(ceil(width / CGFloat(maxNumberOfResponseFrequencies)))
        var location = leftMargin
        var locationsCount = maxNumberOfResponseFrequencies

        if pixelRatio <= 1 {
            pixelRatio = 1
            locationsCount = Int(width)
        }

        frequencies = (0..<locationsCount).map { _ in
            if location > rightEdge {
                return Double(FilterView.defaultMaxHertz)
            } else {
                var frequency = frequencyValueForLocation(location)

                if frequency > FilterView.defaultMaxHertz {
                    frequency = FilterView.defaultMaxHertz
                }

                location += CGFloat(pixelRatio)

                return Double(frequency)
            }
        }

        return frequencies!
    }

	/*
		Generates a bezier path from the frequency response curve data provided by
		the view controller. Also responsible for keeping the control point in sync.
	 */
    func setMagnitudes(_ magnitudeData: [Double]) {
        // If no curve layer exists, create one using the configuration closure.
        curveLayer = curveLayer ?? {
            let curveLayer = CAShapeLayer()

            curveLayer.fillColor = UIColor(red: 0.31, green: 0.37, blue: 0.73, alpha: 0.8).cgColor

            graphLayer.addSublayer(curveLayer)

            return curveLayer
        }()

        let bezierPath = CGMutablePath()
        let width = graphLayer.bounds.width

        bezierPath.move(to: CGPoint(x: leftMargin, y: graphLayer.frame.height + bottomMargin))

        var lastDBPos: CGFloat = 0.0

        var location: CGFloat = leftMargin

        let frequencyCount = frequencies?.count ?? 0

        let pixelRatio = Int(ceil(width / CGFloat(frequencyCount)))

        for i in 0 ..< frequencyCount {
            let dbValue = 20.0 * log10(magnitudeData[i])
            var dbPos: CGFloat = 0.0

            switch dbValue {
                case let x where x < Double(-defaultGain):
                    dbPos = locationForDBValue(Float(-defaultGain))

                case let x where x > Double(defaultGain):
                    dbPos = locationForDBValue(Float(defaultGain))

                default:
                    dbPos = locationForDBValue(Float(dbValue))
            }

            if fabs(lastDBPos - dbPos) >= 0.1 {
                bezierPath.addLine(to: CGPoint(x: location, y: dbPos))
            }

            lastDBPos = dbPos
            location += CGFloat(pixelRatio)

            if location > width + graphLayer.frame.origin.x {
                location = width + graphLayer.frame.origin.x
                break
            }
        }

        bezierPath.addLine(to: CGPoint(x: location,
                                       y: graphLayer.frame.origin.y +
                                          graphLayer.frame.height +
                                          bottomMargin))

        bezierPath.closeSubpath()

        // Turn off implict animation on the curve layer.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        curveLayer!.path = bezierPath
        CATransaction.commit()

        updateControls(true)
    }

    /*
		Calculates the pixel position on the y axis of the graph corresponding to
		the dB value.
	 */
    func locationForDBValue(_ value: Float) -> CGFloat {
        let step = graphLayer.frame.height / CGFloat(defaultGain * 2)

        let location = (CGFloat(value) + CGFloat(defaultGain)) * step

        return graphLayer.frame.height - location + bottomMargin
    }

    /*
        Calculates the pixel position on the x axis of the graph corresponding to
		the frequency value.
     */
    func locationForFrequencyValue(_ value: Float) -> CGFloat {
        let pixelIncrement = graphLayer.frame.width / CGFloat(gridLineCount)

        let number = value / Float(FilterView.defaultMinHertz)
        let location = logValueForNumber(number, base: Float(logBase)) * Float(pixelIncrement)

        return floor(CGFloat(location) + graphLayer.frame.origin.x) + 0.5
    }

	/*
		Calculates the dB value corresponding to a position value on the y axis of
		the graph.
	 */
    func dbValueForLocation(_ location: CGFloat) -> Float {
        let step = graphLayer.frame.height / CGFloat(defaultGain * 2)

        return Float(-(((location - bottomMargin) / step) - CGFloat(defaultGain)))
    }

    /*
		Calculates the frequency value corresponding to a position value on the x
		axis of the graph.
	 */
    func frequencyValueForLocation(_ location: CGFloat) -> Float {
        let pixelIncrement = graphLayer.frame.width / CGFloat(gridLineCount)

        let index = (location - graphLayer.frame.origin.x) / CGFloat(pixelIncrement)

        return valueAtGridIndex(Float(index))
    }

    /*
		Provides a properly formatted string with an appropriate precision for the
		input value.
	 */
    func stringForValue(_ value: Float) -> String {
       var temp = value

        if value >= 1000 {
            temp /= 1000
        }

        temp = floor((temp * 100.0) / 100.0)

        if floor(temp) == temp {
            return String(format: "%.0f", temp)
        } else {
            return String(format: "%.1f", temp)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Create all of the CALayers for the graph, lines, and labels.
        let scale = UIScreen.main.scale

        containerLayer.name = "container"
        containerLayer.anchorPoint = .zero
        containerLayer.frame = CGRect(origin: .zero, size: layer.bounds.size)
        containerLayer.bounds = containerLayer.frame
        containerLayer.contentsScale = scale
        layer.addSublayer(containerLayer)

        graphLayer.name = "graph background"
        graphLayer.borderColor = UIColor.darkGray.cgColor
        graphLayer.borderWidth = 1.0
        graphLayer.backgroundColor = UIColor(white: 0.88, alpha: 1.0).cgColor
        graphLayer.bounds = CGRect(x: 0, y: 0,
                                   width: layer.frame.width - leftMargin,
                                   height: layer.frame.height - bottomMargin)
        graphLayer.position = CGPoint(x: leftMargin, y: 0)
        graphLayer.anchorPoint = CGPoint.zero
        graphLayer.contentsScale = scale

        containerLayer.addSublayer(graphLayer)

        layer.contentsScale = scale

        createDBLabelsAndLines()
        createFrequencyLabelsAndLines()
        createControlPoint()
    }

    /*
		Creates the decibel label layers for the vertical axis of the graph and adds
		them as sublayers of the graph layer. Also creates the db Lines.
	 */
    func createDBLabelsAndLines() {
        var value: Int
        let scale = layer.contentsScale

        for index in -numDBLines...numDBLines {
            value = index * (defaultGain / numDBLines)

            if index >= -numDBLines && index <= numDBLines {
                let labelLayer = CATextLayer()

                // Create the label layers and set their properties.
                labelLayer.string = "\(value) db"
                labelLayer.name = String(index)
                labelLayer.font = UIFont.systemFont(ofSize: 14).fontName as CFTypeRef
                labelLayer.fontSize = 14
                labelLayer.contentsScale = scale
                labelLayer.foregroundColor = UIColor(white: 0.1, alpha: 1.0).cgColor
                labelLayer.alignmentMode = kCAAlignmentRight

                dbLabels.append(labelLayer)
                containerLayer.addSublayer(labelLayer)

                // Create the line labels.
                let lineLayer = CALayer()

                if index == 0 {
                    lineLayer.backgroundColor = UIColor(white: 0.65, alpha: 1.0).cgColor
                } else {
                    lineLayer.backgroundColor = UIColor(white: 0.8, alpha: 1.0).cgColor
                }

                dbLines.append(lineLayer)

                graphLayer.addSublayer(lineLayer)
            }
        }
    }

	/*
		Creates the frequency label layers for the horizontal axis of the graph and
		adds them as sublayers of the graph layer. Also creates the frequency line
        layers.
	 */
    func createFrequencyLabelsAndLines() {
        var value: Float

        var firstK = true

        let scale = layer.contentsScale

        for index in 0 ... gridLineCount {
            value = valueAtGridIndex(Float(index))

            // Create the label layers and set their properties.
            let labelLayer = CATextLayer()
            labelLayer.font = UIFont.systemFont(ofSize: 14).fontName as CFTypeRef
            labelLayer.foregroundColor = UIColor(white: 0.1, alpha: 1.0).cgColor
            labelLayer.fontSize = 14
            labelLayer.alignmentMode = kCAAlignmentCenter
            labelLayer.contentsScale = scale
            labelLayer.anchorPoint = CGPoint.zero

            frequencyLabels.append(labelLayer)

            // Create the line layers.
            if index > 0 && index < gridLineCount {
                let lineLayer: CALayer = CALayer()
                lineLayer.backgroundColor = UIColor(white: 0.8, alpha: 1.0).cgColor
                freqLines.append(lineLayer)
                graphLayer.addSublayer(lineLayer)

                var s = stringForValue(value)

                if value >= 1000 && firstK {
                    s += "K"
                    firstK = false
                }

                labelLayer.string = s
            } else if index == 0 {
                labelLayer.string = "\(stringForValue(value)) Hz"
            } else {
                labelLayer.string = "\(stringForValue(FilterView.defaultMaxHertz)) K"
            }

            containerLayer.addSublayer(labelLayer)
        }
    }

	/*
		Creates the control point layers comprising of a horizontal and vertical
		line (crosshairs) and a circle at the intersection.
	 */
    func createControlPoint() {
        var lineLayer = CALayer()
        let controlColor = touchDown ? tintColor.cgColor: UIColor.darkGray.cgColor

        lineLayer.backgroundColor = controlColor
        lineLayer.name = "x"
        controls.append(lineLayer)
        graphLayer.addSublayer(lineLayer)

        lineLayer = CALayer()
        lineLayer.backgroundColor = controlColor
        lineLayer.name = "y"
        controls.append(lineLayer)
        graphLayer.addSublayer(lineLayer)

        let circleLayer = CALayer()
        circleLayer.borderColor = controlColor
        circleLayer.borderWidth = 2.0
        circleLayer.cornerRadius = 3.0
        circleLayer.name = "point"
        controls.append(circleLayer)

        graphLayer.addSublayer(circleLayer)
    }

    /*
        Updates the position of the control layers and the color if the refreshColor
        parameter is true. The controls are drawn in a blue color if the user's finger
        is touching the graph and still down.
     */
    func updateControls(_ refreshColor: Bool) {
        let color = touchDown ? tintColor.cgColor: UIColor.darkGray.cgColor

        // Turn off implicit animations for the control layers to avoid any control lag.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for layer in controls {
            switch layer.name! {
                case "point":
                    layer.frame = CGRect(x: editPoint.x - 3, y: editPoint.y - 3, width: 7, height: 7).integral
                    layer.position = editPoint

                    if refreshColor {
                        layer.borderColor = color
                    }

                case "x":
                    layer.frame = CGRect(x: graphLayer.frame.origin.x,
                                         y: floor(editPoint.y + 0.5),
                                         width: graphLayer.frame.width,
                                         height: 1.0)

                    if refreshColor {
                        layer.backgroundColor = color
                    }

                case "y":
                    layer.frame = CGRect(x: floor(editPoint.x) + 0.5,
                                         y: bottomMargin,
                                         width: 1.0,
                                         height: graphLayer.frame.height)

                    if refreshColor {
                        layer.backgroundColor = color
                    }

                default:
                    layer.frame = CGRect.zero
            }
        }

        CATransaction.commit()
    }

    func updateDBLayers() {
 		// Update the positions of the dBLine and label layers.

       for index in -numDBLines...numDBLines {
            let location = floor(locationForDBValue(Float(index * (defaultGain / numDBLines))))

            if index >= -numDBLines && index <= numDBLines {
                dbLines[index + 4].frame = CGRect(x: graphLayer.frame.origin.x,
                                                  y: location,
                                                  width: graphLayer.frame.width,
                                                  height: 1.0)

                dbLabels[index + 4].frame = CGRect(x: 0.0,
                                                   y: location - bottomMargin - 8,
                                                   width: leftMargin - 7.0,
                                                   height: 16.0)
            }
        }
    }

    func updateFrequencyLayers() {
    	// Update the positions of the frequency line and label layers.

        for index in 0...gridLineCount {
            let value = valueAtGridIndex(Float(index))
            let location = floor(locationForFrequencyValue(value))

            if index > 0 && index < gridLineCount {
                freqLines[index - 1].frame = CGRect(x: location,
                                                    y: bottomMargin,
                                                    width: 1.0,
                                                    height: graphLayer.frame.height)

                frequencyLabels[index].frame = CGRect(x: location - labelWidth / 2.0,
                                                      y: graphLayer.frame.height,
                                                      width: labelWidth,
                                                      height: 16.0)
            }

            frequencyLabels[index].frame = CGRect(x: location - labelWidth / 2.0,
                                                  y: graphLayer.frame.height + 6,
                                                  width: labelWidth + rightMargin,
                                                  height: 16.0)
        }
    }

	/*
		This function positions all of the layers of the view starting with
		the horizontal dbLines and lables on the y axis. Next, it positions
		the vertical frequency lines and labels on the x axis. Finally, it
		positions the controls and the curve layer.

		This method is also called when the orientation of the device changes
		and the view needs to re-layout for the new view size.
	 */
	override func layoutSublayers(of layer: CALayer) {
        if layer === self.layer {
            // Disable implicit layer animations.
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            containerLayer.bounds = layer.bounds

            graphLayer.bounds = CGRect(x: leftMargin, y: bottomMargin,
                                       width: layer.bounds.width - leftMargin - rightMargin,
                                       height: layer.bounds.height - bottomMargin - 10.0)

            updateDBLayers()

            updateFrequencyLayers()

            editPoint = CGPoint(x: locationForFrequencyValue(frequency), y: locationForDBValue(resonance))

            if let curveLayer = curveLayer {
                curveLayer.bounds = graphLayer.bounds

                curveLayer.frame = CGRect(x: graphLayer.frame.origin.x,
                                          y: graphLayer.frame.origin.y + bottomMargin,
                                          width: graphLayer.frame.width,
                                          height: graphLayer.frame.height)
            }

            CATransaction.commit()
        }

        updateControls(false)

        frequencies = nil

        /*
            Notify view controller that our bounds has changed -- meaning that new
            frequency data is available.
        */
        delegate?.filterViewDataDidChange(self)
    }

    /*
        If either the frequency or resonance (or both) change, notify the delegate
        as appropriate.
    */
    func updateFrequenciesAndResonance() {
        let lastFrequency = frequencyValueForLocation(editPoint.x)
        let lastResonance = dbValueForLocation(editPoint.y)

        if lastFrequency != frequency && lastResonance != resonance {
            frequency = lastFrequency
            resonance = lastResonance

            // Notify delegate that frequency changed.
            delegate?.filterView(self, didChangeFrequency: frequency, andResonance: resonance)
        }

        if lastFrequency != frequency {
            frequency = lastFrequency

            // Notify delegate that frequency changed.
            delegate?.filterView(self, didChangeFrequency: frequency)
        }

        if lastResonance != resonance {
            resonance = lastResonance

            // Notify delegate that resonance changed.
            delegate?.filterView(self, didChangeResonance: resonance)
        }
    }

    // MARK: Touch Event Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var pointOfTouch = touches.first?.location(in: self) else { return }

        pointOfTouch = CGPoint(x: pointOfTouch.x, y: pointOfTouch.y + bottomMargin)

        if graphLayer.contains(pointOfTouch) {
            touchDown = true
            editPoint = pointOfTouch

            updateFrequenciesAndResonance()
         }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var pointOfTouch = touches.first?.location(in: self) else { return }

        pointOfTouch = CGPoint(x: pointOfTouch.x, y: pointOfTouch.y + bottomMargin)

        if graphLayer.contains(pointOfTouch) {
            processTouch(pointOfTouch)

            updateFrequenciesAndResonance()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var pointOfTouch = touches.first?.location(in: self) else { return }

        pointOfTouch = CGPoint(x: pointOfTouch.x, y: pointOfTouch.y + bottomMargin)

        if graphLayer.contains(pointOfTouch) {
            processTouch(pointOfTouch)
        }

        touchDown = false

        updateFrequenciesAndResonance()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchDown = false
    }

    func processTouch(_ touchPoint: CGPoint) {
        if touchPoint.x < 0 {
            editPoint.x = 0
        } else if touchPoint.x > graphLayer.frame.width + leftMargin {
            editPoint.x = graphLayer.frame.width + leftMargin
        } else {
            editPoint.x = touchPoint.x
        }

        if touchPoint.y < 0 {
            editPoint.y = 0
        } else if touchPoint.y > graphLayer.frame.height + bottomMargin {
            editPoint.y = graphLayer.frame.height + bottomMargin
        } else {
            editPoint.y = touchPoint.y
        }
    }
}
