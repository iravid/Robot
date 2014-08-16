//
//  main.mm
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#import <Foundation/Foundation.h>
#include <iostream>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>

#include "ShaderProgram.h"
#include "Shader.h"
#include "Texture.h"

const glm::vec2 SCREEN_SIZE(1024, 768);

struct Model {
    ShaderProgram *shaders;
    Texture *texture;
    
    GLuint vbo;
    GLuint vao;
    
    // Vertex parameters
    GLenum drawType;
    GLint drawStart;
    GLint drawCount;
    
    // Lighting parameters
    GLfloat shininess;
    glm::vec3 specularColor;
    
    // Constructor
    Model() :
        shaders(nullptr), texture(nullptr),
        vbo(0), vao(0),
        drawType(GL_TRIANGLES), drawStart(0), drawCount(0),
        shininess(0.0f), specularColor(1.0f, 1.0f, 1.0f) {}
};

struct ModelInstance {
    // The model itself
    Model *model;
    // The transformation to be applied to this instance
    glm::mat4 transform;
    
    ModelInstance() : model(nullptr), transform() {}
};

struct Light {
    // Light position
    glm::vec3 position;
    // Light color
    glm::vec3 intensities;
    // Attentuation coefficient
    float attentuation;
    // Ambience coefficient
    float ambientCoefficient;
};

// returns the full path to the file `fileName` in the resources directory of the app bundle
static std::string ResourcePath(std::string fileName) {
    NSString* fname = [NSString stringWithCString:fileName.c_str() encoding:NSUTF8StringEncoding];
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fname];
    return std::string([path cStringUsingEncoding:NSUTF8StringEncoding]);
}

static ShaderProgram *programWithShaders(const char *vertexShaderFilename, const char *fragmentShaderFilename) {
    std::vector<Shader> shaders;
    shaders.push_back(Shader::shaderFromFile(ResourcePath(vertexShaderFilename), GL_VERTEX_SHADER));
    shaders.push_back(Shader::shaderFromFile(ResourcePath(fragmentShaderFilename), GL_FRAGMENT_SHADER));
    return new ShaderProgram(shaders);
}

static Texture *textureFromFile(const char *textureFilename) {
    Bitmap bmp = Bitmap::bitmapFromFile(ResourcePath(textureFilename));
    bmp.flipVertically();
    return new Texture(bmp);
}

static void glfwErrorCallbackFunc(int error, const char *desc) {
    std::cerr << "GLFW error description:" << std::endl << desc << std::endl;
}

static void glfwKeyCallbackFunc(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}

void updatePositions() {
    
}

void renderFrame() {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
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
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
    
    // Create the window
    window = glfwCreateWindow(1024, 768, "Robot", nullptr, nullptr);
    if (!window) {
        glfwTerminate();
        throw std::runtime_error("Error creating GLFW window");
    }
        
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
    
    while (!glfwWindowShouldClose(window)) {
        updatePositions();
        renderFrame();
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