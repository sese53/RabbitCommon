# Author: Kang Lin <kl222@126.com>

cmake_minimum_required(VERSION 2.8.12)

include(CMakePackageConfigHelpers)
include(CMakeParseArguments)
include(GenerateExportHeader)

include(CPackComponent)

SET(CMAKE_INSTALL_SYSTEM_RUNTIME_COMPONENT Runtime)
if(CMAKE_MFC_FLAG)
    set(CMAKE_INSTALL_MFC_LIBRARIES TRUE)
endif()
if(CMAKE_BUILD_TYPE)
    string(TOLOWER ${CMAKE_BUILD_TYPE} LOWER_BUILD_TYPE)
endif()
if(LOWER_BUILD_TYPE STREQUAL "debug")
    set(CMAKE_INSTALL_DEBUG_LIBRARIES TRUE)
endif()
include(InstallRequiredSystemLibraries)

cpack_add_component(Development
    DISPLAY_NAME  "Development"
    DESCRIPTION   "Development"
	DEPENDS Runtime
    )

cpack_add_component(Runtime
    DISPLAY_NAME  "Runtime"
    DESCRIPTION   "Runtime"
    )

# 产生android平台分发设置
# 详见： ${QT_INSTALL_DIR}/features/android/android_deployment_settings.prf
# ANDROID_SOURCES_DIR: Android 源码文件目录。默认为：${CMAKE_CURRENT_SOURCE_DIR}/android
function(GENERATED_DEPLOYMENT_SETTINGS)
    cmake_parse_arguments(PARA "" "NAME;APPLACTION;ANDROID_SOURCES_DIR" "" ${ARGN})

    if(NOT ANDROID_NDK)
        set(ANDROID_NDK $ENV{ANDROID_NDK})
        if(NOT ANDROID_NDK)
            set(ANDROID_NDK ${ANDROID_NDK_ROOT})
            if(NOT ANDROID_NDK)
                set(ANDROID_NDK $ENV{ANDROID_NDK_ROOT})
            endif()
        endif()
    endif()

    if(NOT ANDROID_SDK)
        set(ANDROID_SDK $ENV{ANDROID_SDK})
        if(NOT ANDROID_SDK)
            set(ANDROID_SDK ${ANDROID_SDK_ROOT})
            if(NOT ANDROID_SDK)
                set(ANDROID_SDK $ENV{ANDROID_SDK_ROOT})
            endif()
        endif()
    endif()

    if(NOT DEFINED BUILD_TOOS_VERSION)
        set(BUILD_TOOS_VERSION $ENV{BUILD_TOOS_VERSION})
    endif()
    if(NOT DEFINED BUILD_TOOS_VERSION)
        set(BUILD_TOOS_VERSION "28.0.3")
    endif()
    
    if(DEFINED PARA_NAME)
        set(_file_name ${PARA_NAME})
        #message("file_name:${PARA_NAME}")
    else()
        SET(_file_name "${PROJECT_BINARY_DIR}/android-lib${PROJECT_NAME}.so-deployment-settings.json")
    endif()

    FILE(WRITE ${_file_name} "{\n")
    FILE(APPEND ${_file_name} "\"description\": \"This file is generated by qmake to be read by androiddeployqt and should not be modified by hand.\",\n")
    FILE(APPEND ${_file_name} "\"qt\":\"${QT_INSTALL_DIR}\",\n")
    FILE(APPEND ${_file_name} "\"sdk\":\"${ANDROID_SDK}\",\n")
    FILE(APPEND ${_file_name} "\"sdkBuildToolsRevision\":\"${BUILD_TOOS_VERSION}\",\n")
    FILE(APPEND ${_file_name} "\"ndk\":\"${ANDROID_NDK}\",\n")

    FILE(APPEND ${_file_name} "\"stdcpp-path\":\"${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so\",\n")
    FILE(APPEND ${_file_name} "\"useLLVM\":true,\n")
    FILE(APPEND ${_file_name} "\"toolchain-prefix\":\"llvm\",\n")
    FILE(APPEND ${_file_name} "\"tool-prefix\":\"llvm\",\n")

    IF(CMAKE_HOST_WIN32)
        IF(ANDROID_NDK_HOST_X64)
            FILE(APPEND ${_file_name} "\"ndk-host\":\"windows-x86_64\",\n")
        ELSE()
            FILE(APPEND ${_file_name} "\"ndk-host\":\"windows\",\n")
        ENDIF()
    ELSE()
        IF(ANDROID_NDK_HOST_X64)
            FILE(APPEND ${_file_name} "\"ndk-host\":\"linux-x86_64\",\n")
	ELSE()
	    FILE(APPEND ${_file_name} "\"ndk-host\":\"linux\",\n")
        ENDIF()
    ENDIF()
    FILE(APPEND ${_file_name} "\"target-architecture\":\"${CMAKE_ANDROID_ARCH_ABI}\",\n")
    IF(DEFINED PARA_ANDROID_SOURCES_DIR)
        FILE(APPEND ${_file_name} "\"android-package-source-directory\":\"${PARA_ANDROID_SOURCES_DIR}\",\n")
    else()
        FILE(APPEND ${_file_name} "\"android-package-source-directory\":\"${CMAKE_CURRENT_SOURCE_DIR}/android\",\n")
    endif()
    IF(ANDROID_EXTRA_LIBS)
        FILE(APPEND ${_file_name} "\"android-extra-libs\":\"${ANDROID_EXTRA_LIBS}\",\n")
    ENDIF(ANDROID_EXTRA_LIBS)
    if(DEFINED PARA_APPLACTION)
        FILE(APPEND ${_file_name} "\"application-binary\":\"${PARA_APPLACTION}\"\n")
        #message("app_bin:${PARA_APPLACTION}")
    else()
        FILE(APPEND ${_file_name} "\"application-binary\":\"${CMAKE_BINARY_DIR}/bin/lib${PROJECT_NAME}.so\"\n")
    endif()
    FILE(APPEND ${_file_name} "}")
