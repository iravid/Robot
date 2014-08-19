//
//  main.mm
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#import <Foundation/Foundation.h>
#include <iostream>
#include <list>
#include <string>
#include <map>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "ShaderProgram.h"
#include "Shader.h"
#include "Texture.h"
#include "Camera.h"
#include "Light.h"
#include "Model.h"
#include "MatrixStack.h"
#include "RenderNode.h"
#include "Loaders.h"

const glm::vec2 SCREEN_SIZE(1680, 1050);
Light light;
Camera camera;

static Model *loadModel(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData,
                        GLenum drawType, GLuint drawCount, GLuint drawStart,
                        GLfloat shininess, glm::vec3 specularColor,
                        const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath);

static Model *loadModel(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData,
                        GLenum drawType, GLuint drawCount, GLuint drawStart,
                        GLfloat shininess, glm::vec3 specularColor,
                        const char *texturePath, const char *vertexShaderPath, const char *fragmentShaderPath) {
    Model *model = new Model();
    model->shaders = programWithShaders(vertexShaderPath, fragmentShaderPath);
    model->drawType = drawType;
    model->drawCount = drawCount;
    model->drawStart = drawStart;
    model->shininess = shininess;
    model->specularColor = specularColor;
    model->texture = textureFromFile(texturePath);
    
    // Create buffers
    glGenBuffers(1, &model->vbo);
    glGenBuffers(1, &model->nbo);
    glGenBuffers(1, &model->tbo);
    glGenVertexArrays(1, &model->vao);
    glGenBuffers(1, &model->ebo);
    
    // Bind array
    glBindVertexArray(model->vao);
    
    // Load the vertex data.
    glBindBuffer(GL_ARRAY_BUFFER, model->vbo);
    glBufferData(GL_ARRAY_BUFFER, vertexData.size() * sizeof(glm::vec3), &vertexData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(model->shaders->attrib("vert"));
    glVertexAttribPointer(model->shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, model->tbo);
    glBufferData(GL_ARRAY_BUFFER, textureData.size() * sizeof(glm::vec2), &textureData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(model->shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(model->shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), NULL);
    
    // Load the normal data
    glBindBuffer(GL_ARRAY_BUFFER, model->nbo);
    glBufferData(GL_ARRAY_BUFFER, normalData.size() * sizeof(glm::vec3), &normalData[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(model->shaders->attrib("vertNormal"));
    glVertexAttribPointer(model->shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, model->ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementData.size() * sizeof(GLuint), &elementData[0], GL_STATIC_DRAW);
    
    glBindVertexArray(0);
    
    return model;
}

static Model *loadFloorModel() {
    Model *floor = new Model();
    floor->shaders = programWithShaders("vertex-shader.vsh", "fragment-shader.fsh");
    floor->drawType = GL_TRIANGLES;
    floor->drawStart = 0;
    floor->drawCount = 6;
    floor->shininess = 80.0f;
    floor->specularColor = glm::vec3(1.0f, 1.0f, 1.0f);
    floor->texture = textureFromFile("concrete_texture.jpg");
    
    // Generate buffers and vertex arrays
    glGenBuffers(1, &floor->vbo);
    glGenBuffers(1, &floor->tbo);
    glGenBuffers(1, &floor->nbo);
    glGenVertexArrays(1, &floor->vao);
    // Generate a buffer for the element array
    glGenBuffers(1, &floor->ebo);
    
    // Bind the vertex array
    glBindVertexArray(floor->vao);
    
    // Bind the vertex data buffer
    glBindBuffer(GL_ARRAY_BUFFER, floor->vbo);
    GLfloat floorVertexData[] = {
    //    X     Y     Z
        -1.5f, 0.0f, 1.0f,
        1.5f, 0.0f, 1.0f,
        1.5f, 0.0f, -1.0f,
        -1.5f, 0.0f, -1.0f,
    };
    // Copy vertex data to OpenGL buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorVertexData), floorVertexData, GL_STATIC_DRAW);
    
    // Attach vert to vbo
    glEnableVertexAttribArray(floor->shaders->attrib("vert"));
    glVertexAttribPointer(floor->shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, floor->tbo);
    GLfloat floorTextureData[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorTextureData), floorTextureData, GL_STATIC_DRAW);
    
    // Attach vertTextureData to tbo
    glEnableVertexAttribArray(floor->shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(floor->shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), NULL);
    
    // Bind the normal data buffer
    glBindBuffer(GL_ARRAY_BUFFER, floor->nbo);
    GLfloat floorNormalData[] = {
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f
    };
    // Copy the normal data to OpenGL buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorNormalData), floorNormalData, GL_STATIC_DRAW);
    
    // Point vertNormal to this buffer
    glEnableVertexAttribArray(floor->shaders->attrib("vertNormal"));
    glVertexAttribPointer(floor->shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // Bind the element buffer
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, floor->ebo);
    GLuint floorElementData[] = {
        0, 1, 2,
        2, 3, 0
    };
    // Copy element data to OpenGL buffer
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(floorElementData), floorElementData, GL_STATIC_DRAW);
    
    // Unbind the VAO
    glBindVertexArray(0);
    
    return floor;
}

static Model *loadWallModel() {
    Model *wall = new Model();
    wall->shaders = programWithShaders("vertex-shader.vsh", "fragment-shader.fsh");
    wall->drawType = GL_TRIANGLES;
    wall->drawStart = 0;
    wall->drawCount = 6;
    wall->shininess = 80.0f;
    wall->specularColor = glm::vec3(1.0f, 1.0f, 1.0f);
    wall->texture = textureFromFile("brick_texture.jpg");
    
    glGenBuffers(1, &wall->vbo);
    glGenBuffers(1, &wall->tbo);
    glGenBuffers(1, &wall->nbo);
    glGenVertexArrays(1, &wall->vao);
    glGenBuffers(1, &wall->ebo);
    
    glBindVertexArray(wall->vao);
    
    glBindBuffer(GL_ARRAY_BUFFER, wall->vbo);
    GLfloat wallVertexData[] = {
    //    X      Y     Z
        -1.5f, -1.0f, 0.0f,
        -1.5f, 1.0f, 0.0f,
        1.5f, 1.0f, 0.0f,
        1.5f, -1.0f, 0.0f,
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(wallVertexData), wallVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(wall->shaders->attrib("vert"));
    glVertexAttribPointer(wall->shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, wall->tbo);
    GLfloat wallTextureData[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(wallTextureData), wallTextureData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(wall->shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(wall->shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, wall->nbo);
    GLfloat wallNormalData[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(wallNormalData), wallNormalData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(wall->shaders->attrib("vertNormal"));
    glVertexAttribPointer(wall->shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, wall->ebo);
    GLuint wallElementData[] = {
        0, 1, 2,
        2, 3, 0
    };
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(wallElementData), wallElementData, GL_STATIC_DRAW);
    
    glBindVertexArray(0);
    
    return wall;
}

/*static Model *loadMetalBoxModel() {
    // Load the vertex data. The vertices are specified according to the surfaces they describe (front/back/etc.)
    GLfloat _torsoVertexData[] = {
        // Front
        1.0f, 1.0f, 1.0f,
        1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, 1.0f,
        -1.0f, 1.0f, 1.0f,
        // Back
        1.0f, 1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, 1.0f, -1.0f,
        // Left
        -1.0f, 1.0f, 1.0f,
        -1.0f, 1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f, 1.0f,
        // Right
        1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, 1.0f,
        // Top
        -1.0f, 1.0f, 1.0f,
        -1.0f, 1.0f, -1.0f,
        1.0f, 1.0f, -1.0f,
        1.0f, 1.0f, 1.0f,
        // Bottom
        -1.0f, -1.0f, 1.0f,
        1.0f, -1.0f, 1.0f,
        1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f
    };
    
    std::vector<GLfloat> torsoVertexData(_torsoVertexData, _torsoVertexData + sizeof(_torsoVertexData) / sizeof(_torsoVertexData[0]));

    GLfloat _torsoTextureData[] = {
        // Front
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        // Back
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        // Left
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        // Right
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        // Top
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        // Bottom
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f
    };
    std::vector<GLfloat> torsoTextureData(_torsoTextureData, _torsoTextureData + sizeof(_torsoTextureData) / sizeof(_torsoTextureData[0]));

    GLfloat _torsoNormalData[] = {
        // Front
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        // Back
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        // Left
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        // Right
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        // Top
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        // Bottom
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f
    };
    std::vector<GLfloat> torsoNormalData(_torsoNormalData, _torsoNormalData + sizeof(_torsoNormalData) / sizeof(_torsoNormalData[0]));

    GLuint _torsoElementData[] {
        // Front
        0, 1, 2,
        2, 3, 0,
        // Back
        4, 5, 6,
        6, 7, 4,
        // Left
        8, 9, 10,
        10, 11, 8,
        // Right
        12, 13, 14,
        14, 15, 12,
        // Top
        16, 17, 18,
        18, 19, 16,
        // Bottom
        20, 21, 22,
        22, 23, 20
    };
    std::vector<GLuint> torsoElementData(_torsoElementData, _torsoElementData + sizeof(_torsoElementData) / sizeof(_torsoElementData[0]));
    
    Model *torso = loadModel(torsoVertexData, torsoTextureData, torsoNormalData, torsoElementData,
                             GL_TRIANGLES, 6 * 2 * 3, 0,
                             120.0f, glm::vec3(1.0f),
                             "metal_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    return torso;
} */

static std::map<std::string, Model *> loadRobotModels() {
    // Load the arrays from the file
    std::map<std::string, ModelData> robotData = loadModelsFromObj("RobotModel.obj");
    std::map<std::string, Model *> robotModels;
    
    for (std::map<std::string, ModelData>::const_iterator it = robotData.begin(); it != robotData.end(); ++it) {
        Model *model = loadModel(it->second.vertexData, it->second.textureData, it->second.normalData, it->second.indexData,
                                 GL_TRIANGLES, 36, 0,
                                 120.0f, glm::vec3(1.0f),
                                 "metal_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
        robotModels[it->first] = model;
    }
    
    return robotModels;
}

static void createScene(std::list<RenderNode *>& renderNodes) {
    /*
     * Construct the room
     */
    Model *floorModel = loadFloorModel();
    
    ModelInstance *floorInstance = new ModelInstance();
    RenderNode *floorNode = new RenderNode();
    floorInstance->model = floorModel;
    floorInstance->transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 0, 4));
    floorNode->instance = floorInstance;
    renderNodes.push_back(floorNode);
    
    ModelInstance *ceilingInstance = new ModelInstance();
    RenderNode *ceilingNode = new RenderNode();
    ceilingInstance->model = floorModel;
    ceilingInstance->transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 0, 4));
    ceilingInstance->transform.rotate = glm::rotate(glm::mat4(), 180.0f, glm::vec3(1.0f, 0.0f, 0.0f));
    ceilingInstance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 8, 0));
    ceilingNode->instance = ceilingInstance;
    renderNodes.push_back(ceilingNode);
    
    Model *wallModel = loadWallModel();
    
    ModelInstance *backWall = new ModelInstance();
    RenderNode *backWallNode = new RenderNode();
    backWall->model = wallModel;
    backWall->transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 4, 0));
    backWall->transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 4, -4));
    backWallNode->instance = backWall;
    renderNodes.push_back(backWallNode);
    
    ModelInstance *frontWall = new ModelInstance();
    RenderNode *frontWallNode = new RenderNode();
    frontWall->model = wallModel;
    frontWall->transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 4, 0));
    frontWall->transform.rotate = glm::rotate(glm::mat4(), 180.0f, glm::vec3(0, 1.0f, 0));
    frontWall->transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 4, 4));
    frontWallNode->instance = frontWall;
    renderNodes.push_back(frontWallNode);
    
    ModelInstance *leftWall = new ModelInstance();
    RenderNode *leftWallNode = new RenderNode();
    leftWall->model = wallModel;
    leftWall->transform.scale = glm::scale(glm::mat4(), glm::vec3(4.0f / 1.5f, 4.0f, 0.0f));
    leftWall->transform.rotate = glm::rotate(glm::mat4(), 90.0f, glm::vec3(0, 1.0f, 0));
    leftWall->transform.translate = glm::translate(glm::mat4(), glm::vec3(-6, 4, 0));
    leftWallNode->instance = leftWall;
    renderNodes.push_back(leftWallNode);
    
    ModelInstance *rightWall = new ModelInstance();
    RenderNode *rightWallNode = new RenderNode();
    rightWall->model = wallModel;
    rightWall->transform.scale = glm::scale(glm::mat4(), glm::vec3(4.0f / 1.5f, 4.0f, 0.0f));
    rightWall->transform.rotate = glm::rotate(glm::mat4(), -90.0f, glm::vec3(0, 1.0f, 0));
    rightWall->transform.translate = glm::translate(glm::mat4(), glm::vec3(6, 4, 0));
    rightWallNode->instance = rightWall;
    renderNodes.push_back(rightWallNode);
    
    /*
     * Construct the Robot from its various parts
     */
    std::map<std::string, Model *> robotModels = loadRobotModels();
    RenderNode *headNode = new RenderNode(new ModelInstance(robotModels["Head"]));
    RenderNode *torsoNode = new RenderNode(new ModelInstance(robotModels["Torso"]));
    RenderNode *rightArmNode = new RenderNode(new ModelInstance(robotModels["R_Arm"]));
    RenderNode *rightWristNode = new RenderNode(new ModelInstance(robotModels["R_Wrist"]));
    RenderNode *leftArmNode = new RenderNode(new ModelInstance(robotModels["L_Arm"]));
    RenderNode *leftWristNode = new RenderNode(new ModelInstance(robotModels["L_Wrist"]));
    RenderNode *rightLegNode = new RenderNode(new ModelInstance(robotModels["R_Leg"]));
    RenderNode *leftLegNode = new RenderNode(new ModelInstance(robotModels["L_Leg"]));
    
    rightArmNode->children.push_back(rightWristNode);
    leftArmNode->children.push_back(leftWristNode);
    torsoNode->children.push_back(leftLegNode);
    torsoNode->children.push_back(rightLegNode);
    torsoNode->children.push_back(leftArmNode);
    torsoNode->children.push_back(rightArmNode);
    torsoNode->children.push_back(headNode);
    
    renderNodes.push_back(torsoNode);
}

