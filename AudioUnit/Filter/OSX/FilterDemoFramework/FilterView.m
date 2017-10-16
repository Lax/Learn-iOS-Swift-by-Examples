/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View for the FilterDemo audio unit. This lets the user adjust the filter cutoff frequency and resonance on an X-Y grid.
*/

#import "FilterView.h"
#import <QuartzCore/CATextLayer.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAShapeLayer.h>
#import <QuartzCore/CATransaction.h>

#define kDefaultMinHertz 12.0f
#define kDefaultMaxHertz 22050.0f
#define kLogBase 2

#define kLeftMargin 54.0
#define kRightMargin 10.0
#define kBottomMargin 20.0
#define kNumDBLines 4
#define kDefaultGain 20
#define kGridLineCount 11
#define kLabelWidth 40.0

#define kMaxNumberOfResponseFrequencies 1024

@interface FilterView () {
    float mRes;
    float mFreq;
    
    NSMutableArray<NSNumber*>*      frequencies;
    NSMutableArray<CATextLayer*>*   dbLabels;
    NSMutableArray<CATextLayer*>*   freqLabels;
    
    NSMutableArray<CALayer*>*       dbLines;
    NSMutableArray<CALayer*>*       freqLines;
    NSMutableArray<CALayer*>*       controls;
    
    CALayer         *containerLayer;
    CALayer         *graphLayer;
    CAShapeLayer    *curveLayer;
        
    CGPoint editPoint;
    BOOL    mMouseDown;
}
@end

static double valueAtGridIndex(double index) {
    return kDefaultMinHertz * pow(kLogBase, index);
}

static double logValueForNumber(double number, double base) {
    return log(number) / log(base);
}

@implementation FilterView

-(void)dealloc {
    NSLog(@"FilterView Dealloc\n");
}

-(void)awakeFromNib {
    editPoint = CGPointZero;
    
    dbLabels = [NSMutableArray arrayWithCapacity: 9];
    freqLabels =    dbLabels = [NSMutableArray arrayWithCapacity: 9];
    freqLabels = [NSMutableArray arrayWithCapacity: 12];
    dbLines = [NSMutableArray arrayWithCapacity: 8];
    freqLines = [NSMutableArray arrayWithCapacity: 10];
    controls = [NSMutableArray arrayWithCapacity: 3];
    
    containerLayer = [CALayer layer];
    containerLayer.name = @"container";
    containerLayer.anchorPoint = CGPointZero;
    containerLayer.frame = CGRectMake(0, 0, self.layer.bounds.size.width, self.layer.bounds.size.height);
    containerLayer.bounds = containerLayer.frame;
    [self.layer addSublayer: containerLayer];

    graphLayer = [CALayer layer];
    graphLayer.name = @"graph background";
    graphLayer.borderColor = [NSColor darkGrayColor].CGColor;
    graphLayer.borderWidth = 1.0f;
    graphLayer.backgroundColor = [NSColor colorWithDeviceWhite: .88 alpha: 1.0].CGColor;
    graphLayer.bounds = CGRectMake(0, 0, self.layer.frame.size.width - kLeftMargin, self.layer.frame.size.height - kBottomMargin);
    graphLayer.position = CGPointMake(kLeftMargin, 0);
    graphLayer.anchorPoint = CGPointZero;

    [containerLayer addSublayer: graphLayer];
    
    [self createDBLabelsAndLines];
    [self createFrequencyLabelsAndLines];
    [self createControlPoint];

    // This should be called implicity, but it is not
    [self layoutSublayersOfLayer:self.layer];
}

-(void) viewDidMoveToWindow {
    // set the scale factor of the text layers once the view has been added to a window
    
    if (self.window != nil) {
        CGFloat scale = self.window.backingScaleFactor;
        
        if (scale != 1.0) {
            for (CALayer *layer in dbLabels) {
                layer.contentsScale = scale;
            }
            
            for (CALayer *layer in freqLabels) {
                layer.contentsScale = scale;
            }
        }
    }
}

