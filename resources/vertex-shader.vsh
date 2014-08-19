#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

in vec3 vert;
in vec2 vertTextureCoord;
in vec3 vertNormal;

out vec2 fragTextureCoord;

void main() {
    fragTextureCoord = vertTextureCoord;
    vec3 bla = vertNormal;
    
    // Apply the camera and model transformations to vert
    gl_Position = projection * view * model * vec4(vert, 1);
}
