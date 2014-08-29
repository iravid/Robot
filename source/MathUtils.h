//
//  MathUtils.h
//  Robot
//
//  Created by Itamar Ravid on 29/8/14.
//
//

#ifndef Robot_MathUtils_h
#define Robot_MathUtils_h

#include <math.h>

float clampToMaxVertical(float angle, float addition, float max) {
    if (angle + addition > max)
        return max;
    else if (angle + addition < -max)
        return -max;
    
    return angle + addition;
}

static inline float degreesToRadians(float degrees) {
    return degrees * (float) M_PI / 180.0f;
}

#endif
