//
//  MatrixStack.h
//  Robot
//
//  Created by Itamar Ravid on 18/8/14.
//
//

#ifndef __Robot__MatrixStack__
#define __Robot__MatrixStack__

#include <list>
#include <glm/glm.hpp>

class MatrixStack {
public:
    void push(const glm::mat4& element);
    void pop();
    const glm::mat4& top() const;
    
    glm::mat4 multiplyMatrices() const;
    
    MatrixStack();

private:
    std::list<glm::mat4> _stack;
};

#endif /* defined(__Robot__MatrixStack__) */
