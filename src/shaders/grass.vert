
#version 450
#extension GL_ARB_separate_shader_objects : enable

// One Blade per vertex/patch. Attributes match Blade::getAttributeDescriptions()
layout(location = 0) in vec4 inV0; // v0.xyz position, v0.w orientation (radians)
layout(location = 1) in vec4 inV1; // v1.xyz guide,   inV1.w height
layout(location = 2) in vec4 inV2; // v2.xyz guide,   inV2.w width
layout(location = 3) in vec4 inUp; // up.xyz,         inUp.w stiffness

// Pass all data to TCS as per-vertex (patch) outputs
layout(location = 0) out vec4 outV0;
layout(location = 1) out vec4 outV1;
layout(location = 2) out vec4 outV2;
layout(location = 3) out vec4 outUp;

void main() {
    outV0 = inV0;
    outV1 = inV1;
    outV2 = inV2;
    outUp = inUp;
}
