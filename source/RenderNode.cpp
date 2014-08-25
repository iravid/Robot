//
//  RenderNode.cpp
//  Robot
//
//  Created by Itamar Ravid on 25/8/14.
//
//

#include "RenderNode.h"
#include "MatrixStack.h"
#include "Camera.h"
#include "Light.h"

RenderNode::RenderNode() : instance(nullptr), children() {
}

RenderNode::RenderNode(ModelInstance *modelInstance) : instance(modelInstance), children() {
}

void RenderNode::renderRecursive(MatrixStack& modelTransformStack, Camera& cameraPosition, Light& lightSource) {
    modelTransformStack.push(instance->transform.matrix());
    
    // Render all children recursively
    std::map<std::string, RenderNode *>::const_iterator it;
    for (it = children.begin(); it != children.end(); ++it)
        it->second->renderRecursive(modelTransformStack, cameraPosition, lightSource);
    
    // Render this instance
    //renderInstance(*(node->instance), modelTransformStack.multiplyMatrices());
    instance->render(modelTransformStack.multiplyMatrices(), cameraPosition, lightSource);
    
    // Pop the matrices
    modelTransformStack.pop();
}
