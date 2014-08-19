#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

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
    gl_Position = projection * view * model * vec4(vert, 1);
}
