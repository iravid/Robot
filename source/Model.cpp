//
//  Model.cpp
//  Robot
//
//  Created by Itamar Ravid on 25/8/14.
//
//

#include "Loaders.h"
#include "Model.h"

// Constructor
Model::Model() : shaders(nullptr), texture(nullptr),
    vbo(0), tbo(0), nbo(0), vao(0), ebo(0),
    drawType(GL_TRIANGLES), drawStart(0), drawCount(0),
    ambientColor(1.0f), diffuseColor(1.0f), specularColor(1.0f), shininess(0.0f) {
    genBuffers();
}

Model::Model(GLenum drawType, GLuint drawCount, GLuint drawStart,
                glm::vec4 ambientColor, glm::vec4 diffuseColor, glm::vec4 specularColor, GLfloat shininess,
                const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath) :
                drawType(drawType), drawCount(drawCount), drawStart(drawStart),
                ambientColor(ambientColor), diffuseColor(diffuseColor), specularColor(specularColor), shininess(shininess) {
    shaders = programWithShaders(vertexShaderPath, fragmentShaderPath);
    texture = textureFromFile(texturePath);
    genBuffers();
}

Model::Model(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData,
     GLenum drawType, GLuint drawCount, GLuint drawStart,
     glm::vec4 ambientColor, glm::vec4 diffuseColor, glm::vec4 specularColor, GLfloat shininess,
     const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath) :
     drawType(drawType), drawCount(drawCount), drawStart(drawStart),
     ambientColor(ambientColor), diffuseColor(diffuseColor), specularColor(specularColor), shininess(shininess) {
    shaders = programWithShaders(vertexShaderPath, fragmentShaderPath);
    texture = textureFromFile(texturePath);
    genBuffers();
    loadData(vertexData, textureData, normalData, elementData);
}

void Model::genBuffers() {
    glGenBuffers(1, &vbo);
    glGenBuffers(1, &nbo);
    glGenBuffers(1, &tbo);
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &ebo);
}

void Model::loadData(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData) {
    // Bind array
    glBindVertexArray(vao);
    
    // Load the vertex data.
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, vertexData.size() * sizeof(glm::vec3), &vertexData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(shaders->attrib("vert"));
    glVertexAttribPointer(shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, tbo);
    glBufferData(GL_ARRAY_BUFFER, textureData.size() * sizeof(glm::vec2), &textureData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), NULL);
    
    // Load the normal data
    glBindBuffer(GL_ARRAY_BUFFER, nbo);
    glBufferData(GL_ARRAY_BUFFER, normalData.size() * sizeof(glm::vec3), &normalData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(shaders->attrib("vertNormal"));
    glVertexAttribPointer(shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementData.size() * sizeof(GLuint), &elementData[0], GL_STATIC_DRAW);
    
    glBindVertexArray(0);
}

ModelInstance::ModelInstance() : model(nullptr), transform() {}

ModelInstance::ModelInstance(Model *model) : model(model), transform() {}

void ModelInstance::render(const glm::mat4 transform, Camera& cameraPosition, Light& lightSource) {
    ShaderProgram *shaders = model->shaders;
    
    // Start using the shader program
    shaders->use();
    
    // Set the uniforms
    shaders->setUniform("model", transform);
    shaders->setUniform("view", cameraPosition.view());
    shaders->setUniform("projection", cameraPosition.projection());
    
    shaders->setUniform("materialTexture", 0);
    shaders->setUniform("material.ambient", model->ambientColor);
    shaders->setUniform("material.diffuse", model->diffuseColor);
    shaders->setUniform("material.specular", model->specularColor);
    shaders->setUniform("material.shininess", model->shininess);
    
    shaders->setUniform("light.position", lightSource.position);
    shaders->setUniform("light.diffuse", lightSource.diffuseColor);
    shaders->setUniform("light.specular", lightSource.specularColor);
    shaders->setUniform("light.ambient", lightSource.ambientColor);
    shaders->setUniform("light.attenuation", lightSource.attenuation);
    
    // Bind texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, model->texture->handle());
    
    // Bind VAO and draw
    glBindVertexArray(model->vao);
    glDrawElements(model->drawType, model->drawCount, GL_UNSIGNED_INT, 0);
    
    // Unbind everything
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    shaders->stopUsing();
}