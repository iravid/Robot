//
//  Shader.cpp
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#include "Shader.h"

#include <sstream>
#include <fstream>
#include <string>

Shader::Shader(const std::string& source, GLenum shaderType) : _handle(0), _refCount(nullptr) {
    // Get a handle for a shader object
    _handle = glCreateShader(shaderType);
    if (_handle == 0)
        throw std::runtime_error("Error in glCreateShader");
    
    // Set the source
    const char *code = source.c_str();
    glShaderSource(_handle, 1, (const char **) &code, NULL);
    
    // Compile
    glCompileShader(_handle);
    
    // Make sure everything was fine
    GLint compileStatus;
    glGetShaderiv(_handle, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        std::string errorMessage("Compile failure in glCompileShader:\n");
        
        // Extract error log length
        GLint infoLogLength;
        glGetShaderiv(_handle, GL_INFO_LOG_LENGTH, &infoLogLength);
        
        // Extract the error log itself
        char *errorLog = new char[infoLogLength + 1];
        glGetShaderInfoLog(_handle, infoLogLength, NULL, errorLog);
        
        errorMessage += errorLog;
        
        delete[] errorLog;
        
        // Clean up
        glDeleteShader(_handle);
        _handle = 0;
        
        throw std::runtime_error(errorMessage);
    }
    
    // Init and increase refcount
    _refCount = new unsigned;
    *_refCount = 1;
}


Shader::Shader(const Shader& other) : _handle(other._handle), _refCount(other._refCount) {
    // Increase the other Shader's refCount
    _retain();
}

Shader::~Shader() {
    if (_refCount)
        _release();
}

GLuint Shader::handle() const {
    return _handle;
}

Shader Shader::shaderFromFile(const std::string &path, GLenum shaderType) {
    std::ifstream inputFile;
    inputFile.open(path.c_str(), std::ios::in | std::ios::binary);
    
    if (!inputFile.is_open())
        throw std::runtime_error("Failed to open file: " + path);
    
    std::stringstream buf;
    buf << inputFile.rdbuf();
    
    return Shader(buf.str(), shaderType);
}

void Shader::_retain() {
    *_refCount += 1;
}

void Shader::_release() {
    *_refCount -= 1;
    
    if (*_refCount == 0) {
        glDeleteShader(_handle);
        _handle = 0;
        delete _refCount;
        _refCount = nullptr;
    }
}


