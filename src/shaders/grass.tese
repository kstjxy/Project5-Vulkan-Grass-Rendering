#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(quads, equal_spacing, ccw) in;

layout(set = 0, binding = 0) uniform CameraBufferObject {
    mat4 view;
    mat4 proj;
} camera;

// TCS → TES varyings
layout(location = 0) in  vec4 inV0[];
layout(location = 1) in  vec4 inV1[];
layout(location = 2) in  vec4 inV2[];
layout(location = 3) in  vec4 inUp[];

out gl_PerVertex { vec4 gl_Position; };
layout(location = 0) out vec2 outUV;

void main() {
    // Parameterization across (v in [0,1]) and along height (u in [0,1])
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    vec3 V0 = inV0[0].xyz;
    vec3 V1 = inV1[0].xyz;
    vec3 V2 = inV2[0].xyz;
    float orient  = inV0[0].w; // radians
    float height  = inV1[0].w;
    float width   = inV2[0].w;
    vec3 up       = normalize(inUp[0].xyz);

    // Build an orthonormal basis on the plane perpendicular to up
    vec3 base = vec3(1.0, 0.0, 0.0);
    if (abs(dot(base, up)) > 0.99) base = vec3(0.0, 0.0, 1.0);
    vec3 n1 = normalize(base - dot(base, up) * up);
    vec3 n2 = normalize(cross(up, n1));

    // Facing direction from orientation angle around up
    vec3 forward = normalize(cos(orient) * n1 + sin(orient) * n2);
    vec3 side = normalize(cross(up, forward));

    // Quadratic Bezier along height
    vec3 A = mix(V0, V1, u);
    vec3 B = mix(V1, V2, u);
    vec3 P = mix(A, B, u);

    // Taper width to tip
    float w = width * (1.0 - u);
    vec3 pos = P + (v - 0.5) * w * side;

    gl_Position = camera.proj * camera.view * vec4(pos, 1.0);
    outUV = vec2(v, u);
}
