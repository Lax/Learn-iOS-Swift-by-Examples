/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom `SKNode` based menu.
 */

#define DURATION .3f

#import "AAPLMenu.h"
#import "AAPLButton.h"
#import "AAPLSlider.h"

@interface AAPLMenu ()


@property (strong, nonatomic) NSMutableArray<AAPLButton*> *cameraButton;
@property (strong, nonatomic) NSMutableArray<AAPLSlider*> *dofSlider;
@property (nonatomic) bool menuHidden;

@end

@implementation AAPLMenu

- (id)initWithSize:(CGSize)size
{
    if (self = [super init]) {
        
        // Track mouse event
        self.userInteractionEnabled = YES;
        
        // Init buttons
        // Menu
        {
            _cameraButton = [[NSMutableArray alloc] init];
            NSArray *txt = [NSArray arrayWithObjects: @"Camera 1", @"Camera 2", @"Camera 3", nil];
            
#define ButtonMargin 250
#define MenuY 40
#define SecondaryMenuY 80
            
            for(int i=0; i<txt.count; i++)
            {
                [_cameraButton addObject: [AAPLButton buttonWithText:txt[i]] ];
                
                CGFloat x = _cameraButton[i].width/2 + (i>0 ? _cameraButton[i-1].position.x + _cameraButton[i-1].width/2 + 10 : ButtonMargin);
                CGFloat y = - MenuY;
                _cameraButton[i].position = CGPointMake(x, y);
                
                [_cameraButton[i] setClickedTarget:self action:@selector(menuChanged:)];
                [self addChild:_cameraButton[i]];
            }
        }
        // Depth of Field
        {
            NSArray *txt = [NSArray arrayWithObjects: @"fStop", @"Focus", nil];
            _dofSlider = [[NSMutableArray alloc] init];
            
            for(int i=0; i<2; i++)
            {
                
                _dofSlider[i] = [AAPLSlider sliderWithWidth:300 height:10 text:txt[i]];
                _dofSlider[i].position = CGPointMake(ButtonMargin, -i*30.-70.f);
                _dofSlider[i].alpha = 0.f;
                [self addChild:_dofSlider[i]];
            }
            [_dofSlider[0] setClickedTarget:self action:@selector(cameraFStopChanged:)];
            [_dofSlider[1] setClickedTarget:self action:@selector(cameraFocusDistanceChanged:)];
        }
    }
    
    [self showMenu];
    
    return self;
}


-(IBAction) menuChanged:(id)sender
{
    [self hideAllSubMenu];
    
    [_cameraButton enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if(sender == object)
        {
            [self.delegate debugMenuSelectCameraAtIndex:index];
            
            if(index == 2)
            {
                [self showSliderMenu];
            }
        }
    }];
    
}


-(void)setHidden:(BOOL)hidden
{
    if(hidden)
        [self hideMenu];
    else
        [self showMenu];
}

-(BOOL)isHidden
{
    return _menuHidden;
}

- (void)showMenu
{
    for(int i=0; i<3; i++)
    {
        _cameraButton[i].alpha = 0.;
        SKAction *fade = [SKAction fadeInWithDuration:DURATION];
        [_cameraButton[i] runAction:fade];
    }
    
    _menuHidden = false;
}
- (void)hideMenu
{
    for(int i=0; i<3; i++)
    {
        _cameraButton[i].alpha = 1.;
        SKAction *fade = [SKAction fadeOutWithDuration:DURATION];
        [_cameraButton[i] runAction:fade];
    }
    [self hideAllSubMenu];
    
    _menuHidden = true;
}


- (void)hideAllSubMenu
{
    for(int i=0; i<2; i++)
    {
        SKAction *fade = [SKAction fadeOutWithDuration:DURATION];
        [_dofSlider[i] runAction:fade];
    }
}

- (void)showSliderMenu
{
    for(int i=0; i<2; i++)
    {
        SKAction *fade = [SKAction fadeInWithDuration:DURATION];
        [_dofSlider[i] runAction:fade];
    }
    
    [_dofSlider[0] setValue:.1];
    [_dofSlider[1] setValue:.5];
    [self performSelector:@selector(cameraFStopChanged:) withObject:_dofSlider[0]];
    [self performSelector:@selector(cameraFocusDistanceChanged:) withObject:_dofSlider[1]];
}


-(IBAction) cameraFStopChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(fStopChanged:)]) {
        [self.delegate fStopChanged:_dofSlider[0].value+.2f ];
    }
}
-(IBAction) cameraFocusDistanceChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(focusDistanceChanged:)]) {
        [self.delegate focusDistanceChanged:_dofSlider[1].value*20.f+3.f ];
    }
}

@end
