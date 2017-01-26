INCLUDE(GetPrerequisites)

IF(WIN32)
    include("${CMAKE_CURRENT_LIST_DIR}/include.windows.cmake")
ELSE()
    include("${CMAKE_CURRENT_LIST_DIR}/include.unix.cmake")
ENDIF()
