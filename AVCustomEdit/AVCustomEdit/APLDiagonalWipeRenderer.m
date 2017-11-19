/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 APLDiagonalWipeRenderer subclass of APLOpenGLRenderer, renders the given source buffers to perform a diagonal wipe over the time range of the transition.
 */

#import "APLDiagonalWipeRenderer.h"

#define kForegroundTrack 0
#define kBackgroundTrack 1

@interface APLDiagonalWipeRenderer ()
{
	CGPoint _diagonalEnd1;
	CGPoint _diagonalEnd2;
}

@end

@implementation APLDiagonalWipeRenderer

- (void)quadVertexCoordinates:(GLfloat *)vertexCoordinates forFrame:(int)trackID forTweenFactor:(float)tween
{
	/*
	 diagonalEnd1 and diagonalEnd2 represent the endpoints of a line which partitions the frame on screen into the two parts.
	 
	 diagonalEnd1
	 ------------X-----------
	 |			 			|
	 |			  			X diagonalEnd2
	 |						|
	 |						|
	 ------------------------
	 
	 The below conditionals, use the tween factor as a measure to determine the size of the foreground and background quads.
	 
	 */
	
	if (tween <= 0.5) { // The expectation here is that in half the timeRange of the transition we reach the diagonal of the frame
		_diagonalEnd2.x = 1.0;
		_diagonalEnd1.y = -1.0;
		_diagonalEnd1.x = 1.0 - tween * 4;
		_diagonalEnd2.y = -1.0 + tween * 4;
		
		vertexCoordinates[6] = _diagonalEnd2.x;
		vertexCoordinates[7] = _diagonalEnd2.y;
		vertexCoordinates[8] = _diagonalEnd1.x;
		vertexCoordinates[9] = _diagonalEnd1.y;
		
	}
	else if (tween > 0.5 && tween < 1.0) {
		if (trackID == kForegroundTrack) {
			_diagonalEnd1.x = -1.0;
			_diagonalEnd2.y = 1.0;
			_diagonalEnd2.x = 1.0 - (tween - 0.5) * 4;
			_diagonalEnd1.y = -1.0 + (tween - 0.5) * 4;
			
            vertexCoordinates[2] = _diagonalEnd2.x;
            vertexCoordinates[3] = _diagonalEnd2.y;
            vertexCoordinates[4] = _diagonalEnd1.x;
            vertexCoordinates[5] = _diagonalEnd1.y;
            vertexCoordinates[6] = _diagonalEnd1.x;
            vertexCoordinates[7] = _diagonalEnd1.y;
            vertexCoordinates[8] = _diagonalEnd1.x;
            vertexCoordinates[9] = _diagonalEnd1.y;
		}
		else if (trackID == kBackgroundTrack) {
			vertexCoordinates[4] = 1.0;
			vertexCoordinates[5] = 1.0;
			vertexCoordinates[6] = -1.0;
			vertexCoordinates[7] = -1.0;
        }
	}
	else if (tween >= 1.0) {
		_diagonalEnd1 = CGPointMake(1.0, -1.0);
		_diagonalEnd2 = CGPointMake(1.0, -1.0);
	}
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween
{
    [EAGLContext setCurrentContext:self.currentContext];
	
    if (foregroundPixelBuffer != NULL || backgroundPixelBuffer != NULL) {
        
        CVOpenGLESTextureRef foregroundLumaTexture  = [self lumaTextureForPixelBuffer:foregroundPixelBuffer];
        CVOpenGLESTextureRef foregroundChromaTexture = [self chromaTextureForPixelBuffer:foregroundPixelBuffer];
		
        CVOpenGLESTextureRef backgroundLumaTexture = [self lumaTextureForPixelBuffer:backgroundPixelBuffer];
        CVOpenGLESTextureRef backgroundChromaTexture = [self chromaTextureForPixelBuffer:backgroundPixelBuffer];
		
        CVOpenGLESTextureRef destLumaTexture = [self lumaTextureForPixelBuffer:destinationPixelBuffer];
        CVOpenGLESTextureRef destChromaTexture = [self chromaTextureForPixelBuffer:destinationPixelBuffer];
        
		glUseProgram(self.programY);
		
		// Set the render transform
		GLfloat preferredRenderTransform [] = {
			self.renderTransform.a, self.renderTransform.b, self.renderTransform.tx, 0.0,
			self.renderTransform.c, self.renderTransform.d, self.renderTransform.ty, 0.0,
			0.0,					   0.0,										1.0, 0.0,
			0.0,					   0.0,										0.0, 1.0,
		};
		
		glUniformMatrix4fv(uniforms[UNIFORM_RENDER_TRANSFORM_Y], 1, GL_FALSE, preferredRenderTransform);
		
        glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
		
        glViewport(0, 0, (int)CVPixelBufferGetWidthOfPlane(destinationPixelBuffer, 0), (int)CVPixelBufferGetHeightOfPlane(destinationPixelBuffer, 0));
		
		// Y planes of foreground and background frame are used to render the Y plane of the destination frame
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundLumaTexture), CVOpenGLESTextureGetName(foregroundLumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundLumaTexture), CVOpenGLESTextureGetName(backgroundLumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destLumaTexture), CVOpenGLESTextureGetName(destLumaTexture), 0);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			goto bail;
		}
		
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
        
        GLfloat quadVertexData1 [] = {
			-1.0, 1.0,
			1.0, 1.0,
			-1.0, -1.0,
			1.0, -1.0,
			1.0, -1.0,
		};
		
		// Compute the vertex data for the foreground frame at this instructionLerp 
		[self quadVertexCoordinates:quadVertexData1 forFrame:kForegroundTrack forTweenFactor:tween];
		
		// texture data varies from 0 -> 1, whereas vertex data varies from -1 -> 1
		GLfloat quadTextureData1 [] = {
            0.5 + quadVertexData1[0]/2, 0.5 + quadVertexData1[1]/2,
            0.5 + quadVertexData1[2]/2, 0.5 + quadVertexData1[3]/2,
            0.5 + quadVertexData1[4]/2, 0.5 + quadVertexData1[5]/2,
            0.5 + quadVertexData1[6]/2, 0.5 + quadVertexData1[7]/2,
            0.5 + quadVertexData1[8]/2, 0.5 + quadVertexData1[9]/2,
        };
        
		glUniform1i(uniforms[UNIFORM_Y], 0);
		
        glVertexAttribPointer(ATTRIB_VERTEX_Y, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_Y);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_Y, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_Y);
		
		// Draw the foreground frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
		
        GLfloat quadVertexData2 [] = {
            _diagonalEnd2.x, _diagonalEnd2.y,
            _diagonalEnd1.x, _diagonalEnd1.y,
            1.0, -1.0,
            1.0, -1.0,
            1.0, -1.0,
        };
		
		// Compute the vertex data for the background frame at this instructionLerp 
        [self quadVertexCoordinates:quadVertexData2 forFrame:kBackgroundTrack forTweenFactor:tween];
        
        GLfloat quadTextureData2 [] = {
            0.5 + quadVertexData2[0]/2, 0.5 + quadVertexData2[1]/2,
            0.5 + quadVertexData2[2]/2, 0.5 + quadVertexData2[3]/2,
            0.5 + quadVertexData2[4]/2, 0.5 + quadVertexData2[5]/2,
            0.5 + quadVertexData2[6]/2, 0.5 + quadVertexData2[7]/2,
            0.5 + quadVertexData2[8]/2, 0.5 + quadVertexData2[9]/2,
        };
        
        glUniform1i(uniforms[UNIFORM_Y], 1);
        
        glVertexAttribPointer(ATTRIB_VERTEX_Y, 2, GL_FLOAT, 0, 0, quadVertexData2);
        glEnableVertexAttribArray(ATTRIB_VERTEX_Y);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_Y, 2, GL_FLOAT, 0, 0, quadTextureData2);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_Y);
        
		// Draw the background frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
		
		// Perform similar operations as above for the UV plane
		glUseProgram(self.programUV);
		
		glUniformMatrix4fv(uniforms[UNIFORM_RENDER_TRANSFORM_UV], 1, GL_FALSE, preferredRenderTransform);
		
		// UV planes of foreground and background frame are used to render the UV plane of the destination frame
		glActiveTexture(GL_TEXTURE2);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundChromaTexture), CVOpenGLESTextureGetName(foregroundChromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glActiveTexture(GL_TEXTURE3);
		glBindTexture(CVOpenGLESTextureGetTarget(backgroundChromaTexture), CVOpenGLESTextureGetName(backgroundChromaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glViewport(0, 0, (int)CVPixelBufferGetWidthOfPlane(destinationPixelBuffer, 1), (int)CVPixelBufferGetHeightOfPlane(destinationPixelBuffer, 1));
		
		// Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destChromaTexture), CVOpenGLESTextureGetName(destChromaTexture), 0);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			goto bail;
		}
		
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
        
		glUniform1i(uniforms[UNIFORM_UV], 2);
		
        glVertexAttribPointer(ATTRIB_VERTEX_UV, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_UV);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_UV, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_UV);
		
		// Draw the foreground frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
		
        glUniform1i(uniforms[UNIFORM_UV], 3);
        
        glVertexAttribPointer(ATTRIB_VERTEX_UV, 2, GL_FLOAT, 0, 0, quadVertexData2);
        glEnableVertexAttribArray(ATTRIB_VERTEX_UV);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_UV, 2, GL_FLOAT, 0, 0, quadTextureData2);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_UV);
        
		// Draw the background frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
		
        glFlush();
		
	bail:
		CFRelease(foregroundLumaTexture);
		CFRelease(foregroundChromaTexture);
		CFRelease(backgroundLumaTexture);
		CFRelease(backgroundChromaTexture);
		CFRelease(destLumaTexture);
		CFRelease(destChromaTexture);
		
		// Periodic texture cache flush every frame
		CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
		
		[EAGLContext setCurrentContext:nil];
    }
}

@end
