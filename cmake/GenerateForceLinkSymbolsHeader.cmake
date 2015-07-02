macro(add_generate_force_link_symbols_header_post_build_command target output_file symbol_pattern)
    if(MSVC)
        add_custom_command(TARGET ${target} POST_BUILD
                           COMMAND ${CMAKE_COMMAND} -DMSVC_VERSION=${MSVC_VERSION} -DSYMBOL_PATTERN=${symbol_pattern} -DOUTPUT_FILE=${output_file} -DTARGET=$<TARGET_FILE:${target}> -P ${CMAKE_SOURCE_DIR}/cmake/GenerateForceLinkSymbolsHeader.cmake
                           )
        set_source_files_properties(${output_file} PROPERTIES GENERATED TRUE)
    endif()
endmacro()

macro(find_dumpbin_executable)
    if(NOT MSVC_VC_DIR)
        # MSVC_VERSION = 
        # 1200 = VS  6.0
        # 1300 = VS  7.0
        # 1310 = VS  7.1
        # 1400 = VS  8.0
        # 1500 = VS  9.0
        # 1600 = VS 10.0
        # 1700 = VS 11.0
        # 1800 = VS 12.0
        set(MSVC_PRODUCT_VERSION_1200 6.0)
        set(MSVC_PRODUCT_VERSION_1300 7.0)
        set(MSVC_PRODUCT_VERSION_1310 7.1)
        set(MSVC_PRODUCT_VERSION_1400 8.0)
        set(MSVC_PRODUCT_VERSION_1500 9.0)
        set(MSVC_PRODUCT_VERSION_1600 10.0)
        set(MSVC_PRODUCT_VERSION_1700 11.0)
        set(MSVC_PRODUCT_VERSION_1800 12.0)
        get_filename_component(MSVC_VC_DIR [HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\${MSVC_PRODUCT_VERSION_${MSVC_VERSION}}\\Setup\\VC;ProductDir] REALPATH CACHE)
    endif()
    find_program(DUMPBIN_EXECUTABLE dumpbin ${MSVC_VC_DIR}/bin)
    if(NOT DUMPBIN_EXECUTABLE)
            message(FATAL_ERROR "Could not find DUMPBIN_EXECUTABLE please define this variable")
    endif()
endmacro()

if(CMAKE_SCRIPT_MODE_FILE)
    if(NOT DUMPBIN_EXECUTABLE)
        if(NOT MSVC_VERSION)
            message(FATAL_ERROR "Please define DUMPBIN_EXECUTABLE or MSVC_VERSION")
        else()
            # find DUMPBIN from MSVC_VERSION 
            find_dumpbin_executable()       
        endif()
    endif()

    if(NOT TARGET)
        message(FATAL_ERROR "Please define TARGET variable")
    endif()
    
    # default to forceLink symbol if not defined otherwise
    if(NOT SYMBOL_PATTERN)
        set(SYMBOL_PATTERN forceLink)
    endif()

    # execute DUMPBIN.exe to list all symbols in the library
    execute_process(COMMAND ${DUMPBIN_EXECUTABLE} /SYMBOLS ${TARGET}
                    RESULT_VARIABLE _RESULT_VARIABLE
                    OUTPUT_VARIABLE _OUTPUT_VARIABLE)
    
    # log an error if dumpbin.exe returned something other than 0
    if(NOT ${_RESULT_VARIABLE} EQUAL 0)
        message(FATAL_ERROR "Dumpbin execution failed")
    endif()
    
    # split the output string by line
    string(REPLACE  "\n" ";" _OUTPUT_LIST "${_OUTPUT_VARIABLE}")
    # find all matching symbols
    foreach(_line ${_OUTPUT_LIST})
        # match a string that looks like "|-<pattern to match>-(" 
        # where - literal is one or more spaces
        string(REGEX MATCH "\\| +(.*${SYMBOL_PATTERN}.*) +\\(" _match_var "${_line}")
        if(_match_var)
            # append symbol to list
            list(APPEND FORCE_LINK_SYMBOLS ${CMAKE_MATCH_1})                    
        endif()
    endforeach()   
    
    if(NOT OUTPUT_FILE)
        set(OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/force_link.h)
    endif()
    
    file(WRITE ${OUTPUT_FILE}
"// header automatically generated by cmake. DO NOT EDIT
#ifndef _FORCE_LINK_
#define _FORCE_LINK_

// force inclusion of statically registered
// functions and classes with a linker pragma\n"
    )
    
    foreach(_symbol ${FORCE_LINK_SYMBOLS})
        file(APPEND ${OUTPUT_FILE} "#pragma comment(linker, \"/include:${_symbol}\")\n")        
    endforeach()
                
    file(APPEND ${OUTPUT_FILE} "#endif  // _FORCE_LINK_\n")
    
    list(LENGTH FORCE_LINK_SYMBOLS NUMBER_OF_SYMBOLS)
    
    message("Found ${NUMBER_OF_SYMBOLS} symbols to force linking\nHeader written to ${OUTPUT_FILE}")
           
endif()