/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 OpenGL base class renderer sets up an EAGLContext for rendering, it also loads, compiles and links the vertex and fragment shaders for both the Y and UV planes.
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

enum
{
	UNIFORM_Y,
	UNIFORM_UV,
	UNIFORM_RENDER_TRANSFORM_Y,
	UNIFORM_RENDER_TRANSFORM_UV,
   	NUM_UNIFORMS
};
extern GLint uniforms[NUM_UNIFORMS];

enum
{
	ATTRIB_VERTEX_Y,
	ATTRIB_TEXCOORD_Y,
	ATTRIB_VERTEX_UV,
	ATTRIB_TEXCOORD_UV,
   	NUM_ATTRIBUTES
};

@interface APLOpenGLRenderer : NSObject

@property GLuint programY;
@property GLuint programUV;
@property CGAffineTransform renderTransform;
@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;

- (CVOpenGLESTextureRef)lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVOpenGLESTextureRef)chromaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween;

@end
