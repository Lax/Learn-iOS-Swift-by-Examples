/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom `SKNode` based button.
 */

#import "AAPLButton.h"

@interface AAPLButton ()


@property (strong, nonatomic) SKLabelNode *label;
@property (strong, nonatomic) SKSpriteNode *background;

@property (nonatomic, readonly) SEL actionClicked;
@property (nonatomic, readonly, weak) id targetClicked;

@property (nonatomic) CGSize size;

@end

@implementation AAPLButton

+ (AAPLButton*)buttonWithText:(NSString*)txt
{
    AAPLButton *button = [[AAPLButton alloc] initWithText:txt];
    return button;
}

+ (AAPLButton*)buttonWithSKNode:(SKNode*)node
{
    AAPLButton *button = [[AAPLButton alloc] initWithSKNode:node];
    return button;
}

- (id)initWithText:(NSString*)txt
{
    if (self = [super init])
    {
        // create a label
        NSString *fontName = @"Optima-ExtraBlack";
        _label = [SKLabelNode labelNodeWithFontNamed:fontName];
        _label.text = txt;
        _label.fontSize = 18;
        _label.fontColor = [SKColor whiteColor];
        _label.position = CGPointMake(0., -8.);
        
        // create the background
        _size = CGSizeMake(_label.frame.size.width + 10., 30.);
        _background = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0 green:0 blue:0 alpha:0.75] size:_size ];
        
        
        // add to the root node
        [self addChild:_background];
        [self addChild:_label];
        
        // Track mouse event
        self.userInteractionEnabled = YES;        
    }
    
    return self;
}

- (id)initWithSKNode:(SKNode *)node
{
    if (self = [super init])
    {
        // Track mouse event
        self.userInteractionEnabled = YES;
        
        _size = node.frame.size;
        [self addChild:node];
    }
    
    return self;
}

- (CGFloat) width
{
    return _size.width;
}
- (CGFloat) height
{
    return _size.height;
}


- (void)setText:(NSString*)txt
{
    _label.text = txt;
}

- (void)setBackgroundColor:(SKColor*)col
{
    [_background setColor:col];
}

- (void)setClickedTarget:(id)target action:(SEL)action
{
    assert( target != nil && action != nil );
    
    _targetClicked = target;
    _actionClicked = action;
    
    IMP imp = [_targetClicked methodForSelector:action];
    assert( imp != nil );
    
    _action = (void *)imp;
}

#if TARGET_OS_OSX

- (void)mouseDown:(NSEvent *)event
{
    [self setBackgroundColor:[SKColor colorWithRed:0 green:0 blue:0 alpha:1.0]];
}

- (void)mouseUp:(NSEvent *)event
{
    [self setBackgroundColor:[SKColor colorWithRed:0 green:0 blue:0 alpha:0.75]];
    CGPoint pos = [self.scene convertPoint:self.position fromNode:self.parent];
    
    CGPoint p = [event locationInWindow];
    if( fabs(p.x-pos.x) < self.width/2*self.xScale && fabs(p.y-pos.y) < self.height/2*self.yScale )
        _action( _targetClicked, _actionClicked );
}

#endif

#if TARGET_OS_IPHONE

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    _action( _targetClicked, _actionClicked );
}

#endif

@end