void updatePositions() {
    
}

// Render a single instance
void renderInstance(const ModelInstance& instance, const glm::mat4& modelTransform) {
    Model *model = instance.model;
    ShaderProgram *shaders = model->shaders;
    
    // Start using the shader program
    shaders->use();
    
    // Set the uniforms
    shaders->setUniform("model", modelTransform);
    shaders->setUniform("view", camera.view());
    shaders->setUniform("projection", camera.projection());
    shaders->setUniform("materialTexture", 0);
//    shaders->setUniform("materialShininess", model->shininess);
//    shaders->setUniform("materialSpecularColor", model->specularColor);
    shaders->setUniform("light.position", light.position);
    shaders->setUniform("light.intensities", light.intensities);
    shaders->setUniform("light.attentuation", light.attentuation);
    shaders->setUniform("light.ambientCoefficient", light.ambientCoefficient);
//    shaders->setUniform("cameraPosition", camera.position());
    
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

void renderRecursive(const RenderNode *node, MatrixStack& modelTransformStack) {
    modelTransformStack.push(node->instance->transform.matrix());
    
    // Render all children recursively
    std::list<RenderNode *>::const_iterator it;
    for (it = node->children.begin(); it != node->children.end(); ++it)
        renderRecursive(*it, modelTransformStack);
    
    // Render this instance
    renderInstance(*(node->instance), modelTransformStack.multiplyMatrices());
    
    // Pop the matrices
    modelTransformStack.pop();
}

void renderFrame(const std::list<RenderNode *>& scene) {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MatrixStack matrixStack;
    
    std::list<RenderNode *>::const_iterator it;
    for (it = scene.begin(); it != scene.end(); ++it)
        renderRecursive(*it, matrixStack);
}

static void glfwErrorCallbackFunc(int error, const char *desc) {
    std::cerr << "GLFW error description:" << std::endl << desc << std::endl;
}

static void glfwKeyCallbackFunc(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
    
    if (key == GLFW_KEY_1 && action == GLFW_PRESS) {
        if (light.ambientCoefficient < 1.0f)
            light.ambientCoefficient += 1.0f;
        else
            light.ambientCoefficient -= 1.0f;
    }
    
    if (key == GLFW_KEY_UP && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetOrientation(-5.0f, 0.0f);
    if (key == GLFW_KEY_DOWN && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetOrientation(5.0f, 0.0f);
    if (key == GLFW_KEY_RIGHT && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetOrientation(0.0f, 5.0f);
    if (key == GLFW_KEY_LEFT && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetOrientation(0.0f, -5.0f);
    
    if (key == GLFW_KEY_W && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetPosition(camera.forward());
    if (key == GLFW_KEY_S && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetPosition(-camera.forward());
    if (key == GLFW_KEY_A && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetPosition(-camera.right());
    if (key == GLFW_KEY_D && (action == GLFW_PRESS || action == GLFW_REPEAT))
        camera.offsetPosition(camera.right());
    
}

void glfwFramebufferResizeCallbackFunc(GLFWwindow *window, int width, int height) {
    camera.setViewportAspectRatio((float) width / (float) height);
}

void AppMain() {
    GLFWwindow *window;
    
    glfwSetErrorCallback(glfwErrorCallbackFunc);
    
    // Initialize GLFW
    if (!glfwInit())
        throw std::runtime_error("Error initializing GLFW");
    
    // Define the OpenGL version and the resizability of the window
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_RESIZABLE, GL_TRUE);
    
    // Create the window
    window = glfwCreateWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, "Robot", nullptr, nullptr);
    if (!window) {
        glfwTerminate();
        throw std::runtime_error("Error creating GLFW window");
    }
    
    glfwSetFramebufferSizeCallback(window, glfwFramebufferResizeCallbackFunc);
    glfwMakeContextCurrent(window);
    
    // Initialize GLEW
    glewExperimental = GL_TRUE;
    GLenum err = glewInit();
    if (err != GLEW_OK) {
        std::cerr << "GLEW error description:" << std::endl << glewGetErrorString(err) << std::endl;
        throw std::runtime_error("Error initializing GLEW");
    }
    
    // Discard all GLEW errors
    while (glGetError() != GL_NO_ERROR) {}
    
    // Print out some diagnostics
    std::cout << "OpenGL version: " << glGetString(GL_VERSION) << std::endl;
    std::cout << "GLSL version: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;
    std::cout << "Vendor: " << glGetString(GL_VENDOR) << std::endl;
    std::cout << "Renderer: " << glGetString(GL_RENDERER) << std::endl;
    
    // Make sure 3.2 is available
    if (!GLEW_VERSION_3_2)
        throw std::runtime_error("OpenGL 3.2 not supported");
    
    // Enable depth-testing
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
        
    glfwSetKeyCallback(window, glfwKeyCallbackFunc);
    
    std::list<RenderNode *> scene;
    createScene(scene);
    
    // Orient camera
    camera.setPosition(glm::vec3(0, 2, 0));
    camera.setViewportAspectRatio(SCREEN_SIZE.x / SCREEN_SIZE.y);
    camera.setNearAndFarPlanes(0.2f, 100.0f);
    camera.setFieldOfView(65.0f);
    
    // Setup light source parameters
    light.position = glm::vec3(-5, 3, 2);
    light.intensities = glm::vec3(1.0f, 1.0f, 1.0f); // white
    light.attentuation = 0.002f;
    light.ambientCoefficient = 0.5f;
    
    while (!glfwWindowShouldClose(window)) {
        updatePositions();
        renderFrame(scene);
        glfwSwapBuffers(window);
        
        GLenum error = glGetError();
        if (error != GL_NO_ERROR)
            std::cerr << "OpenGL error " << error << ": " << (const char *) gluErrorString(error) << std::endl;
        
        glfwPollEvents();
    }
    
    glfwDestroyWindow(window);
    glfwTerminate();
}

int main(int argc, char *argv[]) {
    try {
        AppMain();
    } catch (const std::exception& e) {
        std::cerr << "ERROR: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}