endfunction(GENERATED_DEPLOYMENT_SETTINGS)

# 得到子目录
macro(SUBDIRLIST result curdir)
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if(IS_DIRECTORY ${curdir}/${child})
            LIST(APPEND dirlist ${child})
        endif()
    endforeach()
    set(${result} ${dirlist})
endmacro()

# Install QIcon theme
# SOURCES: Default is Resource/icons/
# DESTINATION: Default is ${CMAKE_INSTALL_PREFIX}/icons
option(INSTALL_ICONS_TO_BUILD_PATH "Install icons to build path" ON)
function(INSTALL_ICON_THEME)
    cmake_parse_arguments(PARA "" "DESTINATION" "SOURCES" ${ARGN})
    
    if(NOT DEFINED SOURCES)
        set(PARA_SOURCES Resource/icons/)
    endif()
    if(NOT DEFINED DESTINATION)
        if(ANDROID)
            set(PARA_DESTINATION assets/icons)
        else()
            set(PARA_DESTINATION icons)
        endif()
    endif()

    install(DIRECTORY ${PARA_SOURCES}
        DESTINATION ${PARA_DESTINATION}
        COMPONENT Runtime)

    if(NOT ANDROID)
        if(INSTALL_ICONS_TO_BUILD_PATH)
            file(COPY ${PARA_SOURCES} DESTINATION ${CMAKE_BINARY_DIR}/icons)
        endif()
    endif()
endfunction()

