//
//  Shader.h
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#ifndef __Robot__Shader__
#define __Robot__Shader__

#include <GL/glew.h>
#include <string>

// A wrapper class for an OpenGL shader
class Shader {
public:
    // Utility method to create a shader object from a source file
    static Shader shaderFromFile(const std::string& path, GLenum shaderType);
    
    // Construct a new Shader from a string containing its source
    Shader(const std::string& source, GLenum shaderType);
    
    // The shader's OpenGL handle
    GLuint handle() const;
    
    // Copy constructor
    Shader(const Shader& other);

    // Destructor
    ~Shader();
private:
    GLuint _handle;
    unsigned* _refCount;
    
    void _retain();
    void _release();
};

#endif /* defined(__Robot__Shader__) */