/* Update the edit point based on the new resonance value */
-(void) setResonance: (float) res {
    mRes = res;
    if (mRes > kDefaultGain)
        mRes = kDefaultGain;
    else if (mRes < -kDefaultGain)
        mRes = -kDefaultGain;
    
    editPoint.y = floor([self locationForDBValue: mRes]);
    
    [self updateControlsRefreshingColor: NO];
}

/* Update the edit point based on the new frequency value */
-(void) setFrequency: (float) freq {
    mFreq = freq;
    
    if (mFreq > kDefaultMaxHertz)
        mFreq = kDefaultMaxHertz;
    else if (mFreq < kDefaultMinHertz)
        mFreq = kDefaultMinHertz;
    
    editPoint.x = floor([self locationForFrequencyValue: mFreq]);
    
    [self updateControlsRefreshingColor: NO];
}

/* Get the resonance value */
-(float)resonance {
    return mRes;
}

/* Get the frequency value */
-(float)frequency {
    return mFreq;
}

@synthesize delegate;

/*
 Prepares an array of g that the AU needs to supply magnitudes for.
 This array is cached until the view size changes.
 */
-(NSArray<NSNumber*>*)frequencyDataForDrawing {
    if (!frequencies) {
        CGFloat width = graphLayer.bounds.size.width;
        int     i, pixelRatio = (int) ceil(width/kMaxNumberOfResponseFrequencies);
        CGFloat location = 0;
        int     numLocations = kMaxNumberOfResponseFrequencies;

        if (pixelRatio <= 1) {
            pixelRatio = 1;
            numLocations = width;
        }
        
        frequencies = [NSMutableArray arrayWithCapacity:numLocations];
        
        for (i=0; i < numLocations; i++) {
            if (location > width)
                [frequencies addObject: @(kDefaultMaxHertz)];
            else {
                double freq = [self frequencyValueForLocation: location];
                if (freq > kDefaultMaxHertz)
                    freq = kDefaultMaxHertz;
                [frequencies addObject: @(freq)];
            }
            location += pixelRatio;
        }
    }
    
    return [NSArray arrayWithArray: frequencies];
}

/*
 Generates a bezier path from the frequency response curve data provided by
 the view controller. Also responsible for keeping the control point in sync.
 */
-(void)setMagnitudes:(NSArray<NSNumber *> *) magnitudes {
    if (!curveLayer) {
        curveLayer = [CAShapeLayer layer];
        curveLayer.fillColor = [NSColor colorWithDeviceRed: .31 green: .37 blue: .73 alpha: .8].CGColor;
        curveLayer.anchorPoint = CGPointZero;
        
        [graphLayer addSublayer: curveLayer];
    }
    
    CGMutablePathRef bezierPath = CGPathCreateMutable();
    CGFloat          width = graphLayer.bounds.size.width;
    
    CGPathMoveToPoint(bezierPath, nil, 0, 0);
    
    CGFloat location = 0;
    NSUInteger frequencyCount = frequencies.count;
    int pixelRatio = (int)ceil(width/frequencyCount);
    
    float dbPos = 0;
    for (int i = 0; i < frequencies.count; i++) {
        float dbValue = 20.0f * log10(magnitudes[i].doubleValue);

        if (dbValue < -kDefaultGain)
            dbPos = [self locationForDBValue: -kDefaultGain];
        else if (dbValue > kDefaultGain)
            dbPos = [self locationForDBValue: kDefaultGain];
        else
            dbPos = [self locationForDBValue: dbValue];
        
        CGPathAddLineToPoint(bezierPath, nil, location, dbPos);
        location += pixelRatio;
       
        if (location > width) {
            location = width;
            break;
        }
    }
    
    CGPathAddLineToPoint(bezierPath, nil, location, 0);
    CGPathCloseSubpath(bezierPath);
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    curveLayer.path = bezierPath;
    [CATransaction commit];
    
    CGPathRelease(bezierPath);
    
    [self updateControlsRefreshingColor: YES];
}

/*
 Calculates the pixel position on the y axis of the graph corresponding to
 the dB value.
 */
-(double) locationForDBValue: (double) value {
    double step		= graphLayer.frame.size.height / (kDefaultGain * 2);
    double location = (value + kDefaultGain) * step;
    
    return location;
}

