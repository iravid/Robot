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
    glm::vec3 position;
    // Light color
    glm::vec3 intensities;
    // Attentuation coefficient
    float attentuation;
    // Ambience coefficient
    float ambientCoefficient;
    
    Light() : position(0, 0, 0), intensities(1.0f, 1.0f, 1.0f), attentuation(0.02f), ambientCoefficient(0.005f) {}
};

#endif
