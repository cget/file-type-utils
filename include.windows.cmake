
function(SETUP_TOOLS)
	set(cmd_paths "")
	foreach(MSVC_VER "14.0" "12.0" "11.0" "10.0" "9.0" "8")
		STRING(REPLACE MSVC_VER "." "" MSVC_VER_NO_PERIODS "${MSVC_VER}")
		list(APPEND cmd_paths "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\${MSVC_VER};InstallDir]/../../VC/bin")
		list(APPEND cmd_paths "$ENV{VS${MSVC_VER_NO_PERIODS}COMNTOOLS}/../../VC/bin")
		list(APPEND cmd_paths "C:/Program Files/Microsoft Visual Studio ${MSVC_VER}/VC/bin")
		list(APPEND cmd_paths "C:/Program Files (x86)/Microsoft Visual Studio ${MSVC_VER}/VC/bin")
		list(APPEND cmd_paths "D:/Program Files/Microsoft Visual Studio ${MSVC_VER}/VC/bin")
		list(APPEND cmd_paths "D:/Program Files (x86)/Microsoft Visual Studio ${MSVC_VER}/VC/bin")
	endforeach()

	find_program(DUMPBIN "dumpbin" PATHS ${cmd_paths} NO_DEFAULT_PATH)
	find_program(LINK_CMD "link" PATHS ${cmd_paths} NO_DEFAULT_PATH)
	find_program(LIB_CMD "lib" PATHS ${cmd_paths} NO_DEFAULT_PATH)

	message(${cmd_paths})
	
	if(DUMPBIN-NOTFOUND)
		message(FATAL_ERROR "Could not find dumpbin exe")
	endif()
	if(LINK_CMD-NOTFOUND)
		message(FATAL_ERROR "Could not find link exe")
	endif()
endfunction(SETUP_TOOLS)

SETUP_TOOLS()

FUNCTION(CGET_GET_FILE_TYPE name var)
    get_filename_component(EXT "${name}" EXT)
    if(EXT MATCHES "dll")
        SET(${var} "SHARED_LIBRARY" PARENT_SCOPE)
    elseif(EXT MATCHES "exe")
        SET(${var} "EXECUTABLE" PARENT_SCOPE)
    elseif(EXT MATCHES "lib")
        execute_process(COMMAND "${LINK_CMD}" /dump /linkermember  "${name}" OUTPUT_VARIABLE OUTPUT)
        if(OUTPUT MATCHES "__imp_")
            SET(${var} "SHARED_LIBRARY" PARENT_SCOPE)
        else()
            SET(${var} "STATIC_LIBRARY" PARENT_SCOPE)
        endif()
    else()
        message(FATAL_ERROR "Unknown file type: ${name}")
    endif()
ENDFUNCTION()