# 安装指定目标文件
function(INSTALL_TARGETS)
    cmake_parse_arguments(PARA "" "DESTINATION" "TARGETS" ${ARGN})
    if(NOT DEFINED PARA_TARGETS)
        message("Usage: INSTALL_TARGETS(TARGETS ... DESTINATION ...)")
        return()
    endif()

    if(NOT DEFINED DESTINATION)
        if(ANDROID)
            set(PARA_DESTINATION "libs/${ANDROID_ABI}")
        elseif(WIN32)
            set(PARA_DESTINATION "${CMAKE_INSTALL_BINDIR}")
        else()
            set(PARA_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
        endif()
    endif()

    foreach(component ${PARA_TARGETS})
        INSTALL(FILES $<TARGET_FILE:${component}>
            DESTINATION "${PARA_DESTINATION}"
                COMPONENT Runtime)
        if(NOT ANDROID AND UINX)
            INSTALL(FILES $<TARGET_LINKER_FILE:${component}>
                DESTINATION "${PARA_DESTINATION}"
                    COMPONENT Runtime)
        endif()
    endforeach()
endfunction()

# 安装目标
#    [必须]NAME              目标名
#    ISEXE                  是执行程序目标还是库目标
#    ISPLUGIN               是插件
#    RUNTIME
#    LIBRARY                库安装位置
#    INSTALL_PLUGIN_LIBRARY_DIR 插件库安装位置
#    ARCHIVE
#    PUBLIC_HEADER          头文件的安装位置
#    INCLUDES               导出安装头文件位置
#    VERSION                版本号
#    EXPORT_NAME            cmake 配置文件的导出名
#    NAMESPACE              cmake 配置文件的导出目录 
#    INSTALL_CMAKE_CONFIG_IN_FILE   ${PROJECT_NAME}Config.cmake.in 位置
function(INSTALL_TARGET)
    cmake_parse_arguments(PARA "ISEXE;ISPLUGIN"
        "NAME;EXPORT_NAME;NAMESPACE;RUNTIME;LIBRARY;ARCHIVE;PUBLIC_HEADER;INSTALL_PLUGIN_LIBRARY_DIR;VERSION;INSTALL_CMAKE_CONFIG_IN_FILE"
        "INCLUDES"
        ${ARGN})
    if(NOT DEFINED PARA_NAME)
        message(FATAL_ERROR "Use:
            INSTALL_TARGET
                NAME name
                [ISEXE]
                [ISPULGIN]
                [INSTALL_PLUGIN_LIBRARY_DIR ...]
                [RUNTIME ...]
                [LIBRARY ...]
                [ARCHIVE ...]
                [PUBLIC_HEADER ...]
                [INCLUDES ...]
                [VERSION verson]
                [EXPORT_NAME install export configure file name]
                [INSTALL_CMAKE_CONFIG_IN_FILE cmake configure(Config.cmake.in) file]"
                )
    endif()
    
    if(PARA_ISPLUGIN)
    
        if(WIN32)
            INSTALL(TARGETS ${PARA_NAME}
                RUNTIME DESTINATION "${PARA_INSTALL_PLUGIN_LIBRARY_DIR}"
                        COMPONENT Runtime
                )
        elseif(ANDROID)
            # cmake >= 3.16, the CMAKE_INSTALL_LIBDIR is support multi-arch lib dir
            # See: https://gitlab.kitware.com/cmake/cmake/-/issues/20565
            INSTALL(TARGETS ${PARA_NAME}
                LIBRARY DESTINATION "libs/${ANDROID_ABI}"
                        COMPONENT Runtime
                )
        else()
            INSTALL(TARGETS ${PARA_NAME}
                LIBRARY DESTINATION "${PARA_INSTALL_PLUGIN_LIBRARY_DIR}"
                        COMPONENT Runtime
                )
        endif()
        INSTALL(DIRECTORY "$<TARGET_FILE_DIR:${PARA_NAME}>/"
            DESTINATION "${PARA_INSTALL_PLUGIN_LIBRARY_DIR}"
                COMPONENT Runtime
            )
        # 分发
        IF(WIN32 AND BUILD_SHARED_LIBS)
            IF(MINGW)
                # windeployqt 分发时，是根据是否 strip 来判断是否是 DEBUG 版本,而用mingw编译时,qt没有自动 strip
                add_custom_command(TARGET ${PARA_NAME} POST_BUILD
                    COMMAND strip "$<TARGET_FILE:${PARA_NAME}>"
                    )
            ENDIF(MINGW)

            #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
            add_custom_command(TARGET ${PARA_NAME} POST_BUILD
                COMMAND "${QT_INSTALL_DIR}/bin/windeployqt"
                --no-compiler-runtime # 因为已用了 include(InstallRequiredSystemLibraries)
                --verbose 7
                --no-translations
                --dir ${CMAKE_BINARY_DIR}/bin
                --libdir ${CMAKE_BINARY_DIR}/bin
                --plugindir ${CMAKE_BINARY_DIR}/bin
                "$<TARGET_FILE:${PARA_NAME}>"
                )
        ENDIF(WIN32 AND BUILD_SHARED_LIBS)
        
    else(PARA_ISPLUGIN)
        
        # cmake >= 3.16, the CMAKE_INSTALL_LIBDIR is support multi-arch lib dir
        # See: https://gitlab.kitware.com/cmake/cmake/-/issues/20565
        # Install target
        if(ANDROID)
            if(NOT DEFINED PARA_RUNTIME)
                set(PARA_RUNTIME "libs/${ANDROID_ABI}")
            endif()
            if(NOT DEFINED PARA_LIBRARY)
                set(PARA_LIBRARY "libs/${ANDROID_ABI}")
            endif()
        elseif(WIN32)
            if(NOT DEFINED PARA_RUNTIME)
                set(PARA_RUNTIME "${CMAKE_INSTALL_BINDIR}")
            endif()
            if(NOT DEFINED PARA_LIBRARY)
                set(PARA_LIBRARY "${CMAKE_INSTALL_BINDIR}")
            endif()
        else()
            if(NOT DEFINED PARA_RUNTIME)
                set(PARA_RUNTIME "${CMAKE_INSTALL_BINDIR}")
            endif()
            if(NOT DEFINED PARA_LIBRARY)
                set(PARA_LIBRARY "${CMAKE_INSTALL_LIBDIR}")
            endif()
        endif()
        if(NOT DEFINED PARA_ARCHIVE)
            set(PARA_ARCHIVE "${CMAKE_INSTALL_LIBDIR}")
        endif()
        if(PARA_ISEXE)
            set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION "${PARA_RUNTIME}")
            INSTALL(TARGETS ${PARA_NAME}
                RUNTIME DESTINATION "${PARA_RUNTIME}"
                    COMPONENT Runtime
                LIBRARY DESTINATION "${PARA_LIBRARY}"
                    COMPONENT Runtime
                ARCHIVE DESTINATION "${PARA_ARCHIVE}"
                )
            
            #分发
            IF(ANDROID)
                Set(JSON_FILE ${CMAKE_BINARY_DIR}/android_deployment_settings.json)
                GENERATED_DEPLOYMENT_SETTINGS(NAME ${JSON_FILE}
                    ANDROID_SOURCES_DIR ${PARA_ANDROID_SOURCES_DIR}
                    APPLACTION "${CMAKE_BINARY_DIR}/bin/lib${PARA_NAME}.so")
                
