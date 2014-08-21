//
//  Light.h
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#ifndef Robot_Light_h
#define Robot_Light_h

#include <glm/glm.hpp>

struct Light {
    // Light position
    glm::vec4 position;
    // Light color
    glm::vec4 diffuseColor;
    // Specular color
    glm::vec4 specularColor;
    // Ambience color
    glm::vec4 ambientColor;
    // Attentuation coefficient
    float attentuation;
    
    Light() : position(0, 0, 0, 1), diffuseColor(1.0f), specularColor(1.0f), ambientColor(1.0f), attentuation(0.02f) {}
};

#endif
