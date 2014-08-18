//
//  MatrixStack.cpp
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#include "MatrixStack.h"

void MatrixStack::push(const glm::mat4& element) {
    _stack.push_front(element);
}

void MatrixStack::pop() {
    _stack.pop_front();
}

const glm::mat4& MatrixStack::top() const {
    return _stack.front();
}

glm::mat4 MatrixStack::multiplyMatrices() const {
    glm::mat4 outputMatrix;
    
    for (std::list<glm::mat4>::const_iterator it = _stack.begin(); it != _stack.end(); ++it)
        outputMatrix = *it * outputMatrix;
    
    return outputMatrix;
}