#                if(CMAKE_BUILD_TYPE)
#                    string(TOLOWER ${CMAKE_BUILD_TYPE} LOWER_BUILD_TYPE)
#                endif()
                if(LOWER_BUILD_TYPE STREQUAL "release")
                    if(NOT DEFINED STOREPASS)
                        set(STOREPASS $ENV{STOREPASS})
                    endif()

                    if(STOREPASS)
                        add_custom_target(APK #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                            COMMAND "${QT_INSTALL_DIR}/bin/androiddeployqt"
                                --output ${CMAKE_INSTALL_PREFIX} #注意输出文件名为：[${CMAKE_INSTALL_PREFIX}的最后一级目录名]-release-signed.apk
                                --input ${JSON_FILE}
                                --verbose
                                --gradle
                                --release
                                --android-platform ${ANDROID_PLATFORM}
                                --sign ${RabbitCommon_DIR}/RabbitCommon.keystore rabbitcommon 
                                --storepass ${STOREPASS}
                            )
                    else()
                        message(WARNING "Please set camke paramter or environment value STOREPASS, will use debug deploy ......")
                        add_custom_target(APK #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                            COMMAND "${QT_INSTALL_DIR}/bin/androiddeployqt"
                                --output ${CMAKE_INSTALL_PREFIX} #注意输出文件名为：[${CMAKE_INSTALL_PREFIX}的最后一级目录名]-debug.apk
                                --input ${JSON_FILE}
                                --verbose
                                --gradle
                                --android-platform ${ANDROID_PLATFORM}
                            )
                    endif()
                    
                else()
                    add_custom_target(APK #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                        COMMAND "${QT_INSTALL_DIR}/bin/androiddeployqt"
                            --output ${CMAKE_INSTALL_PREFIX} #注意输出文件名为：[${CMAKE_INSTALL_PREFIX}的最后一级目录名]-debug.apk
                            --input ${JSON_FILE}
                            --verbose
                            --gradle
                            --android-platform ${ANDROID_PLATFORM}
                        )
                    add_custom_target(INSTALL_APK #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                        COMMAND "${QT_INSTALL_DIR}/bin/androiddeployqt"
                            --output ${CMAKE_INSTALL_PREFIX} #注意输出文件名为：[${CMAKE_INSTALL_PREFIX}的最后一级目录名]-debug.apk
                            --input ${JSON_FILE}
                            --reinstall
                            --verbose
                            --gradle
                            --android-platform ${ANDROID_PLATFORM}
                        )
                endif()
                
            ENDIF(ANDROID)
        else(PARA_ISEXE) # Is library
            if(NOT DEFINED PARA_PUBLIC_HEADER)
                set(PARA_PUBLIC_HEADER ${CMAKE_INSTALL_INCLUDEDIR}/${PARA_NAME})
            endif()
            if(NOT DEFINED PARA_INCLUDES)
                set(PARA_INCLUDES ${CMAKE_INSTALL_INCLUDEDIR})
            endif()
            
            if(NOT DEFINED PARA_EXPORT_NAME)
                set(PARA_EXPORT_NAME ${PARA_NAME}Config)
            endif()
            
            INSTALL(TARGETS ${PARA_NAME}
                EXPORT ${PARA_EXPORT_NAME}
                RUNTIME DESTINATION "${PARA_RUNTIME}"
                    COMPONENT Runtime
                LIBRARY DESTINATION "${PARA_LIBRARY}"
                    COMPONENT Runtime
                ARCHIVE DESTINATION "${PARA_ARCHIVE}"
                    COMPONENT Development
                PUBLIC_HEADER DESTINATION ${PARA_PUBLIC_HEADER}
                    COMPONENT Development
                INCLUDES DESTINATION ${PARA_INCLUDES}
                )
            # Install cmake configure files
            if(DEFINED PARA_NAMESPACE)
                export(TARGETS ${PARA_NAME}
                    APPEND FILE ${CMAKE_BINARY_DIR}/${PARA_NAME}Config.cmake
                    NAMESPACE ${PARA_NAMESPACE}::
                    )
                install(EXPORT ${PARA_EXPORT_NAME}
                    DESTINATION "${PARA_ARCHIVE}/cmake/${PARA_NAMESPACE}"
                        COMPONENT Development
                    NAMESPACE ${PARA_NAMESPACE}::
                    )
            else()
                set(PARA_NAMESPACE ${PARA_NAME})
                export(TARGETS ${PARA_NAME}
                    APPEND FILE ${CMAKE_BINARY_DIR}/${PARA_NAME}Config.cmake
                    )
                # Install cmake configure files
                install(EXPORT ${PARA_EXPORT_NAME}
                    DESTINATION "${PARA_ARCHIVE}/cmake/${PARA_NAMESPACE}"
                        COMPONENT Development
                    )
            endif()
            if(PARA_EXPORT_NAME)
                # 因为编译树中已有 export(${PARA_NAME}Config.cmake)
                if(NOT DEFINED PARA_INSTALL_CMAKE_CONFIG_IN_FILE)
                    set(PARA_INSTALL_CMAKE_CONFIG_IN_FILE ${CMAKE_SOURCE_DIR}/cmake/${PARA_NAME}Config.cmake.in)
                endif()
                if(EXISTS ${PARA_INSTALL_CMAKE_CONFIG_IN_FILE})
                    configure_package_config_file(
                        ${PARA_INSTALL_CMAKE_CONFIG_IN_FILE}
                        ${CMAKE_CURRENT_BINARY_DIR}/${PARA_NAME}Config.cmake.in
                        INSTALL_DESTINATION "${PARA_ARCHIVE}/cmake/${PARA_NAMESPACE}"
                        )
                    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PARA_NAME}Config.cmake.in
                        DESTINATION "${PARA_ARCHIVE}/cmake/${PARA_NAMESPACE}"
                            COMPONENT Development
                        RENAME ${PARA_NAME}Config.cmake)
                else()
                    message(WARNING "Please create file: ${PARA_INSTALL_CMAKE_CONFIG_IN_FILE}")
                endif()
            endif()
            # Install cmake version configure file
            if(DEFINED PARA_VERSION)
                write_basic_package_version_file(
                    "${CMAKE_BINARY_DIR}/${PARA_NAME}ConfigVersion.cmake"
                    VERSION ${PARA_VERSION}
                    COMPATIBILITY AnyNewerVersion)
                install(FILES "${CMAKE_BINARY_DIR}/${PARA_NAME}ConfigVersion.cmake"
                    DESTINATION "${PARA_ARCHIVE}/cmake/${PARA_NAMESPACE}"
                        COMPONENT Development)
            endif()
        endif(PARA_ISEXE)
        
        # Windows 下分发
        IF(WIN32 AND BUILD_SHARED_LIBS)
            IF(MINGW)
                # windeployqt 分发时，是根据是否 strip 来判断是否是 DEBUG 版本,而用mingw编译时,qt没有自动 strip
                add_custom_command(TARGET ${PARA_NAME} POST_BUILD
                    COMMAND strip "$<TARGET_FILE:${PARA_NAME}>"
                    )
                #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                add_custom_command(TARGET ${PARA_NAME} POST_BUILD
                    COMMAND "${QT_INSTALL_DIR}/bin/windeployqt"
                    --no-compiler-runtime # 因为已用了 include(InstallRequiredSystemLibraries)
                    --verbose 7
                    --no-translations
                    "$<TARGET_FILE:${PARA_NAME}>"
                    )
            ELSE(MINGW)
                #注意 需要把 ${QT_INSTALL_DIR}/bin 加到环境变量PATH中
                add_custom_command(TARGET ${PARA_NAME} POST_BUILD
                    COMMAND "${QT_INSTALL_DIR}/bin/windeployqt"
                    --no-compiler-runtime # 因为已用了 include(InstallRequiredSystemLibraries)
                    --verbose 7
                    #--no-translations
                    #--dir "$<TARGET_FILE_DIR:${PARA_NAME}>"
                    "$<TARGET_FILE:${PARA_NAME}>"
                    )
            ENDIF(MINGW)

            if(DEFINED PARA_ISEXE)
                INSTALL(DIRECTORY "$<TARGET_FILE_DIR:${PARA_NAME}>/"
                    DESTINATION "${PARA_RUNTIME}"
                        COMPONENT Runtime)
            endif()
        ENDIF(WIN32 AND BUILD_SHARED_LIBS)
        
    endif(PARA_ISPLUGIN)
