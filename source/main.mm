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
#include <math.h>

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

float clampToMaxVertical(float angle, float addition) {
    if (angle + addition > 60)
        return 60;
    else if (angle + addition < -60)
        return -60;
    
    return angle + addition;
}

static inline float degreesToRadians(float degrees) {
    return degrees * (float) M_PI / 180.0f;
}

struct Orientations {
    float headHorizontal;
    float headVertical;
    
    float torsoHorizontal;
    
    float leftArmVertical;
    float leftWristVertical;
    
    float rightArmVertical;
    float rightWristVertical;
    
    Orientations() : headHorizontal(0), headVertical(0), torsoHorizontal(0),
        leftArmVertical(0), leftWristVertical(0), rightArmVertical(0), rightWristVertical(0) {}
};

const glm::vec2 initialScreenSize(800, 600);
Light lightSource;
Camera camera;
bool cameraInHead = false;
GLFWwindow *window;
std::map<std::string, RenderNode *> scene;
Orientations orientations;

static Model *loadModel(const std::vector<glm::vec3>& vertexData, const std::vector<glm::vec2>& textureData, const std::vector<glm::vec3>& normalData, const std::vector<GLuint>& elementData,
                        GLenum drawType, GLuint drawCount, GLuint drawStart,
                        glm::vec4 ambientColor, glm::vec4 diffuseColor, glm::vec4 specularColor, GLfloat shininess,
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
                                       GL_TRIANGLES, (GLuint) roomData["Ceiling"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 40.0f,
                                       "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    roomModels["Floor"] = loadModel(roomData["Floor"].vertexData, roomData["Floor"].textureData, roomData["Floor"].normalData, roomData["Floor"].indexData,
                                      GL_TRIANGLES, (GLuint) roomData["Floor"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 40.0f,
                                      "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    // Walls
    roomModels["Left_Wall"] = loadModel(roomData["Left_Wall"].vertexData, roomData["Left_Wall"].textureData, roomData["Left_Wall"].normalData, roomData["Left_Wall"].indexData,
                                    GL_TRIANGLES, (GLuint) roomData["Left_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                    "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Right_Wall"] = loadModel(roomData["Right_Wall"].vertexData, roomData["Right_Wall"].textureData, roomData["Right_Wall"].normalData, roomData["Right_Wall"].indexData,
                                        GL_TRIANGLES, (GLuint) roomData["Right_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Front_Wall"] = loadModel(roomData["Front_Wall"].vertexData, roomData["Front_Wall"].textureData, roomData["Front_Wall"].normalData, roomData["Front_Wall"].indexData,
                                        GL_TRIANGLES, (GLuint) roomData["Front_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Back_Wall"] = loadModel(roomData["Back_Wall"].vertexData, roomData["Back_Wall"].textureData, roomData["Back_Wall"].normalData, roomData["Back_Wall"].indexData,
                                        GL_TRIANGLES, (GLuint) roomData["Back_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
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
                                 glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 120.0f,
                                 "metal_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
        robotModels[it->first] = model;
    }
    
    return robotModels;
}

static void createScene() {
    /*
     * Construct the room
     */
    std::map<std::string, Model *> roomModels = loadRoomModels();
    
    RenderNode *ceilingNode = new RenderNode(new ModelInstance(roomModels["Ceiling"]));
    scene["Ceiling"] = ceilingNode;
    RenderNode *floorNode = new RenderNode(new ModelInstance(roomModels["Floor"]));
    scene["Floor"] = floorNode;
    RenderNode *leftWallNode = new RenderNode(new ModelInstance(roomModels["Left_Wall"]));
    scene["Left_Wall"] = leftWallNode;
    RenderNode *rightWallNode = new RenderNode(new ModelInstance(roomModels["Right_Wall"]));
    scene["Right_Wall"] = rightWallNode;
    RenderNode *frontWallNode = new RenderNode(new ModelInstance(roomModels["Front_Wall"]));
    scene["Front_Wall"] = frontWallNode;
    RenderNode *backWallNode = new RenderNode(new ModelInstance(roomModels["Back_Wall"]));
    scene["Back_Wall"] = backWallNode;
    
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
    
    // All the translations that we wrote down in Blender
    headNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0050, 1.6611, -0.0563));
    leftArmNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0672, 0.2466, -1.4236));
    leftWristNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0092, -1.2856, -0.0097));
    rightArmNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0580, 0.2572, 1.4286));
    rightWristNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0092, -1.2856, -0.0097));
    rightLegNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0881, -1.8537, 0.5387));
    leftLegNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0881, -1.8541, -0.5452));
    torsoNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0, 2.0, 0.0));
    
    rightArmNode->children["Right_Wrist"] = rightWristNode;
    leftArmNode->children["Left_Wrist"] = leftWristNode;
    torsoNode->children["Left_Leg"] = leftLegNode;
    torsoNode->children["Right_Leg"] = rightLegNode;
    torsoNode->children["Left_Arm"] = leftArmNode;
    torsoNode->children["Right_Arm"] = rightArmNode;
    torsoNode->children["Head"] = headNode;
    scene["Torso"] = torsoNode;
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
    shaders->setUniform("material.ambient", model->ambientColor);
    shaders->setUniform("material.diffuse", model->diffuseColor);
    shaders->setUniform("material.specular", model->specularColor);
    shaders->setUniform("material.shininess", model->shininess);
    
    shaders->setUniform("light.position", lightSource.position);
    shaders->setUniform("light.diffuse", lightSource.diffuseColor);
    shaders->setUniform("light.specular", lightSource.specularColor);
    shaders->setUniform("light.ambient", lightSource.ambientColor);
    shaders->setUniform("light.attenuation", lightSource.attentuation);
    
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
    std::map<std::string, RenderNode *>::const_iterator it;
    for (it = node->children.begin(); it != node->children.end(); ++it)
        renderRecursive(it->second, modelTransformStack);
    
    // Render this instance
    renderInstance(*(node->instance), modelTransformStack.multiplyMatrices());
    
    // Pop the matrices
    modelTransformStack.pop();
}

