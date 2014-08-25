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
#include "Camera.h"
#include "Light.h"

struct ModelData {
    std::vector<glm::vec3> vertexData;
    std::vector<glm::vec2> textureData;
    std::vector<glm::vec3> normalData;
    std::vector<GLuint> indexData;
};

struct ModelTransform {
    glm::mat4 scale;
    glm::mat4 rotate;
    glm::mat4 translate;
    
    ModelTransform() : scale(), rotate(), translate() {}
    glm::mat4 matrix() const { return translate * rotate * scale; }
};

class Model {
public:
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
    
    Model();
    Model(GLenum drawType, GLuint drawCount, GLuint drawStart,
          glm::vec4 ambientColor, glm::vec4 diffuseColor, glm::vec4 specularColor, GLfloat shininess,
          const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath);
    Model(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData,
          GLenum drawType, GLuint drawCount, GLuint drawStart,
          glm::vec4 ambientColor, glm::vec4 diffuseColor, glm::vec4 specularColor, GLfloat shininess,
          const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath);
    void loadData(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData);
private:
    void genBuffers();
};

class ModelInstance {
public:
    // The model itself
    Model *model;
    // The transformation to be applied to this instance
    ModelTransform transform;
    
    ModelInstance();
    ModelInstance(Model *model);
    void render(const glm::mat4 transform, Camera& cameraPosition, Light& lightSource);
};

#endif
