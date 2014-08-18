//
//  RenderNode.h
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#ifndef Robot_RenderNode_h
#define Robot_RenderNode_h

#include "Model.h"

struct RenderNode {
    ModelInstance *instance;
    std::list<RenderNode> children;
};

#endif
