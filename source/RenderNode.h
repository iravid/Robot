//
//  RenderNode.h
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#ifndef Robot_RenderNode_h
#define Robot_RenderNode_h

#include <map>
#include <string>

#include "Model.h"
#include "Camera.h"
#include "Light.h"
#include "MatrixStack.h"

class RenderNode {
public:
    RenderNode();
    RenderNode(ModelInstance *instance);
    
    void renderRecursive(MatrixStack& modelTransform, Camera& cameraPosition, Light& lightSource);
    
    ModelInstance *instance;
    std::map<std::string, RenderNode *> children;
};

#endif
