#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(set = 1, binding = 1) uniform sampler2D texSampler;

layout(location = 0) in vec2 inUV;
layout(location = 0) out vec4 outColor;

void main() {
    // Sample provided texture; fallback tint
    vec4 tex = texture(texSampler, inUV);
    outColor = tex;
}
