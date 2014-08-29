//
//  main.mm
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

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
Light _lightSource;
Camera _camera;
bool cameraInHead = false;
GLFWwindow *_window;
std::map<std::string, RenderNode *> _scene;
Orientations _robotOrientations;

static std::map<std::string, Model *> loadRoomModels() {
    std::map<std::string, ModelData> roomData = loadModelsFromObj("RoomModel.obj");
    std::map<std::string, Model *> roomModels;
    
    // Ceiling and floor
    roomModels["Ceiling"] = new Model(roomData["Ceiling"].vertexData, roomData["Ceiling"].textureData, roomData["Ceiling"].normalData, roomData["Ceiling"].indexData,
                                       GL_TRIANGLES, (GLuint) roomData["Ceiling"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 40.0f,
                                       "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    roomModels["Floor"] = new Model(roomData["Floor"].vertexData, roomData["Floor"].textureData, roomData["Floor"].normalData, roomData["Floor"].indexData,
                                      GL_TRIANGLES, (GLuint) roomData["Floor"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 40.0f,
                                      "concrete_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    
    // Walls
    roomModels["Left_Wall"] = new Model(roomData["Left_Wall"].vertexData, roomData["Left_Wall"].textureData, roomData["Left_Wall"].normalData, roomData["Left_Wall"].indexData,
                                    GL_TRIANGLES, (GLuint) roomData["Left_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                    "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Right_Wall"] = new Model(roomData["Right_Wall"].vertexData, roomData["Right_Wall"].textureData, roomData["Right_Wall"].normalData, roomData["Right_Wall"].indexData,
                                        GL_TRIANGLES, (GLuint) roomData["Right_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Front_Wall"] = new Model(roomData["Front_Wall"].vertexData, roomData["Front_Wall"].textureData, roomData["Front_Wall"].normalData, roomData["Front_Wall"].indexData,
                                        GL_TRIANGLES, (GLuint) roomData["Front_Wall"].indexData.size(), 0,
                                      glm::vec4(1.0f), glm::vec4(1.0f), glm::vec4(1.0f), 20.0f,
                                        "brick_texture.jpg", "vertex-shader.vsh", "fragment-shader.fsh");
    roomModels["Back_Wall"] = new Model(roomData["Back_Wall"].vertexData, roomData["Back_Wall"].textureData, roomData["Back_Wall"].normalData, roomData["Back_Wall"].indexData,
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
        Model *model = new Model(it->second.vertexData, it->second.textureData, it->second.normalData, it->second.indexData,
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
    _scene["Ceiling"] = ceilingNode;
    RenderNode *floorNode = new RenderNode(new ModelInstance(roomModels["Floor"]));
    _scene["Floor"] = floorNode;
    RenderNode *leftWallNode = new RenderNode(new ModelInstance(roomModels["Left_Wall"]));
    _scene["Left_Wall"] = leftWallNode;
    RenderNode *rightWallNode = new RenderNode(new ModelInstance(roomModels["Right_Wall"]));
    _scene["Right_Wall"] = rightWallNode;
    RenderNode *frontWallNode = new RenderNode(new ModelInstance(roomModels["Front_Wall"]));
    _scene["Front_Wall"] = frontWallNode;
    RenderNode *backWallNode = new RenderNode(new ModelInstance(roomModels["Back_Wall"]));
    _scene["Back_Wall"] = backWallNode;
    
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
    _scene["Torso"] = torsoNode;
}

void renderFrame(const std::map<std::string, RenderNode *>& scene) {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MatrixStack matrixStack;
    
    std::map<std::string, RenderNode *>::const_iterator it;
    for (it = scene.begin(); it != scene.end(); ++it)
        it->second->renderRecursive(matrixStack, _camera, _lightSource);
}

static void glfwErrorCallbackFunc(int error, const char *desc) {
    std::cerr << "GLFW error description:" << std::endl << desc << std::endl;
}

static glm::mat4 getCameraInHeadMatrix() {
    ModelTransform torsoTransform = _scene["Torso"]->instance->transform;
    ModelTransform headTransform = _scene["Torso"]->children["Head"]->instance->transform;
    
    return torsoTransform.matrix() * headTransform.matrix();
}

void updatePositions(float timeDiff) {
    const float movementSpeed = 1.5f;
    float headVerticalDiff = 0, headHorizontalDiff = 0, torsoHorizontalDiff = 0, leftArmVerticalDiff = 0, leftWristVerticalDiff = 0, rightArmVerticalDiff = 0, rightWristVerticalDiff = 0;
    float torsoTranslationDiff = 0;
    
    if (glfwGetKey(_window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(_window, GL_TRUE);
    
    if (glfwGetKey(_window, GLFW_KEY_RIGHT_BRACKET) == GLFW_PRESS)
        _lightSource.ambientColor += 0.1;
    if (glfwGetKey(_window, GLFW_KEY_LEFT_BRACKET) == GLFW_PRESS)
        _lightSource.ambientColor -= 0.1;
    
    if (!cameraInHead) {
        // Camera movement
        if (glfwGetKey(_window, GLFW_KEY_W) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * movementSpeed * _camera.forward());
        if (glfwGetKey(_window, GLFW_KEY_S) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * movementSpeed * -_camera.forward());
        if (glfwGetKey(_window, GLFW_KEY_A) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * movementSpeed * -_camera.right());
        if (glfwGetKey(_window, GLFW_KEY_D) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * movementSpeed * _camera.right());
        
        const float mouseSensitivity = 0.1f;
        double mouseX, mouseY;
        
        glfwGetCursorPos(_window, &mouseX, &mouseY);
        _camera.offsetOrientation(mouseSensitivity * mouseY, mouseSensitivity * mouseX);
        glfwSetCursorPos(_window, 0, 0);
    }
    
    // Head movement
    if (glfwGetKey(_window, GLFW_KEY_Z) == GLFW_PRESS)
        headHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_X) == GLFW_PRESS)
        headHorizontalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_C) == GLFW_PRESS)
        headVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_V) == GLFW_PRESS)
        headVerticalDiff -= 45.0f * timeDiff;
    
    // Torso movement
    if (glfwGetKey(_window, GLFW_KEY_I) == GLFW_PRESS)
        torsoTranslationDiff += timeDiff * movementSpeed;
    if (glfwGetKey(_window, GLFW_KEY_K) == GLFW_PRESS)
        torsoTranslationDiff -= timeDiff * movementSpeed;
    if (glfwGetKey(_window, GLFW_KEY_J) == GLFW_PRESS)
        torsoHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_L) == GLFW_PRESS)
        torsoHorizontalDiff -= 45.0f * timeDiff;
    
    // Arms
    if (glfwGetKey(_window, GLFW_KEY_1) == GLFW_PRESS)
        leftArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_2) == GLFW_PRESS)
        leftArmVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_3) == GLFW_PRESS)
        rightArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_4) == GLFW_PRESS)
        rightArmVerticalDiff -= 45.0f * timeDiff;
    
    // Wrists
    if (glfwGetKey(_window, GLFW_KEY_5) == GLFW_PRESS)
        leftWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_6) == GLFW_PRESS)
        leftWristVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_7) == GLFW_PRESS)
        rightWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_8) == GLFW_PRESS)
        rightWristVerticalDiff -= 45.0f * timeDiff;
    
    // Update all orientations
    _robotOrientations.torsoHorizontal += torsoHorizontalDiff;
    
    _robotOrientations.torsoHorizontal = fmodf(_robotOrientations.torsoHorizontal, 360.0f);
    if (_robotOrientations.torsoHorizontal < 0.0f)
        _robotOrientations.torsoHorizontal += 360.0f;
    
    _robotOrientations.headHorizontal += headHorizontalDiff;
    _robotOrientations.headVertical = clampToMaxVertical(_robotOrientations.headVertical, headVerticalDiff);
    _robotOrientations.leftArmVertical = clampToMaxVertical(_robotOrientations.leftArmVertical, leftArmVerticalDiff);
    _robotOrientations.leftWristVertical = clampToMaxVertical(_robotOrientations.leftWristVertical, leftWristVerticalDiff);
    _robotOrientations.rightArmVertical = clampToMaxVertical(_robotOrientations.rightArmVertical, rightArmVerticalDiff);
    _robotOrientations.rightWristVertical = clampToMaxVertical(_robotOrientations.rightWristVertical, rightWristVerticalDiff);
    
    float xTrans, zTrans;
    xTrans = torsoTranslationDiff * cosf(degreesToRadians(_robotOrientations.torsoHorizontal));
    zTrans = -torsoTranslationDiff * sinf(degreesToRadians(_robotOrientations.torsoHorizontal));
    
    // Update matrices
    _scene["Torso"]->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(xTrans, 0.0f, zTrans)) * _scene["Torso"]->instance->transform.translate;
    _scene["Torso"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.torsoHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    
    _scene["Torso"]->children["Head"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.headHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    _scene["Torso"]->children["Head"]->instance->transform.rotate *= glm::rotate(glm::mat4(), _robotOrientations.headVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    
    if (cameraInHead) {
        _camera.offsetPosition(glm::vec3(xTrans, 0.0, zTrans));
        _camera.offsetOrientation(headVerticalDiff, - (torsoHorizontalDiff + headHorizontalDiff));
    }
    
    _scene["Torso"]->children["Left_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.leftArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Left_Arm"]->children["Left_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.leftWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Right_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.rightArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Right_Arm"]->children["Right_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.rightWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
}

void glfwFramebufferResizeCallbackFunc(GLFWwindow *window, int width, int height) {
    _camera.setViewportAspectRatio((float) width / (float) height);
}

void glfwKeyCallbackFunc(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_0 && action == GLFW_PRESS) {
        cameraInHead = !cameraInHead;
    
        if (cameraInHead) {
            _camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            _camera.lookAt(glm::vec3(0, 2, -1));
            _camera.setPosition(glm::vec3(getCameraInHeadMatrix() * glm::vec4(0.0, 0.0, 0.0, 1.0)));
            _camera.offsetOrientation(_robotOrientations.headVertical, - (_robotOrientations.headHorizontal + _robotOrientations.torsoHorizontal - 90.0f));
        }
        
        if (!cameraInHead) {
            _camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            _camera.lookAt(glm::vec3(0, 2, -1));
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
    _window = glfwCreateWindow(initialScreenSize.x, initialScreenSize.y, "Robot", nullptr, nullptr);
    if (!_window) {
        glfwTerminate();
        throw std::runtime_error("Error creating GLFW window");
    }
    
    glfwSetInputMode(_window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glfwSetCursorPos(_window, 0, 0);
    glfwSetFramebufferSizeCallback(_window, glfwFramebufferResizeCallbackFunc);
    glfwSetKeyCallback(_window, glfwKeyCallbackFunc);
    glfwMakeContextCurrent(_window);
    
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
    _camera.setPosition(glm::vec3(0, 2, 0));
    _camera.lookAt(glm::vec3(0, 2, -1));
    _camera.setViewportAspectRatio(initialScreenSize.x / initialScreenSize.y);
    _camera.setNearAndFarPlanes(0.2f, 100.0f);
    _camera.setFieldOfView(65.0f);
    
    _lightSource.position = glm::vec4(5.0, 3.0, -2.0, 1.0);
    _lightSource.diffuseColor = glm::vec4(0.5);
    _lightSource.specularColor = glm::vec4(1.0);
    _lightSource.ambientColor = glm::vec4(1.5);
    _lightSource.attentuation = 1.2;
    
    double lastTime = glfwGetTime();
    while (!glfwWindowShouldClose(_window)) {
        double currentTime = glfwGetTime();
        updatePositions(currentTime - lastTime);
        lastTime = currentTime;
        
        renderFrame(_scene);
        glfwSwapBuffers(_window);
        
        GLenum error = glGetError();
        if (error != GL_NO_ERROR)
            std::cerr << "OpenGL error " << error << ": " << (const char *) gluErrorString(error) << std::endl;
        
        glfwPollEvents();
    }
    
    glfwDestroyWindow(_window);
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