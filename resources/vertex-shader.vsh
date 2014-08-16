#version 150

uniform mat4 camera;
uniform mat4 model;

in vec3 vert;
in vec2 vertTextureCoord;
in vec3 vertNormal;

out vec3 fragVert;
out vec2 fragTextureCoord;
out vec3 fragNormal;

void main() {
    fragTextureCoord = vertTextureCoord;
    fragNormal = vertNormal;
    fragVert = vert;
    
    // Apply the camera and model transformations to vert
    gl_Position = camera * model * vec4(vert, 1);
}
