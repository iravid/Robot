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

class RenderNode {
public:
    RenderNode() : instance(nullptr), children() {}
    RenderNode(ModelInstance *instance) : instance(instance), children() {}
    
    ModelInstance *instance;
    std::map<std::string, RenderNode *> children;
};

#endif
