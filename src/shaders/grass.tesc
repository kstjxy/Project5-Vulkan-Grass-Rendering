//
#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(vertices = 1) out;

layout(set = 0, binding = 0) uniform CameraBufferObject {
    mat4 view;
    mat4 proj;
} camera;

layout(set = 2, binding = 0) uniform Time {
    float deltaTime;
    float totalTime;
    int enableOrientationCull;
    int enableFrustumCull;
    int enableDistanceCull;
    int enableLOD;
    float orientationThreshold;
    float frustumTolerance;
    float maxDistance;
    int bucketCount;
    int bladeCount;
    float lodNear;
    float lodFar;
    float minTessU;
    float maxTessU;
    float minTessV;
    float maxTessV;
} timeUBO;

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

    // Base tess levels (fallback)
    float baseU = 8.0; // along u (height)
    float baseV = 4.0; // along v (width)

    float uLevel = baseU;
    float vLevel = baseV;

    if (timeUBO.enableLOD != 0) {
        // Distance from camera in view space (camera at origin)
        vec3 V0 = inV0[0].xyz;
        vec3 posView = (camera.view * vec4(V0, 1.0)).xyz;
        float d = length(posView);

        float nearD = max(0.0, timeUBO.lodNear);
        float farD  = max(nearD + 0.001, timeUBO.lodFar);
        float t = clamp((d - nearD) / (farD - nearD), 0.0, 1.0);

        float minU = max(1.0, timeUBO.minTessU);
        float maxU = max(minU, timeUBO.maxTessU);
        float minV = max(1.0, timeUBO.minTessV);
        float maxV = max(minV, timeUBO.maxTessV);

        uLevel = mix(maxU, minU, t);
        vLevel = mix(maxV, minV, t);
    }

    // Quads domain: inner = {rows(v), cols(u)}. Mirror to outers.
    gl_TessLevelInner[0] = vLevel; // along v
    gl_TessLevelInner[1] = uLevel; // along u
    gl_TessLevelOuter[0] = uLevel;
    gl_TessLevelOuter[1] = vLevel;
    gl_TessLevelOuter[2] = uLevel;
    gl_TessLevelOuter[3] = vLevel;
}