void renderFrame(const std::map<std::string, RenderNode *>& scene) {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MatrixStack matrixStack;
    
    std::map<std::string, RenderNode *>::const_iterator it;
    for (it = scene.begin(); it != scene.end(); ++it)
        renderRecursive(it->second, matrixStack);
}

static void glfwErrorCallbackFunc(int error, const char *desc) {
    std::cerr << "GLFW error description:" << std::endl << desc << std::endl;
}

static glm::mat4 getCameraInHeadMatrix() {
    ModelTransform torsoTransform = scene["Torso"]->instance->transform;
    ModelTransform headTransform = scene["Torso"]->children["Head"]->instance->transform;
    
    return torsoTransform.matrix() * headTransform.matrix();
}

void updatePositions(float timeDiff) {
    const float movementSpeed = 1.5f;
    float headVerticalDiff = 0, headHorizontalDiff = 0, torsoHorizontalDiff = 0, leftArmVerticalDiff = 0, leftWristVerticalDiff = 0, rightArmVerticalDiff = 0, rightWristVerticalDiff = 0;
    float torsoTranslationDiff = 0;
    
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
    
    if (glfwGetKey(window, GLFW_KEY_RIGHT_BRACKET) == GLFW_PRESS)
        lightSource.ambientColor += 0.1;
    if (glfwGetKey(window, GLFW_KEY_LEFT_BRACKET) == GLFW_PRESS)
        lightSource.ambientColor -= 0.1;
    
    if (!cameraInHead) {
        // Camera movement
        if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
            camera.offsetPosition(timeDiff * movementSpeed * camera.forward());
        if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
            camera.offsetPosition(timeDiff * movementSpeed * -camera.forward());
        if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
            camera.offsetPosition(timeDiff * movementSpeed * -camera.right());
        if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
            camera.offsetPosition(timeDiff * movementSpeed * camera.right());
        
        const float mouseSensitivity = 0.1f;
        double mouseX, mouseY;
        
        glfwGetCursorPos(window, &mouseX, &mouseY);
        camera.offsetOrientation(mouseSensitivity * mouseY, mouseSensitivity * mouseX);
        glfwSetCursorPos(window, 0, 0);
    }
    
    // Head movement
    if (glfwGetKey(window, GLFW_KEY_Z) == GLFW_PRESS)
        headHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_X) == GLFW_PRESS)
        headHorizontalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_C) == GLFW_PRESS)
        headVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_V) == GLFW_PRESS)
        headVerticalDiff -= 45.0f * timeDiff;
    
    // Torso movement
    if (glfwGetKey(window, GLFW_KEY_I) == GLFW_PRESS)
        torsoTranslationDiff += timeDiff * movementSpeed;
    if (glfwGetKey(window, GLFW_KEY_K) == GLFW_PRESS)
        torsoTranslationDiff -= timeDiff * movementSpeed;
    if (glfwGetKey(window, GLFW_KEY_J) == GLFW_PRESS)
        torsoHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_L) == GLFW_PRESS)
        torsoHorizontalDiff -= 45.0f * timeDiff;
    
    // Arms
    if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS)
        leftArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS)
        leftArmVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_3) == GLFW_PRESS)
        rightArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_4) == GLFW_PRESS)
        rightArmVerticalDiff -= 45.0f * timeDiff;
    
    // Wrists
    if (glfwGetKey(window, GLFW_KEY_5) == GLFW_PRESS)
        leftWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_6) == GLFW_PRESS)
        leftWristVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_7) == GLFW_PRESS)
        rightWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(window, GLFW_KEY_8) == GLFW_PRESS)
        rightWristVerticalDiff -= 45.0f * timeDiff;
    
    // Update all orientations
    orientations.torsoHorizontal += torsoHorizontalDiff;
    
    orientations.torsoHorizontal = fmodf(orientations.torsoHorizontal, 360.0f);
    if (orientations.torsoHorizontal < 0.0f)
        orientations.torsoHorizontal += 360.0f;
    
    orientations.headHorizontal += headHorizontalDiff;
    orientations.headVertical = clampToMaxVertical(orientations.headVertical, headVerticalDiff);
    orientations.leftArmVertical = clampToMaxVertical(orientations.leftArmVertical, leftArmVerticalDiff);
    orientations.leftWristVertical = clampToMaxVertical(orientations.leftWristVertical, leftWristVerticalDiff);
    orientations.rightArmVertical = clampToMaxVertical(orientations.rightArmVertical, rightArmVerticalDiff);
    orientations.rightWristVertical = clampToMaxVertical(orientations.rightWristVertical, rightWristVerticalDiff);
    
    float xTrans, zTrans;
    xTrans = torsoTranslationDiff * cosf(degreesToRadians(orientations.torsoHorizontal));
    zTrans = -torsoTranslationDiff * sinf(degreesToRadians(orientations.torsoHorizontal));
    
    // Update matrices
    scene["Torso"]->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(xTrans, 0.0f, zTrans)) * scene["Torso"]->instance->transform.translate;
    scene["Torso"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.torsoHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    
    scene["Torso"]->children["Head"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.headHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    scene["Torso"]->children["Head"]->instance->transform.rotate *= glm::rotate(glm::mat4(), orientations.headVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    
    if (cameraInHead) {
        camera.offsetPosition(glm::vec3(xTrans, 0.0, zTrans));
        camera.offsetOrientation(headVerticalDiff, - (torsoHorizontalDiff + headHorizontalDiff));
    }
    
    scene["Torso"]->children["Left_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.leftArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    scene["Torso"]->children["Left_Arm"]->children["Left_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.leftWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    scene["Torso"]->children["Right_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.rightArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    scene["Torso"]->children["Right_Arm"]->children["Right_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), orientations.rightWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
}

void glfwFramebufferResizeCallbackFunc(GLFWwindow *window, int width, int height) {
    camera.setViewportAspectRatio((float) width / (float) height);
}

void glfwKeyCallbackFunc(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_0 && action == GLFW_PRESS) {
        cameraInHead = !cameraInHead;
    
        if (cameraInHead) {
            camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            camera.lookAt(glm::vec3(0, 2, -1));
            camera.setPosition(glm::vec3(getCameraInHeadMatrix() * glm::vec4(0.0, 0.0, 0.0, 1.0)));
            camera.offsetOrientation(orientations.headVertical, - (orientations.headHorizontal + orientations.torsoHorizontal - 90.0f));
        }
        
        if (!cameraInHead) {
            camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            camera.lookAt(glm::vec3(0, 2, -1));
        }
    }
}

void AppMain() {
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
    window = glfwCreateWindow(initialScreenSize.x, initialScreenSize.y, "Robot", nullptr, nullptr);
    if (!window) {
        glfwTerminate();
        throw std::runtime_error("Error creating GLFW window");
    }
    
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glfwSetCursorPos(window, 0, 0);
    glfwSetFramebufferSizeCallback(window, glfwFramebufferResizeCallbackFunc);
    glfwSetKeyCallback(window, glfwKeyCallbackFunc);
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
    
    // Enable back-face-culling
    glEnable(GL_CULL_FACE);
    
    createScene();
    
    // Orient camera
    camera.setPosition(glm::vec3(0, 2, 0));
    camera.lookAt(glm::vec3(0, 2, -1));
    camera.setViewportAspectRatio(initialScreenSize.x / initialScreenSize.y);
    camera.setNearAndFarPlanes(0.2f, 100.0f);
    camera.setFieldOfView(65.0f);
    
    lightSource.position = glm::vec4(5.0, 3.0, -2.0, 1.0);
    lightSource.diffuseColor = glm::vec4(0.5);
    lightSource.specularColor = glm::vec4(1.0);
    lightSource.ambientColor = glm::vec4(1.5);
    lightSource.attentuation = 1.2;
    
    double lastTime = glfwGetTime();
    while (!glfwWindowShouldClose(window)) {
        double currentTime = glfwGetTime();
        updatePositions(currentTime - lastTime);
        lastTime = currentTime;
        
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