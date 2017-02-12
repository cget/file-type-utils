INCLUDE(GetPrerequisites)

IF(WIN32)
    include("${CMAKE_CURRENT_LIST_DIR}/include.windows.cmake")
ELSE()
    include("${CMAKE_CURRENT_LIST_DIR}/include.unix.cmake")
ENDIF()

set(CGET_COPY_DEPENDENCIES_LOCAL_FILE "${CMAKE_CURRENT_LIST_DIR}/fix_dependencies.cmake" CACHE STRING "" FORCE)
function(CGET_COPY_DEPENDENCIES_LOCAL target)
	string(REPLACE ";" "\;" SAFE_PREFIX_PATH "${CMAKE_PREFIX_PATH}")
		FILE(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${target}_install_script.cmake" "#Auto-generated don't modify\n")
		INSTALL(SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${target}_install_script.cmake")
		add_custom_command(TARGET ${target} POST_BUILD
				COMMAND ${CMAKE_COMMAND} -DINSTALL_SCRIPT="${CMAKE_CURRENT_BINARY_DIR}/bundle_install.cmake" -DCMAKE_PREFIX_PATH="${SAFE_PREFIX_PATH}" "-DCMAKE_LIBRARY_PATH=${CMAKE_LIBRARY_PATH}"
										 -DTARGET=\"$<TARGET_FILE:${target}>\" -DDIR="${CGET_INSTALL_DIR}/\;${CMAKE_LIBRARY_PATH}\;" -P "${CGET_COPY_DEPENDENCIES_LOCAL_FILE}"
				COMMENT "Fixing ${target}"
		)
endfunction()