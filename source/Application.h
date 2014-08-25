//
//  Application.h
//  Robot
//
//  Created by Itamar Ravid on 25/8/14.
//
//

#ifndef Robot_Application_h
#define Robot_Application_h

#include <GLFW/glfw3.h>

class Application {
public:
    void startAppLoop();

private:
    GLFWwindow *_window;
    std::map<std::string, RenderNode *> _scene;
    Camera _camera;
    Light _lightSource;
    
    bool _cameraInHead;
    
    // GLFW callbacks
    void glfwErrorCallbackFunc(int error, const char *desc);
    void glfwKeyCallbackFunc(GLFWwindow *window, int key, int scancode, int action, int mods);
    void glfwFramebufferResizeCallbackFunc(GLFWwindow *window, int width, int height);
    
    void initGlfw();
    void initCamera();
    void initLightSource();
    
    void updatePositions();
    void renderFrame();
}

#endif