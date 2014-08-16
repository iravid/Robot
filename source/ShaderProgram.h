//
//  ShaderProgram.h
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#ifndef __Robot__ShaderProgram__
#define __Robot__ShaderProgram__

#include "Shader.h"
#include <vector>
#include <glm/glm.hpp>

// A Program wrapper. Represents linked Shader objects.
class ShaderProgram {
public:
    ShaderProgram(const std::vector<Shader>& shaders);
    ~ShaderProgram();
    
    // The program's OpenGL handle
    GLuint handle() const;
    
    // Start using the program in the OpenGL context
    void use() const;
    
    // Determine whether the program is being used in the OpenGL context
    bool isInUse() const;
    
    // Stop using the program in the OpenGL context
    void stopUsing() const;
    
    // Attribute index for the given name
    GLint attrib(const GLchar *attribName) const;
    
    // Uniform index for the given name
    GLint uniform(const GLchar *uniformName) const;
    
    /**
     Setters for attribute and uniform variables.
     
     These are convenience methods for the glVertexAttrib* and glUniform* functions.
     */
#define PROGRAM_ATTRIB_N_UNIFORM_SETTERS(OGL_TYPE) \
        void setAttrib(const GLchar* attribName, OGL_TYPE v0); \
        void setAttrib(const GLchar* attribName, OGL_TYPE v0, OGL_TYPE v1); \
        void setAttrib(const GLchar* attribName, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2); \
        void setAttrib(const GLchar* attribName, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2, OGL_TYPE v3); \
\
        void setAttrib1v(const GLchar* attribName, const OGL_TYPE* v); \
        void setAttrib2v(const GLchar* attribName, const OGL_TYPE* v); \
        void setAttrib3v(const GLchar* attribName, const OGL_TYPE* v); \
        void setAttrib4v(const GLchar* attribName, const OGL_TYPE* v); \
\
        void setUniform(const GLchar* uniformName, OGL_TYPE v0); \
        void setUniform(const GLchar* uniformName, OGL_TYPE v0, OGL_TYPE v1); \
        void setUniform(const GLchar* uniformName, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2); \
        void setUniform(const GLchar* uniformName, OGL_TYPE v0, OGL_TYPE v1, OGL_TYPE v2, OGL_TYPE v3); \
\
        void setUniform1v(const GLchar* uniformName, const OGL_TYPE* v, GLsizei count=1); \
        void setUniform2v(const GLchar* uniformName, const OGL_TYPE* v, GLsizei count=1); \
        void setUniform3v(const GLchar* uniformName, const OGL_TYPE* v, GLsizei count=1); \
        void setUniform4v(const GLchar* uniformName, const OGL_TYPE* v, GLsizei count=1); \

    PROGRAM_ATTRIB_N_UNIFORM_SETTERS(GLfloat)
    PROGRAM_ATTRIB_N_UNIFORM_SETTERS(GLdouble)
    PROGRAM_ATTRIB_N_UNIFORM_SETTERS(GLint)
    PROGRAM_ATTRIB_N_UNIFORM_SETTERS(GLuint)
    
    void setUniformMatrix2(const GLchar* uniformName, const GLfloat* v, GLsizei count=1, GLboolean transpose=GL_FALSE);
    void setUniformMatrix3(const GLchar* uniformName, const GLfloat* v, GLsizei count=1, GLboolean transpose=GL_FALSE);
    void setUniformMatrix4(const GLchar* uniformName, const GLfloat* v, GLsizei count=1, GLboolean transpose=GL_FALSE);
    void setUniform(const GLchar* uniformName, const glm::mat2& m, GLboolean transpose=GL_FALSE);
    void setUniform(const GLchar* uniformName, const glm::mat3& m, GLboolean transpose=GL_FALSE);
    void setUniform(const GLchar* uniformName, const glm::mat4& m, GLboolean transpose=GL_FALSE);
    void setUniform(const GLchar* uniformName, const glm::vec3& v);
    void setUniform(const GLchar* uniformName, const glm::vec4& v);
private:
    GLuint _handle;
};

#endif /* defined(__Robot__ShaderProgram__) */
