/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 OpenGL base class renderer sets up an EAGLContext for rendering, it also loads, compiles and links the vertex and fragment shaders for both the Y and UV planes.
 */

#import "APLOpenGLRenderer.h"

GLint uniforms[NUM_UNIFORMS];

static const char kPassThroughVertexShader[] = {
    "attribute vec4 position; \n \
     attribute vec2 texCoord; \n \
	 uniform mat4 renderTransform; \n \
     varying vec2 texCoordVarying; \n \
     void main() \n \
     { \n \
        gl_Position = position * renderTransform; \n \
        texCoordVarying = texCoord; \n \
     }"
};

static const char kPassThroughFragmentShaderY[] = {
    "varying highp vec2 texCoordVarying; \n \
     uniform sampler2D SamplerY; \n \
     void main() \n \
     { \n \
		gl_FragColor.r = texture2D(SamplerY, texCoordVarying).r; \n \
     }"
};

static const char kPassThroughFragmentShaderUV[] = {
    "varying highp vec2 texCoordVarying; \n \
    uniform sampler2D SamplerUV; \n \
    void main() \n \
    { \n \
		gl_FragColor.rg = texture2D(SamplerUV, texCoordVarying).rg; \n \
    }"
};

@interface APLOpenGLRenderer ()

- (void)setupOffscreenRenderContext;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)source;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation APLOpenGLRenderer

- (id)init
{
    self = [super init];
    if(self) {
		_currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		[EAGLContext setCurrentContext:_currentContext];
		
        [self setupOffscreenRenderContext];
        [self loadShaders];
        
		[EAGLContext setCurrentContext:nil];
    }
    
    return self;
}

- (void)dealloc
{
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)setupOffscreenRenderContext
{
	//-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
	
	glDisable(GL_DEPTH_TEST);
	
	glGenFramebuffers(1, &_offscreenBufferHandle);
	glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
}

- (CVOpenGLESTextureRef)lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef lumaTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // Y
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       (int)CVPixelBufferGetWidth(pixelBuffer),
                                                       (int)CVPixelBufferGetHeight(pixelBuffer),
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &lumaTexture);
    
    if (!lumaTexture || err) {
        NSLog(@"Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
bail:
    return lumaTexture;
}

- (CVOpenGLESTextureRef)chromaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef chromaTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // UV
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                                       (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &chromaTexture);
    
    if (!chromaTexture || err) {
        NSLog(@"Error at creating chroma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
bail:
    return chromaTexture;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
	GLuint vertShader, fragShaderY, fragShaderUV;
	NSString *vertShaderSource, *fragShaderYSource, *fragShaderUVSource;
	
	// Create the shader program.
	_programY = glCreateProgram();
    _programUV = glCreateProgram();
	
	// Create and compile the vertex shader.
	vertShaderSource = [NSString stringWithCString:kPassThroughVertexShader encoding:NSUTF8StringEncoding];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:vertShaderSource]) {
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}
	
	// Create and compile Y fragment shader.
	fragShaderYSource = [NSString stringWithCString:kPassThroughFragmentShaderY encoding:NSUTF8StringEncoding];
	if (![self compileShader:&fragShaderY type:GL_FRAGMENT_SHADER source:fragShaderYSource]) {
		NSLog(@"Failed to compile Y fragment shader");
		return NO;
	}
    
    // Create and compile UV fragment shader.
    fragShaderUVSource = [NSString stringWithCString:kPassThroughFragmentShaderUV encoding:NSUTF8StringEncoding];
	if (![self compileShader:&fragShaderUV type:GL_FRAGMENT_SHADER source:fragShaderUVSource]) {
		NSLog(@"Failed to compile UV fragment shader");
		return NO;
	}
	
	// Attach vertex shader to programY.
	glAttachShader(_programY, vertShader);
	
	// Attach fragment shader to programY.
	glAttachShader(_programY, fragShaderY);
    
    // Attach vertex shader to programY.
	glAttachShader(_programUV, vertShader);
	
	// Attach fragment shader to programY.
	glAttachShader(_programUV, fragShaderUV);

	
	// Bind attribute locations. This needs to be done prior to linking.
	
	glBindAttribLocation(_programY, ATTRIB_VERTEX_Y, "position");
	glBindAttribLocation(_programY, ATTRIB_TEXCOORD_Y, "texCoord");
	glBindAttribLocation(_programUV, ATTRIB_VERTEX_UV, "position");
	glBindAttribLocation(_programUV, ATTRIB_TEXCOORD_UV, "texCoord");
		   
	// Link the program.
	if (![self linkProgram:_programY] || ![self linkProgram:_programUV]) {
		NSLog(@"Failed to link program: %d and %d", _programY, _programUV);
		
		if (vertShader) {
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShaderY) {
			glDeleteShader(fragShaderY);
			fragShaderY = 0;
		}
        if (fragShaderUV) {
			glDeleteShader(fragShaderUV);
			fragShaderUV = 0;
		}
		if (_programY) {
			glDeleteProgram(_programY);
			_programY = 0;
		}
        if (_programUV) {
			glDeleteProgram(_programUV);
			_programUV = 0;
		}
		
		return NO;
	}
	
	// Get uniform locations.
	uniforms[UNIFORM_Y] = glGetUniformLocation(_programY, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(_programUV, "SamplerUV");
    uniforms[UNIFORM_RENDER_TRANSFORM_Y] = glGetUniformLocation(_programY, "renderTransform");
	uniforms[UNIFORM_RENDER_TRANSFORM_UV] = glGetUniformLocation(_programUV, "renderTransform");
	
	// Release vertex and fragment shaders.
	if (vertShader) {
		glDetachShader(_programY, vertShader);
        glDetachShader(_programUV, vertShader);
		glDeleteShader(vertShader);
	}
	if (fragShaderY) {
		glDetachShader(_programY, fragShaderY);
		glDeleteShader(fragShaderY);
	}
    if (fragShaderUV) {
		glDetachShader(_programUV, fragShaderUV);
		glDeleteShader(fragShaderUV);
	}
	
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)sourceString
{
    if (sourceString == nil) {
		NSLog(@"Failed to load vertex shader: Empty source string");
        return NO;
    }
    
	GLint status;
	const GLchar *source;
	source = (GLchar *)[sourceString UTF8String];
	
	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);
	
#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
#endif
	
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0) {
		glDeleteShader(*shader);
		return NO;
	}
	
	return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	glLinkProgram(prog);
	
#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
#endif
	
	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

#if defined(DEBUG)

- (BOOL)validateProgram:(GLuint)prog
{
	GLint logLength, status;
	
	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}
	
	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

#endif

@end