endfunction()

# 增加目标
# 参数：
#    [必须]SOURCE_FILES              源文件（包括头文件，资源文件等）
#    ISEXE                          是执行程序目标还是库目标
#    ISPLUGIN                       是插件
#    NO_TRANSLATION                 不产生翻译资源
#    WINDOWS                        窗口程序
#    NAME                           目标名。注意：翻译资源文件名(.ts)默认是 ${PROJECT_NAME}
#    OUTPUT_DIR                     目标生成目录
#    VERSION                        版本
#    ANDROID_SOURCES_DIR            Android 源码文件目录
#    INCLUDE_DIRS                   包含目录
#    PRIVATE_INCLUDE_DIRS           私有包含目录
#    LIBS                           公有依赖库
#    PRIVATE_LIBS                   私有依赖库
#    DEFINITIONS                    公有宏定义
#    PRIVATE_DEFINITIONS            私有宏宏义
#    OPTIONS                        公有选项
#    PRIVATE_OPTIONS                私有选项
#    FEATURES                       公有特性
#    PRIVATE_FEATURES               私有特性
#    NO_INSTALL                     不安装
#    INSTALL_HEADER_FILES           如果是库，要安装的头文件
#    INSTALL_PUBLIC_HEADER          头文件安装位置
#    INSTALL_INCLUDES               导出安装头文件位置
#    INSTALL_PLUGIN_LIBRARY_DIR     库安装位置
#    INSTALL_EXPORT_NAME            安装 CMAKE 配置文件导出名
#    INSTALL_NAMESPACE              安装 cmake 配置文件的导出目录 
#    INSTALL_CMAKE_CONFIG_IN_FILE   安装 ${PROJECT_NAME}Config.cmake.in 位置
function(ADD_TARGET)
    SET(MUT_PARAS
        SOURCE_FILES            #源文件（包括头文件，资源文件等）
        INSTALL_HEADER_FILES    #如果是库，要安装的头文件
        INCLUDE_DIRS            #包含目录
        PRIVATE_INCLUDE_DIRS    #私有包含目录
        LIBS                    #公有依赖库
        PRIVATE_LIBS            #私有依赖库
        DEFINITIONS             #公有宏定义
        PRIVATE_DEFINITIONS     #私有宏宏义
        OPTIONS                 #公有选项
        PRIVATE_OPTIONS         #私有选项
        FEATURES                #公有特性
        PRIVATE_FEATURES        #私有特性
        INSTALL_INCLUDES        #导出包安装的头文件目录
        )
    SET(SINGLE_PARAS
        NAME
        OUTPUT_DIR
        VERSION
        ANDROID_SOURCES_DIR
        INSTALL_PUBLIC_HEADER
        INSTALL_PLUGIN_LIBRARY_DIR
        INSTALL_EXPORT_NAME
        INSTALL_NAMESPACE
        INSTALL_CMAKE_CONFIG_IN_FILE
        )
    cmake_parse_arguments(PARA
        "ISEXE;ISPLUGIN;ISWINDOWS;NO_TRANSLATION;NO_INSTALL"
        "${SINGLE_PARAS}"
        "${MUT_PARAS}"
        ${ARGN})
    if(NOT DEFINED PARA_SOURCE_FILES)
        message(FATAL_ERROR "Use:
            ADD_TARGET
                [NAME name]
                [ISEXE]
                [ISPLUGIN]
                [ISWINDOWS]
                [NO_TRANSLATION]
                [NO_INSTALL]
                SOURCE_FILES source1 [source2 ... header1 ...]]
                [INSTALL_HEADER_FILES header1 [header2 ...]]
                [LIBS lib1 [lib2 ...]]
                [PRIVATE_LIBS lib1 [lib2 ...]]
                [INCLUDE_DIRS [include_dir1 ...]]
                [PRIVATE_INCLUDE_DIRS [include_dir1 ...]]
                [DEFINITIONS [definition1 ...]]
                [PRIVATE_DEFINITIONS [defnitions1 ...]]
                [OUTPUT_DIR output_dir]
                [PRIVATE_OPTIONS option1 [option2 ...]]
                [OPTIONS option1 [option2 ...]]
                [FEATURES feature1 [feature2 ...]]
                [PRIVATE_FEATURES feature1 [feature2 ...]]
                [VERSION version]
                [ANDROID_SOURCES_DIR android_source_dir]
                [INSTALL_PLUGIN_LIBRARY_DIR dir]
                [INSTALL_EXPORT_NAME configure_file_name]
                [INSTALL_CMAKE_CONFIG_IN_FILE install cmake config file]")
        return()
    endif()

    if(NOT DEFINED PARA_NAME)
        set(PARA_NAME ${PROJECT_NAME})
    endif()

    if(NOT PARA_NO_TRANSLATION)
        #翻译资源    
        if(ANDROID)
            if(PARA_ISPLUGIN)
                set(QM_INSTALL_DIR assets/${PARA_INSTALL_PLUGIN_LIBRARY_DIR}/translations)
            else()
                set(QM_INSTALL_DIR assets/translations)
            endif()
        else()
            if(PARA_ISPLUGIN)
                set(QM_INSTALL_DIR ${PARA_INSTALL_PLUGIN_LIBRARY_DIR}/translations)
            else()
                set(QM_INSTALL_DIR translations)
            endif()
        endif()
        GENERATED_QT_TRANSLATIONS(
            TARGET ${PARA_NAME}
            SOURCES ${PARA_SOURCE_FILES} ${PARA_INSTALL_HEADER_FILES}
            OUT_QRC TRANSLATIONS_QRC_FILES
            QM_INSTALL_DIR ${QM_INSTALL_DIR})
