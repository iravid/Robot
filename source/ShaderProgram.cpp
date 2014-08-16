//
//  ShaderProgram.cpp
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#include "ShaderProgram.h"

ShaderProgram::ShaderProgram(const std::vector<Shader>& shaders) : _handle(0) {
    if (shaders.size() <= 0)
        throw std::runtime_error("No shaders provided in the program");
    
    _handle = glCreateProgram();
    if (_handle == 0)
        throw std::runtime_error("glCreateProgram failed");
    
    for (unsigned i = 0; i < shaders.size(); ++i)
        glAttachShader(_handle, shaders[i].handle());
    
    glLinkProgram(_handle);
    
    for (unsigned i = 0; i < shaders.size(); ++i)
        glDetachShader(_handle, shaders[i].handle());
    
    GLint linkStatus = 0;
    glGetProgramiv(_handle, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        std::string errorMessage("Compile failure in glLinkProgram:\n");
        
        // Extract error log length
        GLint infoLogLength;
        glGetShaderiv(_handle, GL_INFO_LOG_LENGTH, &infoLogLength);
        
        // Extract the error log itself
        char *errorLog = new char[infoLogLength + 1];
        glGetProgramInfoLog(_handle, infoLogLength, NULL, errorLog);
        
        errorMessage += errorLog;
        
        delete[] errorLog;
        
        // Clean up
        glDeleteProgram(_handle);
        _handle = 0;
        
        throw std::runtime_error(errorMessage);
    }
}