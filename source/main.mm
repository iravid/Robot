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

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "ShaderProgram.h"
#include "Shader.h"
#include "Texture.h"
#include "Camera.h"

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

struct ModelTransform {
    glm::mat4 scale;
    glm::mat4 rotate;
    glm::mat4 translate;
    
    ModelTransform() : scale(), rotate(), translate() {}
    glm::mat4 matrix() const { return translate * rotate * scale; }
};

struct ModelInstance {
    // The model itself
    Model *model;
    // The transformation to be applied to this instance
    ModelTransform transform;
    
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

const glm::vec2 SCREEN_SIZE(1680, 1050);
Light light;
Camera camera;

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
    glGenVertexArrays(1, &floor->vao);
    
    // Bind the vertex array
    glBindVertexArray(floor->vao);
    
    // Bind the buffer
    glBindBuffer(GL_ARRAY_BUFFER, floor->vbo);
    
    GLfloat floorVertexData[] = {
    //    X     Y     Z     U     V    Normal
    //  first triangle
        -1.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f,
        1.5f, 0.0f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f,
        1.5f, 0.0f, -1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f,
    //  second triangle
        1.5f, 0.0f, -1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f,
        -1.5f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f,
        -1.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f
    };
    
    // Copy vertex data to OpenGL buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorVertexData), floorVertexData, GL_STATIC_DRAW);
    
    // Point the vert in-parameter of the vertex shader to the first 3 elements of every 5 elements in the array
    glEnableVertexAttribArray(floor->shaders->attrib("vert"));
    glVertexAttribPointer(floor->shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), NULL);
    
    // Same thing, but point vertTextureCoord to last 2 elements of every 5 elements
    glEnableVertexAttribArray(floor->shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(floor->shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (const GLvoid *) (3 * sizeof(GLfloat)));
    
    glEnableVertexAttribArray(floor->shaders->attrib("vertNormal"));
    glVertexAttribPointer(floor->shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (const GLvoid *) (5 * sizeof(GLfloat)));
    
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
    wall->shininess = 100.0f;
    wall->specularColor = glm::vec3(1.0f, 1.0f, 1.0f);
    wall->texture = textureFromFile("brick_texture.jpg");
    
    glGenBuffers(1, &wall->vbo);
    glGenVertexArrays(1, &wall->vao);
    
    glBindVertexArray(wall->vao);
    
    glBindBuffer(GL_ARRAY_BUFFER, wall->vbo);
    
    // Wall quad: (-1.5, -1), (-1.5, 1), (1.5, 1), (1.5, -1)
    GLfloat wallVertexData[] = {
        // First triangle
    //    X      Y     Z     U     V     Xn    Yn    Zn
        -1.5f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f,
        -1.5f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.5f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        // Second triangle
        1.5f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.5f, -1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f,
        -1.5f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f
    };
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(wallVertexData), wallVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(wall->shaders->attrib("vert"));
    glVertexAttribPointer(wall->shaders->attrib("vert"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), NULL);
    
    glEnableVertexAttribArray(wall->shaders->attrib("vertTextureCoord"));
    glVertexAttribPointer(wall->shaders->attrib("vertTextureCoord"), 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (const GLvoid *) (3 * sizeof(GLfloat)));
    
    glEnableVertexAttribArray(wall->shaders->attrib("vertNormal"));
    glVertexAttribPointer(wall->shaders->attrib("vertNormal"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (const GLvoid *) (5 * sizeof(GLfloat)));
    
    glBindVertexArray(0);
    
    return wall;
}

static void createInstances(std::list<ModelInstance>& instanceList) {
    Model *floorModel = loadFloorModel();
    
    ModelInstance floorInstance;
    floorInstance.model = floorModel;
    floorInstance.transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 0, 4));
    instanceList.push_back(floorInstance);
    
    ModelInstance ceilingInstance;
    ceilingInstance.model = floorModel;
    // Transform order: TRS
    ceilingInstance.transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 0, 4));
    ceilingInstance.transform.rotate = glm::rotate(glm::mat4(), 180.0f, glm::vec3(1.0f, 0.0f, 0.0f));
    ceilingInstance.transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 8, 0));
    instanceList.push_back(ceilingInstance);
    
    Model *wallModel = loadWallModel();
    
    ModelInstance backWall;
    backWall.model = wallModel;
    backWall.transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 4, 0));
    backWall.transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 4, -4));
    instanceList.push_back(backWall);
    
    ModelInstance frontWall;
    frontWall.model = wallModel;
    frontWall.transform.scale = glm::scale(glm::mat4(), glm::vec3(4, 4, 0));
    frontWall.transform.rotate = glm::rotate(glm::mat4(), 180.0f, glm::vec3(0, 1.0f, 0));
    frontWall.transform.translate = glm::translate(glm::mat4(), glm::vec3(0, 4, 4));
    instanceList.push_back(frontWall);
    
    ModelInstance leftWall;
    leftWall.model = wallModel;
    // Rotation by negative amount of degrees is needed in order to preserve the direction of the surface normal
    leftWall.transform.scale = glm::scale(glm::mat4(), glm::vec3(4.0f / 1.5f, 4.0f, 0.0f));
    leftWall.transform.rotate = glm::rotate(glm::mat4(), 90.0f, glm::vec3(0, 1.0f, 0));
    leftWall.transform.translate = glm::translate(glm::mat4(), glm::vec3(-6, 4, 0));
    instanceList.push_back(leftWall);
    
    ModelInstance rightWall;
    rightWall.model = wallModel;
    rightWall.transform.scale = glm::scale(glm::mat4(), glm::vec3(4.0f / 1.5f, 4.0f, 0.0f));
    rightWall.transform.rotate = glm::rotate(glm::mat4(), -90.0f, glm::vec3(0, 1.0f, 0));
    rightWall.transform.translate = glm::translate(glm::mat4(), glm::vec3(6, 4, 0));
    instanceList.push_back(rightWall);
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
    
    if (key == GLFW_KEY_UP && action == GLFW_PRESS)
        camera.offsetOrientation(-5.0f, 0.0f);
    if (key == GLFW_KEY_DOWN && action == GLFW_PRESS)
        camera.offsetOrientation(5.0f, 0.0f);
    if (key == GLFW_KEY_RIGHT && action == GLFW_PRESS)
        camera.offsetOrientation(0.0f, 5.0f);
    if (key == GLFW_KEY_LEFT && action == GLFW_PRESS)
        camera.offsetOrientation(0.0f, -5.0f);
    
}

