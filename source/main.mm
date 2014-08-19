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

static std::map<std::string, Model *> loadRoomModels() {
    std::map<std::string, ModelData> roomData = loadModelsFromObj("RoomModel.obj");
    std::map<std::string, Model *> roomModels;
    
    // Ceiling and floor
    roomModels["Ceiling"] = loadModel(roomData["Ceiling"].vertexData, roomData["Ceiling"].textureData, roomData["Ceiling"].normalData, roomData["Ceiling"].indexData,
                                       GL_TRIANGLES, roomData["Ceiling"].indexData.size(), 0,
                                       80.0f, glm::vec3(1.0f),
                                       "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    roomModels["Floor"] = loadModel(roomData["Floor"].vertexData, roomData["Floor"].textureData, roomData["Floor"].normalData, roomData["Floor"].indexData,
                                      GL_TRIANGLES, roomData["Floor"].indexData.size(), 0,
                                      80.0f, glm::vec3(1.0f),
                                      "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    // Walls
    roomModels["Left_Wall"] = loadModel(roomData["Left_Wall"].vertexData, roomData["Left_Wall"].textureData, roomData["Left_Wall"].normalData, roomData["Left_Wall"].indexData,
                                    GL_TRIANGLES, roomData["Left_Wall"].indexData.size(), 0,
                                    80.0f, glm::vec3(1.0f),
                                    "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Right_Wall"] = loadModel(roomData["Right_Wall"].vertexData, roomData["Right_Wall"].textureData, roomData["Right_Wall"].normalData, roomData["Right_Wall"].indexData,
                                        GL_TRIANGLES, roomData["Right_Wall"].indexData.size(), 0,
                                        80.0f, glm::vec3(1.0f),
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Front_Wall"] = loadModel(roomData["Front_Wall"].vertexData, roomData["Front_Wall"].textureData, roomData["Front_Wall"].normalData, roomData["Front_Wall"].indexData,
                                        GL_TRIANGLES, roomData["Front_Wall"].indexData.size(), 0,
                                        80.0f, glm::vec3(1.0f),
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Back_Wall"] = loadModel(roomData["Back_Wall"].vertexData, roomData["Back_Wall"].textureData, roomData["Back_Wall"].normalData, roomData["Back_Wall"].indexData,
                                        GL_TRIANGLES, roomData["Back_Wall"].indexData.size(), 0,
                                        80.0f, glm::vec3(1.0f),
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    return roomModels;
}

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
    std::map<std::string, Model *> roomModels = loadRoomModels();
    
    RenderNode *ceilingNode = new RenderNode(new ModelInstance(roomModels["Ceiling"]));
    renderNodes.push_back(ceilingNode);
    RenderNode *floorNode = new RenderNode(new ModelInstance(roomModels["Floor"]));
    renderNodes.push_back(floorNode);
    RenderNode *leftWallNode = new RenderNode(new ModelInstance(roomModels["Left_Wall"]));
    renderNodes.push_back(leftWallNode);
    RenderNode *rightWallNode = new RenderNode(new ModelInstance(roomModels["Right_Wall"]));
    renderNodes.push_back(rightWallNode);
    RenderNode *frontWallNode = new RenderNode(new ModelInstance(roomModels["Front_Wall"]));
    renderNodes.push_back(frontWallNode);
    RenderNode *backWallNode = new RenderNode(new ModelInstance(roomModels["Back_Wall"]));
    renderNodes.push_back(backWallNode);
    
    
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