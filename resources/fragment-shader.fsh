#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
//uniform mat4 normalRotationMatrix;
//uniform vec3 cameraPosition;

// Material settings
uniform sampler2D materialTexture;
//uniform float materialShininess;
//uniform vec3 materialSpecularColor;

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
    // The texture color
    vec4 surfaceColor = texture(materialTexture, fragTextureCoord);
    
    // Directions, all in world space: surface normal, light position, surface position, surface to light
    vec3 normalInWorldSpace = normalize(transpose(inverse(mat3(model))) * fragNormal);
    vec3 lightPositionInWorldSpace = light.position;
    vec3 surfacePositionInWorldSpace = vec3(model * vec4(fragVert, 1));
    vec3 surfaceToLight = normalize(lightPositionInWorldSpace - surfacePositionInWorldSpace);

    // Angle of incidence of light hitting the surface
    float cosAngleIncidence = dot(normalInWorldSpace, lightPositionInWorldSpace);
    cosAngleIncidence = clamp(cosAngleIncidence, 0, 1);
    
    // Diffuse coefficient
    float diffuseCoefficient = dot(normalInWorldSpace, surfaceToLight);
    diffuseCoefficient = clamp(diffuseCoefficient, 0, 1);

    // Diffuse color
    vec3 diffuseLight = diffuseCoefficient * surfaceColor.rgb * light.intensities;
    
    // Ambient lighting
    vec3 ambientLight = light.ambientCoefficient * surfaceColor.rgb * light.intensities;
    
    vec3 finalLight = light.intensities * diffuseLight * cosAngleIncidence + ambientLight;
    
    // Final color
    //finalColor = vec4(finalLight, surfaceColor.a);
    finalColor = texture(materialTexture, fragTextureCoord);
}

/*
void main() {
    vec3 normal = normalize(mat3(view * model) * fragNormal);
    vec3 surfacePos = vec3(view * model * vec4(fragVert, 1));
    vec4 surfaceColor = texture(materialTexture, fragTextureCoord);
    vec3 surfaceToLight = normalize((view * light.position) - surfacePos);
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
}*/