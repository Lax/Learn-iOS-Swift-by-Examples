/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View for the FilterDemo audio unit. This lets the user adjust the filter cutoff frequency and resonance on an X-Y grid.
*/

#import <Cocoa/Cocoa.h>

@class FilterView;

@protocol FilterViewDelegate <NSObject>
-(void) filterViewDidChange:(FilterView *)sender frequency:(double) frequency;
-(void) filterViewDidChange:(FilterView *)sender resonance:(double) resonance;
-(void) filterViewDataDidChange:(FilterView *)sender;
@end

@interface FilterView : NSView
@property (nonatomic) float resonance;
@property (nonatomic) float frequency;
@property (weak) NSObject<FilterViewDelegate> *delegate;

-(NSArray<NSNumber*>*)frequencyDataForDrawing;
-(void)setMagnitudes:(NSArray<NSNumber*>*) magnitudes;

@end