void updatePositions() {
    
}

// Render a single instance
void renderInstance(const ModelInstance& instance) {
    Model *model = instance.model;
    ShaderProgram *shaders = model->shaders;
    
    // Start using the shader program
    shaders->use();
    
    // Set the uniforms
    shaders->setUniform("camera", camera.matrix());
    shaders->setUniform("model", instance.transform.matrix());
    shaders->setUniform("normalRotationMatrix", instance.transform.rotate);
    shaders->setUniform("materialTexture", 0);
    shaders->setUniform("materialShininess", model->shininess);
    shaders->setUniform("materialSpecularColor", model->specularColor);
    shaders->setUniform("light.position", light.position);
    shaders->setUniform("light.intensities", light.intensities);
    shaders->setUniform("light.attentuation", light.attentuation);
    shaders->setUniform("light.ambientCoefficient", light.ambientCoefficient);
    shaders->setUniform("cameraPosition", camera.position());
    
    // Bind texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, model->texture->handle());
    
    // Bind VAO and draw
    glBindVertexArray(model->vao);
    glDrawArrays(model->drawType, model->drawStart, model->drawCount);
    
    // Unbind everything
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    shaders->stopUsing();
}

void renderFrame(const std::list<ModelInstance>& instances) {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    std::list<ModelInstance>::const_iterator it;
    for (it = instances.begin(); it != instances.end(); ++it)
        renderInstance(*it);
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
    window = glfwCreateWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, "Robot", nullptr, nullptr);
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
    
    std::list<ModelInstance> instances;
    createInstances(instances);
    
    // Orient camera
    camera.setPosition(glm::vec3(0, 2, 0));
    camera.setViewportAspectRatio(SCREEN_SIZE.x / SCREEN_SIZE.y);
    camera.setNearAndFarPlanes(0.2f, 100.0f);
    camera.setFieldOfView(120.0f);
    camera.lookAt(glm::vec3(0, 2, -4));
    
    // Setup light source parameters
    light.position = glm::vec3(0, 4, 0);
    light.intensities = glm::vec3(1.0f, 1.0f, 1.0f); // white
    light.attentuation = 0.002f;
    light.ambientCoefficient = 0.005f;
    
    while (!glfwWindowShouldClose(window)) {
        updatePositions();
        renderFrame(instances);
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