# generate protobuf sources
file(GLOB proto_files proto/*.proto)
caffe_protobuf_generate_cpp_py(${proto_gen_folder} proto_srcs proto_hdrs proto_python ${proto_files})

# include python files either to force generation
add_library(proto STATIC ${proto_hdrs} ${proto_srcs} ${proto_python})
set(Caffe_LINKER_LIBS proto ${Caffe_LINKER_LIBS}) # note, crucial to prepend!
caffe_default_properties(proto)

# --[ Caffe library

# creates 'test_srcs', 'srcs', 'test_cuda', 'cuda' lists
caffe_pickup_caffe_sources(${PROJECT_SOURCE_DIR})

if(HAVE_CUDA)
  caffe_cuda_compile(cuda_objs ${cuda})
  if(NOT MSVC)
    list(APPEND srcs ${cuda_objs} ${cuda})
  else()
    add_library(caffecuda ${cuda_objs} ${cuda})
    caffe_default_properties(caffecuda)
    set_target_properties(caffecuda PROPERTIES LINKER_LANGUAGE CXX)
  endif()
endif()

#if(MSVC)
#    message(STATUS "Generating header to force template instantiation")
#    execute_process(COMMAND powershell.exe -ExecutionPolicy Bypass -File ${CMAKE_SOURCE_DIR}/scripts/caffe_gen_template_class_list.ps1
#                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
#                    RESULT_VARIABLE CAFFE_CLASS_LIST_RES
#                    OUTPUT_VARIABLE CAFFE_CLASS_LIST
#                    ERROR_VARIABLE CAFFE_CLASS_LIST_ERR
#                    )
#    if(${CAFFE_CLASS_LIST_RES} EQUAL 0)            
#        foreach(_class ${CAFFE_CLASS_LIST})
#            string(REPLACE "\n" "" _class ${_class})
#            set(CAFFE_FORCE_TEMPLATE_INSTANTIATION_HEADER_CONTENT "${CAFFE_FORCE_TEMPLATE_INSTANTIATION_HEADER_CONTENT}FORCE_TEMPLATE_INSTANTIATION(${_class});\n")
#        endforeach()
#        configure_file(${PROJECT_SOURCE_DIR}/cmake/Templates/caffe_force_tempate_instantiation.h.in "${PROJECT_BINARY_DIR}/caffe_force_tempate_instantiation.h" @ONLY)
#    else()
#        message( FATAL_ERROR "Failed to create statically registered template class list. Error: ${CAFFE_CLASS_LIST_ERR}")
#    endif()
#
#endif()

if(BUILD_caffe_object_library)
    add_library(caffe OBJECT ${srcs})
else()
    add_library(caffe ${srcs})
    target_link_libraries(caffe proto ${Caffe_LINKER_LIBS})
endif()
caffe_default_properties(caffe)

# ---[ Tests
 add_subdirectory(test)

# ---[ Install
install(DIRECTORY ${Caffe_INCLUDE_DIR}/caffe DESTINATION include)
install(FILES ${proto_hdrs} DESTINATION include/caffe/proto)
if(BUILD_caffe_object_library)
    install(TARGETS proto EXPORT CaffeTargets DESTINATION lib)
else()
    install(TARGETS caffe proto EXPORT CaffeTargets DESTINATION lib)
endif()



file(WRITE ${PROJECT_BINARY_DIR}/__init__.py)
list(APPEND proto_python ${PROJECT_BINARY_DIR}/__init__.py)
install(PROGRAMS ${proto_python} DESTINATION python/caffe/proto)