#        if(CMAKE_BUILD_TYPE)
#            string(TOLOWER ${CMAKE_BUILD_TYPE} LOWER_BUILD_TYPE)
#        endif()
        if(LOWER_BUILD_TYPE STREQUAL "debug")
            LIST(APPEND PARA_SOURCE_FILES ${TRANSLATIONS_QRC_FILES})
        endif()
    endif(NOT PARA_NO_TRANSLATION)
    
    if(PARA_ISEXE)
        if(ANDROID)
            add_library(${PARA_NAME} SHARED ${PARA_SOURCE_FILES} ${PARA_INSTALL_HEADER_FILES})
        else()
            if(DEFINED PARA_ISWINDOWS AND WIN32)
                set(WINDOWS_APP WIN32)
            endif()    
            add_executable(${PARA_NAME} ${WINDOWS_APP} ${PARA_SOURCE_FILES} ${PARA_INSTALL_HEADER_FILES})
            
            if(MINGW)
                set_target_properties(${PARA_NAME} PROPERTIES LINK_FLAGS "-mwindows")
            elseif(MSVC)
                if(Qt5_VERSION VERSION_LESS "5.7.0")
                    set_target_properties(${PARA_NAME} PROPERTIES LINK_FLAGS
                        "/SUBSYSTEM:WINDOWS\",5.01\" /ENTRY:mainCRTStartup")
                else()
                    set_target_properties(${PARA_NAME} PROPERTIES LINK_FLAGS
                        "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
                endif()
            endif()
        endif()
    else(PARA_ISEXE) # Is library

        # For debug libs and exes, add "_d" postfix
        if(NOT CMAKE_DEBUG_POSTFIX)
            set(CMAKE_DEBUG_POSTFIX "_d")
        endif()
        if(WIN32)
            if(LOWER_BUILD_TYPE STREQUAL "debug")
                option(WITH_LIBRARY_SUFFIX_VERSION "Library suffix plus version number" OFF)
            else()
                option(WITH_LIBRARY_SUFFIX_VERSION "Library suffix plus version number" ON)
            endif()
            if(WITH_LIBRARY_SUFFIX_VERSION)
                if(NOT DEFINED PARA_VERSION)
                    get_target_property(PARA_VERSION ${PARA_NAME} VERSION)
                endif()
                if(PARA_VERSION_FOUND OR PARA_VERSION)
                    if(CMAKE_BUILD_TYPE)
                        string(TOUPPER ${CMAKE_BUILD_TYPE} UPPER_CMAKE_BUILD_TYPE)
                        SET(CMAKE_${UPPER_CMAKE_BUILD_TYPE}_POSTFIX "${CMAKE_${UPPER_CMAKE_BUILD_TYPE}_POSTFIX}_${PARA_VERSION}")
                    elseif(CMAKE_CONFIGURATION_TYPES)
                        foreach(PARA_CONFIG ${CMAKE_CONFIGURATION_TYPES})
                            string(TOUPPER ${PARA_CONFIG} UPPER_PARA_CONFIG)
                            SET(CMAKE_${UPPER_PARA_CONFIG}_POSTFIX "${CMAKE_${UPPER_PARA_CONFIG}_POSTFIX}_${PARA_VERSION}")
                        endforeach()
                    endif()
                endif(PARA_VERSION_FOUND OR PARA_VERSION)
            endif(WITH_LIBRARY_SUFFIX_VERSION)
        endif()

        string(TOLOWER ${PARA_NAME} LOWER_PROJECT_NAME)
        set(PARA_INSTALL_HEADER_FILES ${PARA_INSTALL_HEADER_FILES} 
            ${CMAKE_CURRENT_BINARY_DIR}/${LOWER_PROJECT_NAME}_export.h)
        
        add_library(${PARA_NAME} ${PARA_SOURCE_FILES} ${PARA_INSTALL_HEADER_FILES})
        
        GENERATE_EXPORT_HEADER(${PARA_NAME})
        file(COPY ${CMAKE_CURRENT_BINARY_DIR}/${LOWER_PROJECT_NAME}_export.h
            DESTINATION ${CMAKE_BINARY_DIR})
    endif(PARA_ISEXE)

    IF(MSVC)
        # This option is to enable the /MP switch for Visual Studio 2005 and above compilers
        OPTION(WIN32_USE_MP "Set to ON to build with the /MP option (Visual Studio 2005 and above)." ON)
        MARK_AS_ADVANCED(WIN32_USE_MP)
        IF(WIN32_USE_MP)
            target_compile_options(${PARA_NAME} PRIVATE /MP)
        ENDIF(WIN32_USE_MP)
        target_compile_options(${PARA_NAME} PRIVATE "$<$<C_COMPILER_ID:MSVC>:/utf-8>")
        target_compile_options(${PARA_NAME} PRIVATE "$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
    ENDIF(MSVC)

    if(DEFINED PARA_OUTPUT_DIR)
        set_target_properties(${PARA_NAME} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${PARA_OUTPUT_DIR}
            RUNTIME_OUTPUT_DIRECTORY ${PARA_OUTPUT_DIR}
            ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
            )
    else()
        set_target_properties(${PARA_NAME} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
            ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
            )
    endif()

    # Be will to install header files
    if(DEFINED PARA_INSTALL_HEADER_FILES)
        set_target_properties(${PARA_NAME} PROPERTIES
            PUBLIC_HEADER "${PARA_INSTALL_HEADER_FILES}" # Install head files
            )
    endif()

    if(DEFINED PARA_VERSION)
        set_target_properties(${PARA_NAME} PROPERTIES
            VERSION ${PARA_VERSION})
    endif()
    
    if(DEFINED PARA_LIBS AND PARA_LIBS)
        target_link_libraries(${PARA_NAME} PUBLIC ${PARA_LIBS})
    endif()
    
    if(DEFINED PARA_PRIVATE_LIBS AND PARA_PRIVATE_LIBS)
        target_link_libraries(${PARA_NAME} PRIVATE ${PARA_PRIVATE_LIBS})
    endif()

    if(DEFINED PARA_DEFINITIONS)
        target_compile_definitions(${PARA_NAME} PUBLIC ${PARA_DEFINITIONS})
    endif()
    
    if(DEFINED PARA_PRIVATE_DEFINITIONS AND PARA_PRIVATE_DEFINITIONS)
        target_compile_definitions(${PARA_NAME} PRIVATE ${PARA_PRIVATE_DEFINITIONS})
    endif()

    if(DEFINED PARA_INCLUDE_DIRS AND PARA_INCLUDE_DIRS)
        target_include_directories(${PARA_NAME} PUBLIC ${PARA_INCLUDE_DIRS})
    endif()

    if(DEFINED PARA_PRIVATE_INCLUDE_DIRS AND PARA_PRIVATE_INCLUDE_DIRS)
        target_include_directories(${PARA_NAME} PRIVATE ${PARA_PRIVATE_INCLUDE_DIRS})
    endif()
    
    if(DEFINED PARA_OPTIONS)
        target_compile_options(${PARA_NAME} PUBLIC ${PARA_OPTIONS})
    endif()

    if(DEFINED PARA_PRIVATE_OPTIONS)
        target_compile_options(${PARA_NAME} PRIVATE ${PARA_PRIVATE_OPTIONS})
    endif()

    if(DEFINED PARA_FEATURES)
        target_compile_features(${PARA_NAME} PUBLIC ${PARA_FEATURES})
    endif()

    if(DEFINED PARA_PRIVATE_FEATURES)
        target_compile_features(${PARA_NAME} PRIVATE ${PARA_PRIVATE_FEATURES})
    endif()
    
    if(NOT PARA_NO_INSTALL)
        # Install target
        if(PARA_ISPLUGIN)
            INSTALL_TARGET(NAME ${PARA_NAME}
                ISPLUGIN
                PUBLIC_HEADER ${PARA_INSTALL_PUBLIC_HEADER}
                INCLUDES ${PARA_INSTALL_INCLUDES}
                INSTALL_PLUGIN_LIBRARY_DIR ${PARA_INSTALL_PLUGIN_LIBRARY_DIR})
        elseif(PARA_ISEXE)
            INSTALL_TARGET(NAME ${PARA_NAME}
                ISEXE
                PUBLIC_HEADER ${PARA_INSTALL_PUBLIC_HEADER}
                INCLUDES ${PARA_INSTALL_INCLUDES})
        else()
            INSTALL_TARGET(NAME ${PARA_NAME}
                EXPORT_NAME ${PARA_INSTALL_EXPORT_NAME}
                NAMESPACE ${PARA_INSTALL_NAMESPACE}
                PUBLIC_HEADER ${PARA_INSTALL_PUBLIC_HEADER}
                INCLUDES ${PARA_INSTALL_INCLUDES}
                INSTALL_CMAKE_CONFIG_IN_FILE ${PARA_INSTALL_CMAKE_CONFIG_IN_FILE})
        endif()
    endif()
endfunction()

# 增加插件目标
# 参数：
#  NAME                    目标名
#  OUTPUT_DIR              目标生成目录
#  VERSION                 版本
#  ANDROID_SOURCES_DIR     Android 源码文件目录
#  [必须]SOURCE_FILES       源文件（包括头文件，资源文件等）
#  INCLUDE_DIRS            包含目录
#  PRIVATE_INCLUDE_DIRS    私有包含目录
#  LIBS                    公有依赖库
#  PRIVATE_LIBS            私有依赖库
#  DEFINITIONS             公有宏定义
#  PRIVATE_DEFINITIONS     私有宏宏义
#  OPTIONS                 公有选项
#  PRIVATE_OPTIONS         私有选项
#  FEATURES                公有特性
#  PRIVATE_FEATURES        私有特性
#  INSTALL_DIR             插件库安装目录，默认：plugins 。
#                          注意：只接受相对路径。绝对路径时，翻译资源前缀会有问题。
function(ADD_PLUGIN_TARGET)
    SET(MUT_PARAS
        SOURCE_FILES            #源文件（包括头文件，资源文件等）
        INCLUDE_DIRS            #包含目录
        PRIVATE_INCLUDE_DIRS    #私有包含目录
        LIBS                    #公有依赖库
        PRIVATE_LIBS            #私有依赖库
        DEFINITIONS             #公有宏定义
        PRIVATE_DEFINITIONS     #私有宏宏义
        OPTIONS                 #公有选项
        PRIVATE_OPTIONS         #私有选项
        FEATURES                #公有特性
        PRIVATE_FEATURES        #私有特性
        )
    cmake_parse_arguments(PARA ""
        "NAME;OUTPUT_DIR;VERSION;ANDROID_SOURCES_DIR;INSTALL_DIR"
        "${MUT_PARAS}"
        ${ARGN})
    if(NOT DEFINED PARA_SOURCE_FILES)
        message(FATAL_ERROR "Use:
            ADD_TARGET
                [NAME name]
                SOURCE_FILES source1 [source2 ... header1 ...]]
                [LIBS lib1 [lib2 ...]]
                [PRIVATE_LIBS lib1 [lib2 ...]]
                [INCLUDE_DIRS [include_dir1 ...]]
                [PRIVATE_INCLUDE_DIRS [include_dir1 ...]]
                [DEFINITIONS [definition1 ...]]
                [PRIVATE_DEFINITIONS [defnitions1 ...]]
                [OUTPUT_DIR output_dir]
                [PRIVATE_OPTIONS option1 [option2 ...]]
                [OPTIONS option1 [option2 ...]]
                [FEATURES feature1 [feature2 ...]]
                [PRIVATE_FEATURES feature1 [feature2 ...]]
                [VERSION version]
                [ANDROID_SOURCES_DIR android_source_dir]")
        return()
    endif()
    
    if(NOT DEFINED PARA_OUTPUT_DIR)
        set(PARA_OUTPUT_DIR ${CMAKE_BINARY_DIR}/plugins)
    endif()
    
    if(NOT DEFINED PARA_INSTALL_DIR)
        set(PARA_INSTALL_DIR plugins)
    endif()
    
    ADD_TARGET(NAME ${PARA_NAME}
        ISPLUGIN
        OUTPUT_DIR ${PARA_OUTPUT_DIR}
        VERSION ${PARA_VERSION}
        ANDROID_SOURCES_DIR ${PARA_ANDROID_SOURCES_DIR}
        SOURCE_FILES ${PARA_SOURCE_FILES}
        LIBS ${PARA_LIBS}
        PRIVATE_LIBS ${PARA_PRIVATE_LIBS}
        DEFINITIONS ${PARA_DEFINITIONS}
        PRIVATE_DEFINITIONS ${PARA_PRIVATE_DEFINITIONS}
        OPTIONS ${PARA_OPTIONS}
        PRIVATE_OPTIONS ${PARA_PRIVATE_OPTIONS}
        FEATURES ${FEATURES}
        PRIVATE_FEATURES ${PRIVATE_FEATURES}
        PRIVATE_INCLUDE_DIRS ${PARA_PRIVATE_INCLUDE_DIRS}
        INSTALL_PLUGIN_LIBRARY_DIR ${PARA_INSTALL_DIR}
        )
endfunction()
