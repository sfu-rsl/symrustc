add_library(SymRuntime SHARED
  ${CMAKE_CURRENT_SOURCE_DIR}/../Config.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/../LibcWrappers.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/../Shadow.cpp
  Runtime.cpp)

target_link_libraries(SymRuntime)

target_include_directories(SymRuntime PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/..)

set_target_properties(SymRuntime PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")