/*
 Calculates the pixel position on the x axis of the graph corresponding to
 the frequency value.
 */
-(double) locationForFrequencyValue: (double) value {
    // how many pixels are in one base power increment?
    double pixelIncrement = graphLayer.frame.size.width / kGridLineCount;
    double location = logValueForNumber(value/kDefaultMinHertz, kLogBase) * pixelIncrement;
    
    location = floor(location) + .5;
    return location;
}

/*
 Calculates the dB value corresponding to a position value on the y axis of
 the graph.
 */
-(double) dbValueForLocation: (float) location {
    double step	= graphLayer.frame.size.height / (kDefaultGain * 2);// number of pixels per db
    return (location / step) - kDefaultGain;
}

/*
 Calculates the frequency value corresponding to a position value on the x
 axis of the graph.
 */
- (double) frequencyValueForLocation: (float) location {
    double pixelIncrement = graphLayer.frame.size.width / kGridLineCount;
    
    return valueAtGridIndex(location/pixelIncrement);
}

/*
 Provides a properly formatted string with an appropriate precision for the
 input value.
 */
-(NSString *) stringForValue:(double) value {
    NSString * theString;
    double temp = value;
    
    if (value >= 1000)
        temp = temp / 1000;
    
    temp = (floor(temp *100))/100;	// chop everything after 2 decimal places
    // we don't want trailing 0's
    
    //if we do not have trailing zeros
    if (floor(temp) == temp)
        theString = [NSString localizedStringWithFormat: @"%.0f", temp];
    else 	// if we have only one digit
        theString = [NSString localizedStringWithFormat: @"%.1f", temp];
    
    return theString;
}

/*
 Creates the decibel label layers for the vertical axis of the graph and adds
 them as sublayers of the graph layer. Also creates the db Lines.
 */
-(void) createDBLabelsAndLines {
    int index, value;

    for (index = -kNumDBLines; index <= kNumDBLines; index++) {
        value = index * (kDefaultGain / kNumDBLines);
        
        if (index >= -kNumDBLines && index <= kNumDBLines) {
            CATextLayer *labelLayer = [CATextLayer new];
            labelLayer.string = [NSString localizedStringWithFormat: @"%d db", value];
            labelLayer.name = [NSString stringWithFormat: @"%d", index];
            labelLayer.font = (__bridge CFTypeRef __nullable)([[NSFont systemFontOfSize: 10] fontName]);
            labelLayer.fontSize = 10;

            labelLayer.foregroundColor = [NSColor colorWithCalibratedWhite: .1 alpha: 1.0].CGColor;
            labelLayer.alignmentMode = kCAAlignmentRight;

            [dbLabels addObject: labelLayer];
            [containerLayer addSublayer: labelLayer];
            
            // Create the line labels.
            CALayer *lineLayer = [CALayer layer];
            if (index == 0)
                lineLayer.backgroundColor = [NSColor colorWithDeviceWhite: .65 alpha: 1].CGColor;
            else
                lineLayer.backgroundColor = [NSColor colorWithDeviceWhite: .8 alpha: 1].CGColor;
            [dbLines addObject: lineLayer];
            
            [graphLayer addSublayer: lineLayer];
        }
    }
}

/*
 Creates the frequency label layers for the horizontal axis of the graph and
 adds them as sublayers of the graph layer. Also creates the frequency line
 layers.
 */
-(void) createFrequencyLabelsAndLines {
    int     index;
    double  value;
    BOOL    firstK = YES;
    
    for (index = 0; index <= kGridLineCount; index++) {
        value = valueAtGridIndex(index);
        
        CATextLayer *labelLayer = [CATextLayer new];
        labelLayer.name = [NSString stringWithFormat: @"%d", index];
        labelLayer.font = (__bridge CFTypeRef __nullable)([[NSFont systemFontOfSize: 10] fontName]);
        labelLayer.fontSize = 10;
        labelLayer.foregroundColor = [NSColor colorWithCalibratedWhite: .1 alpha: 1.0].CGColor;
        labelLayer.alignmentMode = kCAAlignmentCenter;
        
        [freqLabels addObject: labelLayer];
        
        if (index > 0 && index < kGridLineCount) {
            CALayer *lineLayer = [CALayer layer];
            lineLayer.backgroundColor = [NSColor colorWithDeviceWhite: .8 alpha: 1].CGColor;
            [freqLines addObject: lineLayer];
            [graphLayer addSublayer: lineLayer];
            
            NSString *s = [self stringForValue: value];
            if (value >= 1000 && firstK) {
                s = [s stringByAppendingString: @"K"];
                firstK = NO;
            }
            labelLayer.string = s;
        } else if (index == 0) {
            labelLayer.string = [[self stringForValue: value] stringByAppendingString: @"Hz"];
        } else {
            labelLayer.string = [[self stringForValue: kDefaultMaxHertz] stringByAppendingString: @"K"];
        }
        [containerLayer addSublayer: labelLayer];
    }
}

