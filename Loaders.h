//
//  Loaders.h
//  Robot
//
//  Created by Itamar Ravid on 19/8/14.
//
//

#ifndef Robot_Loaders_h
#define Robot_Loaders_h

#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <map>
#include <fstream>
#include <sstream>

#include "Shader.h"
#include "ShaderProgram.h"
#include "Texture.h"
#include "Bitmap.h"
#include "Model.h"

#define MAX_PATH_LEN 1024

// returns the full path to the file `fileName` in the resources directory of the app bundle
static std::string ResourcePath(std::string fileName) {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
    
    char *path = new char[MAX_PATH_LEN];
    CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *) path, MAX_PATH_LEN);
    
    CFRelease(resourcesURL);
    
    std::string finalPath = std::string(path) + "/" + fileName;
    delete[] path;
    
    return finalPath;
}

static ShaderProgram *programWithShaders(const char *vertexShaderFilename, const char *fragmentShaderFilename) {
    std::vector<Shader> shaders;
    shaders.push_back(Shader::shaderFromFile(ResourcePath(vertexShaderFilename), GL_VERTEX_SHADER));
    shaders.push_back(Shader::shaderFromFile(ResourcePath(fragmentShaderFilename), GL_FRAGMENT_SHADER));
    return new ShaderProgram(shaders);
}

static Texture *textureFromFile(const char *textureFilename) {
    Bitmap bmp = Bitmap::bitmapFromFile(ResourcePath(textureFilename));
    bmp.flipVertically();
    return new Texture(bmp);
}

static std::map<std::string, ModelData> loadModelsFromObj(const char *objFilename) {
    std::string objResourcePath = ResourcePath(objFilename);
    
    std::ifstream objFile;
    objFile.open(objResourcePath.c_str(), std::ios::in | std::ios::binary);
    
    if (!objFile.is_open())
        throw std::runtime_error(std::string("Failed to open object file: ") + objResourcePath);
    
    /* Sequence of object file:
            o object_name
            v # # # (vertices)
            ...
            vt # # (UVs)
            ...
            vn # # # (normals)
            ...
            s off (dunno)
            f vert_index/uv_index/norm_index vert_index/uv_index/norm_index vert_index/uv_index/norm_index (indices are 1-based)
            ...
            <repeat>
            EOF
     */
    
    std::map<std::string, std::vector<GLuint>> objectIndexData;
    std::vector<glm::vec3> totalVertexData, totalNormalData;
    std::vector<glm::vec2> totalTextureData;
    
    std::string currentLine;
    std::string currentObject;
    while (std::getline(objFile, currentLine)) {
        std::istringstream iss(currentLine);
        
        std::string directive;
        iss >> directive;
        if (directive == "#")
            continue;
        else if (directive == "o") {
            iss.ignore(256, ' ');
            iss >> currentObject;
        } else if  (directive == "v") {
            glm::vec3 vertexData;
            iss >> vertexData.x >> vertexData.y >> vertexData.z;
            totalVertexData.push_back(vertexData);
        } else if (directive == "vt") {
            glm::vec2 textureData;
            iss >> textureData.x >> textureData.y;
            totalTextureData.push_back(textureData);
        } else if (directive == "vn") {
            glm::vec3 normalData;
            iss >> normalData.x >> normalData.y >> normalData.z;
            totalNormalData.push_back(normalData);
        } else if (directive == "s") {
            continue;
        } else if (directive == "f") {
            unsigned int indexData[9];
            char c;
            
            iss >> indexData[0] >> c >> indexData[1] >> c >> indexData[2] >> indexData[3] >> c >> indexData[4] >> c
            >> indexData[5] >> indexData[6] >> c >> indexData[7] >> c >> indexData[8];
            
            objectIndexData[currentObject].insert(objectIndexData[currentObject].end(), &indexData[0], &indexData[9]);
        } else {
            throw std::runtime_error(std::string("Invalid character encountered while parsing ") + objFilename);
        }
    }
    
    std::map<std::string, ModelData> objectData;
    for (std::map<std::string, std::vector<GLuint>>::const_iterator it = objectIndexData.begin(); it != objectIndexData.end(); ++it) {
        objectData[it->first] = ModelData();
        
        unsigned int counter = 0;
        for (int i = 0; i < it->second.size(); i += 3) {
            // Reminder - Blender's indexing is 1-based
            GLuint vertexIndex = it->second[i] - 1;
            GLuint textureIndex = it->second[i + 1] - 1;
            GLuint normalIndex = it->second[i + 2] - 1;
            
            glm::vec3 vertex = totalVertexData[vertexIndex];
            glm::vec2 texture = totalTextureData[textureIndex];
            glm::vec3 normal = totalNormalData[normalIndex];
            
            objectData[it->first].vertexData.push_back(vertex);
            objectData[it->first].textureData.push_back(texture);
            objectData[it->first].normalData.push_back(normal);
            objectData[it->first].indexData.push_back(counter);
            
            counter++;
        }
    }
    
    return objectData;
}

#endif
