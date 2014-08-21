#version 150

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform sampler2D materialTexture;

uniform struct Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} material;

uniform struct LightSource {
    vec4 position;
    vec4 diffuse;
    vec4 specular;
    vec4 ambient;
    float attenuation;
} light;

in vec4 fragPosition;
in vec2 fragTextureCoord;
in vec3 fragNormal;

out vec4 finalColor;

void main() {
    mat4 inverseView = inverse(view);
    
    vec3 surfaceNormal = normalize(fragNormal);
    vec3 viewDirection = normalize(vec3(inverseView * vec4(0.0, 0.0, 0.0, 1.0) - fragPosition));
    
    vec3 positionToLightSource = vec3(light.position - fragPosition);
    float distance = length(positionToLightSource);
    vec3 lightDirection = normalize(positionToLightSource);
    
    float attenuation = 1.0 / (1.0 + light.attenuation * distance);
    
    vec3 ambientLighting = vec3(light.ambient) * vec3(material.ambient);
    
    vec3 diffuseReflection = attenuation * vec3(light.diffuse) * vec3(material.diffuse) * max(0.0, dot(surfaceNormal, lightDirection));
    
    vec3 specularReflection;
    if (dot(surfaceNormal, lightDirection) > 0.0)
        specularReflection = attenuation * vec3(light.specular) * vec3(material.specular) *
            pow(max(0.0, dot(reflect(-lightDirection, surfaceNormal), viewDirection)), material.shininess);
    else
        specularReflection = vec3(0.0);
    
    // The texture color
    vec4 textureColor = texture(materialTexture, fragTextureCoord);
    
    finalColor = textureColor * vec4(ambientLighting + diffuseReflection + specularReflection, 1.0);
}