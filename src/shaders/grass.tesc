#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(vertices = 1) out;

// VS → TCS varyings
layout(location = 0) in  vec4 inV0[];
layout(location = 1) in  vec4 inV1[];
layout(location = 2) in  vec4 inV2[];
layout(location = 3) in  vec4 inUp[];
layout(location = 0) out vec4 outV0[];
layout(location = 1) out vec4 outV1[];
layout(location = 2) out vec4 outV2[];
layout(location = 3) out vec4 outUp[];

void main() {
	// Don't move the origin location of the patch
    outV0[gl_InvocationID] = inV0[0];
    outV1[gl_InvocationID] = inV1[0];
    outV2[gl_InvocationID] = inV2[0];
    outUp[gl_InvocationID] = inUp[0];

    // Fixed tess levels for first visualization (can LOD later)
    // Quads domain: inner = {rows, cols}. Use moderate detail.
    gl_TessLevelInner[0] = 4.0; // along v
    gl_TessLevelInner[1] = 8.0; // along u
    gl_TessLevelOuter[0] = 8.0;
    gl_TessLevelOuter[1] = 4.0;
    gl_TessLevelOuter[2] = 8.0;
    gl_TessLevelOuter[3] = 4.0;
}
