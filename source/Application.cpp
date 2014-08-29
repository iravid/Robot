//
//  Application.cpp
//  Robot
//
//  Created by Itamar Ravid on 29/8/14.
//
//

#include <iostream>

#include <glm/gtc/matrix_transform.hpp>

#include "Application.h"
#include "MathUtils.h"
#include "Loaders.h"

Application& Application::getInstance() {
    static Application instance;
    
    return instance;
}

Application::Application() {
    initGlfw(1024, 768);
    initOpenGL();
    createScene();
    initCamera(glm::vec3(0, 2, 0), glm::vec3(0, 2, -1), 0.2f, 100.0f, 45.0f);
    initLightSource(glm::vec3(5.0f, 3.0f, -2.0f), glm::vec4(0.5), glm::vec4(1.0f), glm::vec4(1.5), 1.2f);
    
    _robotMovementSpeed = 1.5f;
    _mouseSensitivity = 0.1f;
}

void Application::startAppLoop() {
    double lastTime = glfwGetTime();
    while (!glfwWindowShouldClose(_window)) {
        double currentTime = glfwGetTime();
        updatePositions(currentTime - lastTime);
        lastTime = currentTime;
        
        renderScene();
        glfwSwapBuffers(_window);
        
        GLenum error = glGetError();
        if (error != GL_NO_ERROR)
            std::cerr << "OpenGL error " << error << ": " << (const char *) gluErrorString(error) << std::endl;
        
        glfwPollEvents();
    }
    
    glfwDestroyWindow(_window);
    glfwTerminate();
}

std::map<std::string, Model *> Application::loadRoomModels() {
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

std::map<std::string, Model *> Application::loadRobotModels() {
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

void Application::createScene() {
    // Load the room models
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
    
    // Load the robot models
    std::map<std::string, Model *> robotModels = loadRobotModels();
    RenderNode *headNode = new RenderNode(new ModelInstance(robotModels["Head"]));
    RenderNode *torsoNode = new RenderNode(new ModelInstance(robotModels["Torso"]));
    RenderNode *rightArmNode = new RenderNode(new ModelInstance(robotModels["R_Arm"]));
    RenderNode *rightWristNode = new RenderNode(new ModelInstance(robotModels["R_Wrist"]));
    RenderNode *leftArmNode = new RenderNode(new ModelInstance(robotModels["L_Arm"]));
    RenderNode *leftWristNode = new RenderNode(new ModelInstance(robotModels["L_Wrist"]));
    RenderNode *rightLegNode = new RenderNode(new ModelInstance(robotModels["R_Leg"]));
    RenderNode *leftLegNode = new RenderNode(new ModelInstance(robotModels["L_Leg"]));
    
    // Set the model transform of each part of the robot to the translations we wrote down in Blender
    headNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0050, 1.6611, -0.0563));
    leftArmNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0672, 0.2466, -1.4236));
    leftWristNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0092, -1.2856, -0.0097));
    rightArmNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0580, 0.2572, 1.4286));
    rightWristNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(-0.0092, -1.2856, -0.0097));
    rightLegNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0881, -1.8537, 0.5387));
    leftLegNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0881, -1.8541, -0.5452));
    torsoNode->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(0.0, 2.0, 0.0));
    
    // Attach the Robot parts
    rightArmNode->children["Right_Wrist"] = rightWristNode;
    leftArmNode->children["Left_Wrist"] = leftWristNode;
    torsoNode->children["Left_Leg"] = leftLegNode;
    torsoNode->children["Right_Leg"] = rightLegNode;
    torsoNode->children["Left_Arm"] = leftArmNode;
    torsoNode->children["Right_Arm"] = rightArmNode;
    torsoNode->children["Head"] = headNode;
    
    // Insert the Robot into the scene
    _scene["Torso"] = torsoNode;
}

void Application::renderScene() {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MatrixStack matrixStack;
    
    std::map<std::string, RenderNode *>::const_iterator it;
    for (it = _scene.begin(); it != _scene.end(); ++it)
        it->second->renderRecursive(matrixStack, _camera, _lightSource);
}

