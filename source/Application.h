//
//  Application.h
//  Robot
//
//  Created by Itamar Ravid on 25/8/14.
//
//

#ifndef Robot_Application_h
#define Robot_Application_h

#include <string>
#include <map>

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "Model.h"
#include "RenderNode.h"

class Application {
public:
    // Singleton factory method
    static Application& getInstance();
    void startAppLoop();

private:
    GLFWwindow *_window;
    int _width, _height;
    
    std::map<std::string, RenderNode *> _scene;

    float _robotMovementSpeed, _mouseSensitivity;
    
    struct Orientations {
        float headHorizontal;
        float headVertical;
        
        float torsoHorizontal;
        
        float leftArmVertical;
        float leftWristVertical;
        
        float rightArmVertical;
        float rightWristVertical;
        
        float maxVerticalAngle;
        
        Orientations() : headHorizontal(0), headVertical(0), torsoHorizontal(0),
        leftArmVertical(0), leftWristVertical(0), rightArmVertical(0), rightWristVertical(0),
        maxVerticalAngle(60) {}
    } _robotOrientations;
    
    Camera _camera;
    Light _lightSource;
    
    bool _cameraInHead;
    
    // Static functions that are attached as GLFW callbacks - these call the respective *Impl functions
    static void glfwErrorCallback(int error, const char *desc);
    static void glfwKeyCallback(GLFWwindow *window, int key, int scancode, int action, int mods);
    static void glfwFramebufferResizeCallback(GLFWwindow *window, int width, int height);
    
    // Callback implementations
    void glfwErrorCallbackImpl(int error, const char *desc);
    void glfwKeyCallbackImpl(GLFWwindow *window, int key, int scancode, int action, int mods);
    void glfwFramebufferResizeCallbackImpl(GLFWwindow *window, int width, int height);
    
    // Initialization functions
    void initGlfw(int width, int height);
    void initOpenGL();
    void initCamera(glm::vec3 position, glm::vec3 lookAt, float nearPlane, float farPlane, float fov);
    void initLightSource(glm::vec3 position, glm::vec4 diffuseColor, glm::vec4 specularColor, glm::vec4 ambientColor, float attenuation);
    
    // Loading functions
    void createScene();
    std::map<std::string, Model *> loadRobotModels();
    std::map<std::string, Model *> loadRoomModels();
    
    // Rendering pipeline
    void updatePositions(float timeDiff);
    void renderScene();
    
    // Private constructor, copy constructor and = operator to prevent init and copy
    Application();
    Application(const Application& copy);
    void operator=(const Application& copy);
};

#endif
