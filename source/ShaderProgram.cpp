//
//  ShaderProgram.cpp
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#include "ShaderProgram.h"
#include <glm/gtc/type_ptr.hpp>

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

ShaderProgram::~ShaderProgram() {
    if (_handle != 0)
        glDeleteProgram(_handle);
}

GLuint ShaderProgram::handle() const {
    return _handle;
}

void ShaderProgram::use() const {
    glUseProgram(_handle);
}

bool ShaderProgram::isInUse() const {
    GLint currentProgram = 0;
    glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
    return (currentProgram == (GLint) _handle);
}

void ShaderProgram::stopUsing() const {
    assert(isInUse());
    glUseProgram(0);
}

GLint ShaderProgram::attrib(const GLchar *attribName) const {
    if (!attribName)
        throw std::runtime_error("NULL attribName passed to ShaderProgram::attrib");
    
    GLint attrib = glGetAttribLocation(_handle, attribName);
    if (attrib == -1)
        throw std::runtime_error(std::string("Program attribute not found: ") + attribName);
    
    return attrib;
}

GLint ShaderProgram::uniform(const GLchar *uniformName) const {
    if (!uniformName)
        throw std::runtime_error("NULL uniformName passed to ShaderProgram::uniform");
    
    GLint uniform = glGetUniformLocation(_handle, uniformName);
    if (uniform == -1)
        throw std::runtime_error(std::string("Program uniform not found: ") + uniformName);
    
    return uniform;
}

#define ATTRIB_N_UNIFORM_SETTERS(OGL_TYPE, TYPE_PREFIX, TYPE_SUFFIX) \
\
void ShaderProgram::setAttrib(const GLchar* name, OGL_TYPE v0) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 1 ## TYPE_SUFFIX (attrib(name), v0); } \
void ShaderProgram::setAttrib(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 2 ## TYPE_SUFFIX (attrib(name), v0, v1); } \
void ShaderProgram::setAttrib(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 3 ## TYPE_SUFFIX (attrib(name), v0, v1, v2); } \
void ShaderProgram::setAttrib(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2, OGL_TYPE v3) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 4 ## TYPE_SUFFIX (attrib(name), v0, v1, v2, v3); } \
\
void ShaderProgram::setAttrib1v(const GLchar* name, const OGL_TYPE* v) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 1 ## TYPE_SUFFIX ## v (attrib(name), v); } \
void ShaderProgram::setAttrib2v(const GLchar* name, const OGL_TYPE* v) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 2 ## TYPE_SUFFIX ## v (attrib(name), v); } \
void ShaderProgram::setAttrib3v(const GLchar* name, const OGL_TYPE* v) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 3 ## TYPE_SUFFIX ## v (attrib(name), v); } \
void ShaderProgram::setAttrib4v(const GLchar* name, const OGL_TYPE* v) \
{ assert(isInUse()); glVertexAttrib ## TYPE_PREFIX ## 4 ## TYPE_SUFFIX ## v (attrib(name), v); } \
\
void ShaderProgram::setUniform(const GLchar* name, OGL_TYPE v0) \
{ assert(isInUse()); glUniform1 ## TYPE_SUFFIX (uniform(name), v0); } \
void ShaderProgram::setUniform(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1) \
{ assert(isInUse()); glUniform2 ## TYPE_SUFFIX (uniform(name), v0, v1); } \
void ShaderProgram::setUniform(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2) \
{ assert(isInUse()); glUniform3 ## TYPE_SUFFIX (uniform(name), v0, v1, v2); } \
void ShaderProgram::setUniform(const GLchar* name, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2, OGL_TYPE v3) \
{ assert(isInUse()); glUniform4 ## TYPE_SUFFIX (uniform(name), v0, v1, v2, v3); } \
\
void ShaderProgram::setUniform1v(const GLchar* name, const OGL_TYPE* v, GLsizei count) \
{ assert(isInUse()); glUniform1 ## TYPE_SUFFIX ## v (uniform(name), count, v); } \
void ShaderProgram::setUniform2v(const GLchar* name, const OGL_TYPE* v, GLsizei count) \
{ assert(isInUse()); glUniform2 ## TYPE_SUFFIX ## v (uniform(name), count, v); } \
void ShaderProgram::setUniform3v(const GLchar* name, const OGL_TYPE* v, GLsizei count) \
{ assert(isInUse()); glUniform3 ## TYPE_SUFFIX ## v (uniform(name), count, v); } \
void ShaderProgram::setUniform4v(const GLchar* name, const OGL_TYPE* v, GLsizei count) \
{ assert(isInUse()); glUniform4 ## TYPE_SUFFIX ## v (uniform(name), count, v); }

ATTRIB_N_UNIFORM_SETTERS(GLfloat, , f);
ATTRIB_N_UNIFORM_SETTERS(GLdouble, , d);
ATTRIB_N_UNIFORM_SETTERS(GLint, I, i);
ATTRIB_N_UNIFORM_SETTERS(GLuint, I, ui);

void ShaderProgram::setUniformMatrix2(const GLchar* name, const GLfloat* v, GLsizei count, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix2fv(uniform(name), count, transpose, v);
}

void ShaderProgram::setUniformMatrix3(const GLchar* name, const GLfloat* v, GLsizei count, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix3fv(uniform(name), count, transpose, v);
}

void ShaderProgram::setUniformMatrix4(const GLchar* name, const GLfloat* v, GLsizei count, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix4fv(uniform(name), count, transpose, v);
}

void ShaderProgram::setUniform(const GLchar* name, const glm::mat2& m, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix2fv(uniform(name), 1, transpose, glm::value_ptr(m));
}

void ShaderProgram::setUniform(const GLchar* name, const glm::mat3& m, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix3fv(uniform(name), 1, transpose, glm::value_ptr(m));
}

void ShaderProgram::setUniform(const GLchar* name, const glm::mat4& m, GLboolean transpose) {
    assert(isInUse());
    glUniformMatrix4fv(uniform(name), 1, transpose, glm::value_ptr(m));
}

void ShaderProgram::setUniform(const GLchar* uniformName, const glm::vec3& v) {
    setUniform3v(uniformName, glm::value_ptr(v));
}

void ShaderProgram::setUniform(const GLchar* uniformName, const glm::vec4& v) {
    setUniform4v(uniformName, glm::value_ptr(v));
}