void Application::updatePositions(float timeDiff) {
    float headVerticalDiff = 0, headHorizontalDiff = 0, torsoHorizontalDiff = 0, leftArmVerticalDiff = 0, leftWristVerticalDiff = 0, rightArmVerticalDiff = 0, rightWristVerticalDiff = 0;
    float torsoTranslationDiff = 0;
    float maxVerticalAngle = _robotOrientations.maxVerticalAngle;
    
    // Camera movement with keyboard and mouse
    if (!_cameraInHead) {
        // Camera position
        if (glfwGetKey(_window, GLFW_KEY_W) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * _robotMovementSpeed * _camera.forward());
        if (glfwGetKey(_window, GLFW_KEY_S) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * _robotMovementSpeed * -_camera.forward());
        if (glfwGetKey(_window, GLFW_KEY_A) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * _robotMovementSpeed * -_camera.right());
        if (glfwGetKey(_window, GLFW_KEY_D) == GLFW_PRESS)
            _camera.offsetPosition(timeDiff * _robotMovementSpeed * _camera.right());
        
        
        // Camera orientation
        double mouseX, mouseY;
        
        glfwGetCursorPos(_window, &mouseX, &mouseY);
        _camera.offsetOrientation(_mouseSensitivity * mouseY, _mouseSensitivity * mouseX);
        glfwSetCursorPos(_window, 0, 0);
    }
    
    // Head movement with z-x-c-v
    if (glfwGetKey(_window, GLFW_KEY_Z) == GLFW_PRESS)
        headHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_X) == GLFW_PRESS)
        headHorizontalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_C) == GLFW_PRESS)
        headVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_V) == GLFW_PRESS)
        headVerticalDiff -= 45.0f * timeDiff;
    
    // Torso movement with i-j-k-l
    if (glfwGetKey(_window, GLFW_KEY_I) == GLFW_PRESS)
        torsoTranslationDiff += timeDiff * _robotMovementSpeed;
    if (glfwGetKey(_window, GLFW_KEY_K) == GLFW_PRESS)
        torsoTranslationDiff -= timeDiff * _robotMovementSpeed;
    if (glfwGetKey(_window, GLFW_KEY_J) == GLFW_PRESS)
        torsoHorizontalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_L) == GLFW_PRESS)
        torsoHorizontalDiff -= 45.0f * timeDiff;
    
    // Arms movement with 1-2-3-4
    if (glfwGetKey(_window, GLFW_KEY_1) == GLFW_PRESS)
        leftArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_2) == GLFW_PRESS)
        leftArmVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_3) == GLFW_PRESS)
        rightArmVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_4) == GLFW_PRESS)
        rightArmVerticalDiff -= 45.0f * timeDiff;
    
    // Wrists movement with 5-6-7-8
    if (glfwGetKey(_window, GLFW_KEY_5) == GLFW_PRESS)
        leftWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_6) == GLFW_PRESS)
        leftWristVerticalDiff -= 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_7) == GLFW_PRESS)
        rightWristVerticalDiff += 45.0f * timeDiff;
    if (glfwGetKey(_window, GLFW_KEY_8) == GLFW_PRESS)
        rightWristVerticalDiff -= 45.0f * timeDiff;
    
    // Update all orientations
    // Compute the torso and head horizontal orientation modulo 360
    _robotOrientations.torsoHorizontal += torsoHorizontalDiff;
    _robotOrientations.torsoHorizontal = fmodf(_robotOrientations.torsoHorizontal, 360.0f);
    if (_robotOrientations.torsoHorizontal < 0.0f)
        _robotOrientations.torsoHorizontal += 360.0f;
    
    _robotOrientations.headHorizontal += headHorizontalDiff;
    _robotOrientations.headHorizontal = fmodf(_robotOrientations.headHorizontal, 360.0f);
    if (_robotOrientations.headHorizontal < 0.0f)
        _robotOrientations.headHorizontal += 360.0f;
    
    // Limit the vertical orientations to [-60, 60] degrees
    _robotOrientations.headVertical = clampToMaxVertical(_robotOrientations.headVertical, headVerticalDiff, maxVerticalAngle);
    _robotOrientations.leftArmVertical = clampToMaxVertical(_robotOrientations.leftArmVertical, leftArmVerticalDiff, maxVerticalAngle);
    _robotOrientations.leftWristVertical = clampToMaxVertical(_robotOrientations.leftWristVertical, leftWristVerticalDiff, maxVerticalAngle);
    _robotOrientations.rightArmVertical = clampToMaxVertical(_robotOrientations.rightArmVertical, rightArmVerticalDiff, maxVerticalAngle);
    _robotOrientations.rightWristVertical = clampToMaxVertical(_robotOrientations.rightWristVertical, rightWristVerticalDiff, maxVerticalAngle);
    
    // Since we'd like the robot to move in a different orientation than the standard world orientation, we need to compute its x and z components
    float xTrans, zTrans;
    xTrans = torsoTranslationDiff * cosf(degreesToRadians(_robotOrientations.torsoHorizontal));
    zTrans = -torsoTranslationDiff * sinf(degreesToRadians(_robotOrientations.torsoHorizontal));
    
    // Update the torso model matrices
    _scene["Torso"]->instance->transform.translate = glm::translate(glm::mat4(), glm::vec3(xTrans, 0.0f, zTrans)) * _scene["Torso"]->instance->transform.translate;
    _scene["Torso"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.torsoHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    
    // Update the head model matrices
    _scene["Torso"]->children["Head"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.headHorizontal, glm::vec3(0.0f, 1.0f, 0.0f));
    _scene["Torso"]->children["Head"]->instance->transform.rotate *= glm::rotate(glm::mat4(), _robotOrientations.headVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    
    // If the camera is in robot POV, its position and orientation need to be updated as well
    if (_cameraInHead) {
        _camera.offsetPosition(glm::vec3(xTrans, 0.0, zTrans));
        _camera.offsetOrientation(headVerticalDiff, - (torsoHorizontalDiff + headHorizontalDiff));
    }
    
    // Update the arms and wrists matrices
    _scene["Torso"]->children["Left_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.leftArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Left_Arm"]->children["Left_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.leftWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Right_Arm"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.rightArmVertical, glm::vec3(0.0f, 0.0f, 1.0f));
    _scene["Torso"]->children["Right_Arm"]->children["Right_Wrist"]->instance->transform.rotate = glm::rotate(glm::mat4(), _robotOrientations.rightWristVertical, glm::vec3(0.0f, 0.0f, 1.0f));
}

// The callback functions just grab the default instance and call the respective Impl function
void Application::glfwErrorCallback(int error, const char *desc) {
    getInstance().glfwErrorCallbackImpl(error, desc);
}

void Application::glfwKeyCallback(GLFWwindow *window, int key, int scancode, int action, int mods) {
    getInstance().glfwKeyCallbackImpl(window, key, scancode, action, mods);
}

void Application::glfwFramebufferResizeCallback(GLFWwindow *window, int width, int height) {
    getInstance().glfwFramebufferResizeCallbackImpl(window, width, height);
}

// Callback implementations
void Application::glfwErrorCallbackImpl(int error, const char *desc) {
    std::cerr << "GLFW error description:" << std::endl << desc << std::endl;
}

void Application::glfwFramebufferResizeCallbackImpl(GLFWwindow *window, int width, int height) {
    _camera.setViewportAspectRatio((float) width / (float) height);
}

void Application::glfwKeyCallbackImpl(GLFWwindow *window, int key, int scancode, int action, int mods) {
    // Robot POV handling
    if (key == GLFW_KEY_0 && action == GLFW_PRESS) {
        _cameraInHead = !_cameraInHead;
        
        if (_cameraInHead) {
            // Compute the head's model transformation
            glm::mat4 transform = _scene["Torso"]->instance->transform.matrix() * _scene["Torso"]->children["Head"]->instance->transform.matrix();
            
            // Reset camera
            _camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            _camera.lookAt(glm::vec3(0, 2, -1));
            
            // Apply the head's model transformation to the camera position
            _camera.setPosition(glm::vec3(transform * glm::vec4(0.0, 0.0, 0.0, 1.0)));
            
            // Offset the orientation to match the head's current orientation
            _camera.offsetOrientation(_robotOrientations.headVertical, - (_robotOrientations.headHorizontal + _robotOrientations.torsoHorizontal - 90.0f));
        } else {
            // Reset camera position
            _camera.setPosition(glm::vec3(0.0, 2.0, 0.0));
            _camera.lookAt(glm::vec3(0, 2, -1));
        }
    }
    
    // Stop application
    if (glfwGetKey(_window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(_window, GL_TRUE);
    
    // Increase/decrease ambient light
    if (glfwGetKey(_window, GLFW_KEY_RIGHT_BRACKET) == GLFW_PRESS)
        _lightSource.ambientColor += 0.1;
    if (glfwGetKey(_window, GLFW_KEY_LEFT_BRACKET) == GLFW_PRESS)
        _lightSource.ambientColor -= 0.1;
}

void Application::initGlfw(int width, int height) {
    glfwSetErrorCallback(&Application::glfwErrorCallback);
    
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
    _window = glfwCreateWindow(width, height, "Robot", nullptr, nullptr);
    if (!_window) {
        glfwTerminate();
        throw std::runtime_error("Error creating GLFW window");
    }
    
    _width = width;
    _height = height;
    
    glfwSetInputMode(_window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glfwSetCursorPos(_window, 0, 0);
    glfwSetFramebufferSizeCallback(_window, &Application::glfwFramebufferResizeCallback);
    glfwSetKeyCallback(_window, &Application::glfwKeyCallback);
    glfwMakeContextCurrent(_window);
}

void Application::initOpenGL() {
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
}

void Application::initCamera(glm::vec3 position, glm::vec3 lookAt, float nearPlane, float farPlane, float fov) {
    // Orient camera
    _camera.setPosition(position);
    _camera.lookAt(lookAt);
    _camera.setViewportAspectRatio(_width / _height);
    _camera.setNearAndFarPlanes(nearPlane, farPlane);
    _camera.setFieldOfView(fov);
}

void Application::initLightSource(glm::vec3 position, glm::vec4 diffuseColor, glm::vec4 specularColor, glm::vec4 ambientColor, float attenuation) {
    _lightSource.position = glm::vec4(position, 1.0f);
    _lightSource.diffuseColor = diffuseColor;
    _lightSource.specularColor = specularColor;
    _lightSource.ambientColor = ambientColor;
    _lightSource.attenuation = attenuation;
}