/*
 Creates the control point layers comprising of a horizontal and vertical
 line (crosshairs) and a circle at the intersection.
 */
-(void) createControlPoint {
    // create horizontal line
    CALayer *lineLayer = [CALayer layer];
    lineLayer.backgroundColor = mMouseDown ? [NSColor blueColor].CGColor : [NSColor darkGrayColor].CGColor;
    lineLayer.name = @"x";
    [controls addObject: lineLayer];
    [graphLayer addSublayer: lineLayer];
    
    // create vertical line
    lineLayer = [CALayer layer];
    lineLayer.backgroundColor = mMouseDown ? [NSColor blueColor].CGColor : [NSColor grayColor].CGColor;
    lineLayer.name = @"y";
    [controls addObject: lineLayer];
    [graphLayer addSublayer: lineLayer];
    
    //create cicle
    CALayer *circleLayer = [CALayer layer];
    circleLayer.borderColor = mMouseDown ? [NSColor blueColor].CGColor : [NSColor darkGrayColor].CGColor;
    circleLayer.borderWidth = 2.0f;
    circleLayer.cornerRadius = 3.0f;
    circleLayer.name = @"point";
    [controls addObject: circleLayer];
    [graphLayer addSublayer: circleLayer];
}

/*
 Updates the position of the control layers and the color if the refreshColor
 parameter is true. The controls are drawn in a blue color if the mouse is down.
 */
-(void) updateControlsRefreshingColor: (BOOL) refreshColor {
    CGColorRef color= mMouseDown ? [NSColor blueColor].CGColor : [NSColor darkGrayColor].CGColor;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    for (CALayer *layer in controls) {
        if ([layer.name isEqualToString: @"point"]) {
            layer.frame = CGRectMake(editPoint.x - 3, editPoint.y - 3, 8, 8);
            layer.position = editPoint;
            if (refreshColor)
                layer.borderColor = color;
        } else if ([layer.name isEqualToString: @"x"]) {
            layer.frame = CGRectMake(0, floorf(editPoint.y + .5), graphLayer.frame.size.width, 1);
            if (refreshColor)
                layer.backgroundColor = color;
        } else if ([layer.name isEqualToString: @"y"]) {
            layer.frame = CGRectMake(floorf(editPoint.x + .5), 0, 1, graphLayer.frame.size.height);
            if (refreshColor)
                layer.backgroundColor = color;
        }
    }
    [CATransaction commit];
}

-(void) updateDBLayers {
    // update the dbLines and labels
    int index;
    for (index = -kNumDBLines; index <= kNumDBLines; index++) {
        CGFloat location = floorf([self locationForDBValue: index * (kDefaultGain/kNumDBLines)]);
        if (index >= -kNumDBLines && index <= kNumDBLines) {
            ((CALayer *)(dbLines[index+4])).frame = CGRectMake(0, location, graphLayer.frame.size.width, 1);
            ((CALayer *)(dbLabels[index+4])).frame = CGRectMake(0, location + graphLayer.frame.origin.y - 5, kLeftMargin - 7, 12);
        }
    }
}

