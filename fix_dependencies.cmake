if(APPLE)
	string(REPLACE "\\ " " " TARGET "${TARGET}")
	string(REPLACE "\\ " " " DIR "${DIR}")
endif()

if(NOT CMAKE_INSTALL_PREFIX)
       get_filename_component(CMAKE_INSTALL_PREFIX ${TARGET} DIRECTORY)
endif()
       get_filename_component(TARGET_DIR ${TARGET} DIRECTORY)
get_filename_component(TARGET_NAME ${TARGET} NAME)
message("Fixing up ${TARGET_NAME} in ${CMAKE_INSTALL_PREFIX} with ${CMAKE_PREFIX_PATH} and ${DIR}")

include(GetPrerequisites)
GET_PREREQUISITES("${TARGET}" PREREQS 1 0 "${CMAKE_INSTALL_PREFIX}" "${DIR}")
message("${TARGET_NAME} has dependencies ${PREREQS}")

foreach(DEP ${PREREQS})
	get_filename_component(DEP_NAME ${DEP} NAME)
	get_filename_component(DEP_EXT ${DEP} EXT)

	if(NOT EXISTS ${DEP})
		GP_RESOLVE_ITEM("" "${DEP}" "${CMAKE_INSTALL_PREFIX}" "${DIR};${CMAKE_LIBRARY_PATH}" RESOLVED)
	else()
		SET(RESOLVED "${DEP}")
	endif()

	if(APPLE)
		if(NOT ${DEP} MATCHES "@")
		       message("Checking ${DEP}...")
		       if(NOT IS_ABSOLUTE "${DEP}")		       
		       	      message("Rewriting entry")
		       	      EXECUTE_PROCESS(COMMAND install_name_tool -change "${DEP}" "@executable_path/${DEP}" "${TARGET}")
		       	      SET(DEP "@executable_path/${DEP}")		
		       endif()		       
		endif()


		string(REPLACE "@rpath" "../Frameworks/" DEP "${DEP}")
		string(REPLACE "@executable_path" "." DEP "${DEP}")
	endif()

	# Linux gives us full paths for all deps. Mac gives us local, relative paths. We try to handle that here in a sane way
	IF(EXISTS "${DEP}")   
		  set(COPY_LOCATION ${CMAKE_INSTALL_PREFIX}/${DEP_NAME})
	else()
		  set(COPY_LOCATION ${CMAKE_INSTALL_PREFIX}/${DEP})
	endif()  
	
	get_filename_component(COPY_LOCATION "${COPY_LOCATION}" ABSOLUTE)
    IF(EXISTS "${RESOLVED}" AND NOT "${RESOLVED}" STREQUAL "${COPY_LOCATION}")
	    message("Copying over ${DEP_NAME}(${RESOLVED}) ${RESOLVED} ${COPY_LOCATION} ")
		EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy ${RESOLVED} ${COPY_LOCATION})
		EXECUTE_PROCESS(COMMAND "${CMAKE_COMMAND}" "-DINSTALL_SCRIPT=${INSTALL_SCRIPT}"
					"-DCMAKE_LIBRARY_PATH=\"${CMAKE_LIBRARY_PATH}\""
					"-DCMAKE_PREFIX_PATH=\"${CMAKE_PREFIX_PATH}\"" "-DTARGET=${COPY_LOCATION}" "-DDIR=${DIR}" 
					"-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}" -P "${CMAKE_CURRENT_LIST_FILE}")
		IF(EXISTS "${INSTALL_SCRIPT}")
			FILE(APPEND "${INSTALL_SCRIPT}" "  file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/bin\" TYPE DIRECTORY FILES \"${RESOLVED}\")\n")
		ENDIF()
	ENDIF()
endforeach() 
