//
//  Model.h
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#ifndef Robot_Model_h
#define Robot_Model_h

#include <glm/glm.hpp>

#include "ShaderProgram.h"
#include "Texture.h"

struct Model {
    ShaderProgram *shaders;
    Texture *texture;
    
    GLuint vbo;
    GLuint vao;
    
    // Vertex parameters
    GLenum drawType;
    GLint drawStart;
    GLint drawCount;
    
    // Lighting parameters
    GLfloat shininess;
    glm::vec3 specularColor;
    
    // Constructor
    Model() :
    shaders(nullptr), texture(nullptr),
    vbo(0), vao(0),
    drawType(GL_TRIANGLES), drawStart(0), drawCount(0),
    shininess(0.0f), specularColor(1.0f, 1.0f, 1.0f) {}
};

struct ModelTransform {
    glm::mat4 scale;
    glm::mat4 rotate;
    glm::mat4 translate;
    
    ModelTransform() : scale(), rotate(), translate() {}
    glm::mat4 matrix() const { return translate * rotate * scale; }
};

struct ModelInstance {
    // The model itself
    Model *model;
    // The transformation to be applied to this instance
    ModelTransform transform;
    
    ModelInstance() : model(nullptr), transform() {}
};

#endif
