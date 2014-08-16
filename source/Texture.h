//
//  Texture.h
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#ifndef __Robot__Texture__
#define __Robot__Texture__

#include <GL/glew.h>
#include "Bitmap.h"

class Texture {
public:
    /* Creates a Texture from a Bitmap. The texture will be loaded upside down since Bitmap pixel data is ordered
     * column-major, from the top-row downwards, but OpenGL expects the data to be ordered bottom-row upwards.
     * minMagFiler should be either GL_LINEAR/GL_NEAREST, wrapMode should be GL_REPEAT/GL_MIRRORED_REPEAT/GL_CLAMP_TO_EDGE/GL_CLAMP_TO_BORDER. */
    Texture(const Bitmap& bitmap, GLint minMagFiler = GL_LINEAR, GLint wrapMode = GL_CLAMP_TO_EDGE);
    ~Texture();
    
    // Returns the OpenGL handle
    GLuint handle() const;
    
    GLfloat originalWidth() const;
    GLfloat originalHeight() const;
    
private:
    GLuint _handle;
    GLfloat _originalWidth;
    GLfloat _originalHeight;
};

#endif /* defined(__Robot__Texture__) */
