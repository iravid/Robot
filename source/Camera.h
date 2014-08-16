//
//  Camera.h
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#ifndef __Robot__Camera__
#define __Robot__Camera__

#include <glm/glm.hpp>

// A helper class for defining a camera in the 3D space.
class Camera {
public:
    Camera();
    
    // Get/set/manipulate camera position
    const glm::vec3& position() const;
    void setPosition(const glm::vec3& newPosition);
    void offsetPosition(const glm::vec3& offset);
    
    // Vertical viewing angle. Uses degrees. Must be between 0 and 180.
    float fieldOfView() const;
    void setFieldOfView(float fieldOfView);
    
    // Near clipping plane. Must be > 0.
    float nearPlane() const;
    // Far clipping plane.
    float farPlane() const;
    
    // Set the near/far planes. Constraints: far > near > 0
    void setNearAndFarPlanes(float nearPlane, float farPlane);
    
    // Returns a rotation matrix corresponding to the direction the camera is looking at. Does not include translation coefficients.
    glm::mat4 orientation() const;
    
    // Offset the camera orientation. The verticle angle is constrained between -85 and 85.
    void offsetOrientation(float upAngle, float rightAngle);
    
    // Points the camera at the given position.
    void lookAt(glm::vec3 position);
    
    // The ratio between the viewport's width and height.
    float viewportAspectRatio() const;
    void setViewportAspectRatio(float ratio);
    
    // Returns a unit vector representing the camera's face direction.
    glm::vec3 forward() const;
    
    // ... up direction
    glm::vec3 up() const;
    
    // ... right direction
    glm::vec3 right() const;
    
    // Returns the combined camera transformation matrix. Includes the projection matrix. This is used in the vertex shader.
    glm::mat4 matrix() const;
    
    // Returns the projection matrix.
    glm::mat4 projection() const;
    
    // Returns the rotation and translation matrix.
    glm::mat4 view() const;
    
private:
    glm::vec3 _position;
    float _horizontalAngle;
    float _verticalAngle;
    float _fieldOfView;
    float _nearPlane;
    float _farPlane;
    float _viewportAspectRatio;
    
    void normalizeAngles();
};

#endif /* defined(__Robot__Camera__) */