-(void) updateFrequencyLayers {
    for (UInt32 index = 0; index <= kGridLineCount; index++) {
        double value    = valueAtGridIndex(index);
        double location = floorf([self locationForFrequencyValue: value]);
        
        if (index > 0 && index < kGridLineCount) {
            ((CALayer *)(freqLines[index-1])).frame = CGRectMake(location, 0, 1, graphLayer.frame.size.height);
            ((CALayer *)(freqLabels[index])).frame = CGRectMake(location + graphLayer.frame.origin.x - kLabelWidth/2, 0, kLabelWidth, 12);
        }
        if (index == 0) {
            ((CALayer *)(freqLabels[0])).frame = CGRectMake(location + graphLayer.frame.origin.x - kLabelWidth/2, 0, kLabelWidth, 12);
        } else {
            ((CALayer *)(freqLabels[index])).frame = CGRectMake(location + graphLayer.frame.origin.x - kLabelWidth/2 - 12, 0, kLabelWidth + kRightMargin, 12);
        }
    }
}

/*
 This function positions all of the layers of the view starting with
 the horizontal dbLines and lables on the y axis. Next, it positions
 the vertical frequency lines and labels on the x axis. Finally, it
 positions the controls and the curve layer.
 
 This method is also called when the view needs to re-layout for the new view size.
 */
-(void) layoutSublayersOfLayer:(CALayer *)layer {
    if (layer == self.layer) {
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        
        containerLayer.bounds = layer.bounds;
        graphLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width - kLeftMargin - kRightMargin, layer.bounds.size.height - kBottomMargin - 10);
        graphLayer.position = CGPointMake(kLeftMargin, kBottomMargin);
        
        [self updateDBLayers];
        
        [self updateFrequencyLayers];
        
        editPoint = CGPointMake([self locationForFrequencyValue: mFreq], [self locationForDBValue: mRes]);
        
        if (curveLayer) {
            curveLayer.bounds = graphLayer.bounds;
            
            curveLayer.frame = CGRectMake(0, 0, graphLayer.frame.size.width, graphLayer.frame.size.height);
        }
        
        [CATransaction commit];
    }
    
    [self updateControlsRefreshingColor: NO];
    
    frequencies = nil;
    
    [delegate filterViewDataDidChange: self];
}

#pragma mark: Event Handling

-(void) mouseDown:(NSEvent * __nonnull)theEvent {
    CGPoint pointOfClick = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    
    if ([graphLayer hitTest: pointOfClick]) {        
        CGPoint layerPoint = [self.layer convertPoint:pointOfClick toLayer: graphLayer];
        
        mMouseDown = YES;
        editPoint = layerPoint;
        
        [self updateControlsRefreshingColor: YES];
        [self updateFreqAndRes];
    }
}

-(void) mouseDragged:(NSEvent * __nonnull)theEvent {
    CGPoint pointOfClick = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CGPoint layerPoint = [self.layer convertPoint: pointOfClick toLayer: graphLayer];
    
    CGPoint newPoint = layerPoint;
    
    if (newPoint.x < 0)
        newPoint.x = 0;
    else if (newPoint.x > graphLayer.bounds.size.width)
        newPoint.x = graphLayer.bounds.size.width;
    
    if (newPoint.y < 0)
        newPoint.y = 0;
    else if (newPoint.y > graphLayer.bounds.size.height)
        newPoint.y = graphLayer.bounds.size.height;
    
    if (!CGPointEqualToPoint(newPoint, editPoint)) {
        editPoint = newPoint;
        [self updateControlsRefreshingColor: NO];
        [self updateFreqAndRes];
    }
}

-(void) mouseUp:(NSEvent * __nonnull)theEvent {
    mMouseDown = NO;
    
    CGColorRef color= [NSColor darkGrayColor].CGColor;
    for (CALayer *layer in controls) {
        if ([layer.name isEqualToString: @"point"])
            layer.borderColor = color;
        else
            layer.backgroundColor = color;
    }
}

-(void)updateFreqAndRes {
    double lastFrequency = [self frequencyValueForLocation: editPoint.x];
    
    if (lastFrequency != mFreq) {
        mFreq = lastFrequency;
    
        [delegate filterViewDidChange: self frequency: mFreq];
    }
 
    double lastResonance = [self dbValueForLocation: editPoint.y];
    
    if (lastResonance != mRes) {
        mRes = lastResonance;
        
        [delegate filterViewDidChange: self resonance: mRes];
    }
}

@end
