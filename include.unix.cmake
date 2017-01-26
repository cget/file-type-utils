find_program(OBJDUMP "file" PATHS     "/usr/local/bin" "/usr/bin")

FUNCTION(CGET_GET_FILE_TYPE name var)

ENDFUNCTION()

FUNCTION(CGET_GET_FILE_ARCH name var)
    execute_process(COMMAND "${OBJDUMP}" -i "${name}" OUTPUT_VARIABLE OUTPUT)
    if(${OUTPUT} MATCHES "i386")
        SET(${var} "x86" PARENT_SCOPE)
    elseif(${OUTPUT} MATCHES "x64")
        SET(${var} "x64" PARENT_SCOPE)
    else()
        message("${OUTPUT}")
    endif()
ENDFUNCTION()