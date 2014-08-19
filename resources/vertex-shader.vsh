#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

in vec3 vert;
in vec2 vertTextureCoord;
in vec3 vertNormal;

out vec4 fragPosition; // Vertex position in world-space
out vec2 fragTextureCoord; // UV coordinate
out vec3 fragNormal; // Surface normal in world-space

void main() {
    mat3 normalModelMatrix = transpose(inverse(mat3(model)));
    
    fragPosition = model * vec4(vert, 1);
    fragTextureCoord = vertTextureCoord;
    fragNormal = normalize(normalModelMatrix * vertNormal);
    
    // Apply the camera and model transformations to vert
    gl_Position = projection * view * model * vec4(vert, 1);
}
