#pragma once

#include <glm/glm.hpp>
#include <chrono>

#include "Model.h"
#include "Blades.h"

using namespace std::chrono;

struct Time {
    float deltaTime = 0.0f;
    float totalTime = 0.0f;
    int   enableOrientationCull = 1;
    int   enableFrustumCull = 1;
    int   enableDistanceCull = 0;
    int   enableLOD = 1;
    float orientationThreshold = 0.9f;
    float frustumTolerance = 0.1f;
    float maxDistance = 50.0f;
    int   bucketCount = 8;
    int   bladeCount = NUM_BLADES;
    // LOD parameters
    float lodNear = 5.0f;
    float lodFar  = 50.0f;
    float minTessU = 2.0f;
    float maxTessU = 8.0f;
    float minTessV = 2.0f;
    float maxTessV = 4.0f;
};

class Scene {
private:
    Device* device;
    
    VkBuffer timeBuffer;
    VkDeviceMemory timeBufferMemory;
    Time time;
    
    void* mappedData;

    std::vector<Model*> models;
    std::vector<Blades*> blades;

high_resolution_clock::time_point startTime = high_resolution_clock::now();

public:
    Scene() = delete;
    Scene(Device* device);
    ~Scene();

    const std::vector<Model*>& GetModels() const;
    const std::vector<Blades*>& GetBlades() const;
    
    void AddModel(Model* model);
    void AddBlades(Blades* blades);

    VkBuffer GetTimeBuffer() const;

    void UpdateTime();

    // Culling toggles
    void SetOrientationCull(bool enabled);
    void SetFrustumCull(bool enabled);
    void SetDistanceCull(bool enabled);
    void SetLOD(bool enabled);
    void ToggleOrientationCull();
    void ToggleFrustumCull();
    void ToggleDistanceCull();
    void ToggleLOD();
    bool IsOrientationCull() const { return time.enableOrientationCull != 0; }
    bool IsFrustumCull() const { return time.enableFrustumCull != 0; }
    bool IsDistanceCull() const { return time.enableDistanceCull != 0; }
    bool IsLOD() const { return time.enableLOD != 0; }
};
