#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Material settings
uniform sampler2D materialTexture;

in vec2 fragTextureCoord;

out vec4 finalColor;

void main() {
    // The texture color
    vec4 surfaceColor = texture(materialTexture, fragTextureCoord);
    finalColor = surfaceColor;
}