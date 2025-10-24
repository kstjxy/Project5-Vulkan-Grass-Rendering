file(GLOB SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

file(GLOB IMAGES
    ${CMAKE_CURRENT_SOURCE_DIR}/images/*.jpg
    ${CMAKE_CURRENT_SOURCE_DIR}/images/*.png
    ${CMAKE_CURRENT_SOURCE_DIR}/images/*.bmp
)

foreach(IMAGE ${IMAGES})
    get_filename_component(fname ${IMAGE} NAME)
    configure_file(${IMAGE} ${CMAKE_CURRENT_BINARY_DIR}/images/${fname} COPYONLY)
endforeach()

file(GLOB_RECURSE SHADER_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/*.vert
    ${CMAKE_CURRENT_SOURCE_DIR}/*.frag
    ${CMAKE_CURRENT_SOURCE_DIR}/*.geom
    ${CMAKE_CURRENT_SOURCE_DIR}/*.comp
    ${CMAKE_CURRENT_SOURCE_DIR}/*.tese
    ${CMAKE_CURRENT_SOURCE_DIR}/*.tesc
)

source_group("Shaders" FILES ${SHADER_SOURCES})

if(WIN32)
    add_executable(vulkan_grass_rendering WIN32 ${SOURCES} ${SHADER_SOURCES})
    target_link_libraries(vulkan_grass_rendering ${WINLIBS})
else(WIN32)
    add_executable(vulkan_grass_rendering ${SOURCES})
    target_link_libraries(vulkan_grass_rendering ${CMAKE_THREAD_LIBS_INIT})
endif(WIN32)

foreach(SHADER_SOURCE ${SHADER_SOURCES})
    set(SHADER_DIR ${CMAKE_CURRENT_BINARY_DIR}/shaders)

    if(WIN32)
        # Resolve glslangValidator path robustly
        if(NOT DEFINED GLSLANG_VALIDATOR)
          set(GLSLANG_VALIDATOR "$ENV{VULKAN_SDK}/Bin/glslangValidator.exe")
          if(NOT EXISTS "${GLSLANG_VALIDATOR}")
            set(GLSLANG_VALIDATOR "$ENV{VK_SDK_PATH}/Bin/glslangValidator.exe")
          endif()
          if(NOT EXISTS "${GLSLANG_VALIDATOR}")
            file(GLOB _VKSDK_HINT "C:/VulkanSDK/*/Bin/glslangValidator.exe")
            list(SORT _VKSDK_HINT)
            list(REVERSE _VKSDK_HINT)
            list(LENGTH _VKSDK_HINT _VKSDK_HINT_LEN)
            if(_VKSDK_HINT_LEN GREATER 0)
              list(GET _VKSDK_HINT 0 GLSLANG_VALIDATOR)
            endif()
          endif()
        endif()
        get_filename_component(fname ${SHADER_SOURCE} NAME)
        add_custom_target(${fname}.spv
            COMMAND ${CMAKE_COMMAND} -E make_directory ${SHADER_DIR} && 
            "${GLSLANG_VALIDATOR}" -V ${SHADER_SOURCE} -o ${SHADER_DIR}/${fname}.spv -g
            SOURCES ${SHADER_SOURCE}
        )
        ExternalTarget("Shaders" ${fname}.spv)
        add_dependencies(vulkan_grass_rendering ${fname}.spv)
    endif(WIN32)

    # TODO: Build shaders on not windows
endforeach()

target_link_libraries(vulkan_grass_rendering ${ASSIMP_LIBRARIES} Vulkan::Vulkan glfw)
target_include_directories(vulkan_grass_rendering PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${GLM_INCLUDE_DIR}
  ${STB_INCLUDE_DIR}
)

InternalTarget("" vulkan_grass_rendering)

# Help Visual Studio run with the correct working directory when debugging
if (MSVC)
  set_property(TARGET vulkan_grass_rendering PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:vulkan_grass_rendering>")
endif()

# Ensure runtime has required resources (shaders and images) next to the executable
if (WIN32)
  add_custom_command(TARGET vulkan_grass_rendering POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:vulkan_grass_rendering>/shaders"
    COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:vulkan_grass_rendering>/images"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/shaders" "$<TARGET_FILE_DIR:vulkan_grass_rendering>/shaders"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/images" "$<TARGET_FILE_DIR:vulkan_grass_rendering>/images"
  )
endif()