FUNCTION(CGET_GET_FILE_ARCH name var)
    execute_process(COMMAND "${DUMPBIN}" /headers "${name}" OUTPUT_VARIABLE OUTPUT)
    if(OUTPUT MATCHES "14C machine .x86.")
        SET(${var} "x86" PARENT_SCOPE)
    elseif(OUTPUT MATCHES "8664 machine .x64.")
        SET(${var} "x64" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unexpected output for ${DUMPBIN} ${name}: ${OUTPUT}")
    endif()
ENDFUNCTION()

set(DIR_OF_FILE_TYPE_UTILS_WIN "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "" FORCE)  
FUNCTION(CGET_DLL2LIB DLL OUTPUT_LOCATION)
    GET_FILENAME_COMPONENT(NAME "${DLL}" NAME_WE)
    FILE(COPY "${DLL}" DESTINATION "${CGET_TEMP_DIR}")
    CGET_EXECUTE_PROCESS(COMMAND cmd /c "${DIR_OF_FILE_TYPE_UTILS_WIN}/dll2lib.bat" "${CGET_ARCH}" "${NAME}.dll" "${DUMPBIN}" "${LIB_CMD}" WORKING_DIRECTORY "${CGET_TEMP_DIR}")    
    FILE(COPY "${CGET_TEMP_DIR}/${NAME}.lib" DESTINATION ${OUTPUT_LOCATION})
ENDFUNCTION()

FUNCTION(CGET_GET_MSVC_RUNTIME name var)
    execute_process(COMMAND "${DUMPBIN}" /imports /headers "${name}" OUTPUT_VARIABLE OUTPUT)

    SET(${var} "" PARENT_SCOPE)
    foreach(RUNTIME "140" "120" "110" "100" "90")
        if(OUTPUT MATCHES "MSVCR${RUNTIME}D.dll" OR OUTPUT MATCHES "VCRUNTIME${RUNTIME}D.dll")
            SET(${var} "v${RUNTIME} DEBUG" PARENT_SCOPE)
            return()
        elseif(OUTPUT MATCHES "MSVCR${RUNTIME}.dll" OR OUTPUT MATCHES "VCRUNTIME${RUNTIME}.dll")
            SET(${var} "v${RUNTIME} RELEASE" PARENT_SCOPE)
            return()        
        endif()
    endforeach()
    
ENDFUNCTION()

function(CGET_CHECK_IF_FILE_IS_COMPATIBLE library var)
    CGET_GET_FILE_ARCH(${library} ARCH)
    if(NOT ${ARCH} MATCHES ${CGET_ARCH})
        SET(${var} "FALSE" PARENT_SCOPE)
        CGET_MESSAGE(16 "File '${DLL}' is incompatible due to incorrect arch; got '${ARCH}' wanted '${CGET_ARCH}'")
        return()
    endif()

    set(LIB_TYPE ${ARGN})
    if(LIB_TYPE)
        CGET_GET_FILE_TYPE(${library} FTYPE)
        if(NOT ${FTYPE} MATCHES ${LIB_TYPE})
            SET(${var} "FALSE" PARENT_SCOPE)
            CGET_MESSAGE(16 "File '${DLL}' is incompatible due to incorrect library type; got '${FTYPE}' wanted '${LIB_TYPE}'")
            return()
        endif()
    endif()    
    SET(${var} "TRUE" PARENT_SCOPE)
endfunction()

function(CGET_FILTER_BY_RUNTIME OUTPUT libraries RUNTIME_MATCH)
    SET(LOCAL_LIST ${${libraries}})    
    foreach(DLL ${LOCAL_LIST})   
        CGET_GET_MSVC_RUNTIME(${DLL} RUNTIME)
        CGET_MESSAGE(16 "${DLL} has runtime ${RUNTIME} (want ${RUNTIME_MATCH})")
        if(NOT "${RUNTIME}" MATCHES "${RUNTIME_MATCH}" AND NOT "${RUNTIME}" STREQUAL "")
            CGET_MESSAGE(16 "Runtime mismatch")
            list(REMOVE_ITEM LOCAL_LIST "${DLL}")
        endif()
    endforeach()    
    SET(${OUTPUT} ${LOCAL_LIST} PARENT_SCOPE)
endfunction()

function(CGET_FILTER_INCOMPATIBLE libraries)
    SET(LOCAL_LIST ${${libraries}})
    CGET_MESSAGE(17 "Checking ${LOCAL_LIST} for compatible files")
    foreach(DLL ${LOCAL_LIST})        
        CGET_CHECK_IF_FILE_IS_COMPATIBLE("${DLL}" IS_COMPATIBLE ${ARGN})
        if(NOT IS_COMPATIBLE)
            list(REMOVE_ITEM LOCAL_LIST "${DLL}")
        else()
            CGET_MESSAGE(12 "File '${DLL}' is compatible")
        endif()
    endforeach()
    CGET_MESSAGE(17 "Compatible: ${LOCAL_LIST}")

    SET(${libraries} ${LOCAL_LIST} PARENT_SCOPE)
endfunction()