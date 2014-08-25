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

struct ModelData {
    std::vector<glm::vec3> vertexData;
    std::vector<glm::vec2> textureData;
    std::vector<glm::vec3> normalData;
    std::vector<GLuint> indexData;
};

struct Model {
    ShaderProgram *shaders;
    Texture *texture;
    
    GLuint vbo; // Vertex buffer
    GLuint tbo; // Texture coordinates buffer
    GLuint nbo; // Normal coordinates buffer
    GLuint vao; // Vertex array
    GLuint ebo; // Index buffer
    
    // Vertex parameters
    GLenum drawType;
    GLint drawStart;
    GLint drawCount;
    
    // Lighting parameters
    glm::vec4 ambientColor;
    glm::vec4 diffuseColor;
    glm::vec4 specularColor;
    GLfloat shininess;

    
    // Constructor
    Model() : shaders(nullptr), texture(nullptr),
            vbo(0), tbo(0), nbo(0), vao(0), ebo(0),
            drawType(GL_TRIANGLES), drawStart(0), drawCount(0),
            ambientColor(1.0f), diffuseColor(1.0f), specularColor(1.0f), shininess(0.0f) {}
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
    ModelInstance(Model *model) : model(model), transform() {}
};

#endif
