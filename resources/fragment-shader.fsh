#version 150

uniform mat4 model;
uniform mat4 normalRotationMatrix;
uniform vec3 cameraPosition;

// Material settings
uniform sampler2D materialTexture;
uniform float materialShininess;
uniform vec3 materialSpecularColor;

// Mirrors the C++ struct Light
uniform struct Light {
    vec3 position;
    vec3 intensities;
    float attentuation;
    float ambientCoefficient;
} light;

in vec2 fragTextureCoord;
in vec3 fragNormal;
in vec3 fragVert;

out vec4 finalColor;

void main() {
    vec3 normal = mat3(normalRotationMatrix) * fragNormal;
    vec3 surfacePos = vec3(model * vec4(fragVert, 1));
    vec4 surfaceColor = texture(materialTexture, fragTextureCoord);
    vec3 surfaceToLight = normalize(light.position - surfacePos);
    vec3 surfaceToCamera = normalize(cameraPosition - surfacePos);
    
    // Apply the ambient lighting
    vec3 ambientLight = light.ambientCoefficient * surfaceColor.rgb * light.intensities;
    
    // Apply the diffuse lighting
    float diffuseCoefficient = max(0.0, dot(normal, surfaceToLight));
    vec3 diffuseLight = diffuseCoefficient * surfaceColor.rgb * light.intensities;
    
    // Apply the specular lighting
    float specularCoefficient = 0.0;
    if (diffuseCoefficient > 0.0)
        specularCoefficient = pow(max(0.0, dot(surfaceToCamera, reflect(-surfaceToLight, normal))), materialShininess);
    vec3 specularLight = specularCoefficient * materialSpecularColor * light.intensities;
    
    // Apply distance attentuation
    float distanceToLight = length(light.position - surfacePos);
    float attentuation = 1.0 / (1.0 + light.attentuation * pow(distanceToLight, 2));
    
    // Compute linear color
    vec3 linearColor = ambientLight + attentuation * (diffuseLight + specularLight);
    
    // Apply gamma correction and output final color
    vec3 gamma = vec3(1.0 / 2.2);
    finalColor = vec4(pow(linearColor, gamma), surfaceColor.a);
}