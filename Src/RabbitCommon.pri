QT += core gui xml
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets network

CONFIG *= c++11 link_pkgconfig create_prl link_prl

isEmpty(BUILD_VERSION): error("Please set BUILD_VERSION")
#VERSION=$$replace(BUILD_VERSION, v,)
#win32{
#    VERSION=$$split(VERSION, -)
#    VERSION=$$first(VERSION)
#}
win32: DEFINES += WINDOWS
unix: DEFINES += UNIX
android{
    DEFINES += BUILD_ARCH=\"\\\"$${ANDROID_TARGET_ARCH}\\\"\"
} else: win32 {
    contains(QMAKE_TARGET.arch, x86_64) {
        DEFINES += BUILD_ARCH=\"\\\"x86_64\\\"\"
    } else {
        DEFINES += BUILD_ARCH=\"\\\"x86\\\"\"
    }
} else {
    DEFINES += BUILD_ARCH=\"\\\"$$system(uname -p)\\\"\"
}
CONFIG(debug, debug|release): DEFINES *= _DEBUG
DEFINES += BUILD_PLATFORM=\"\\\"$${QMAKE_PLATFORM}\\\"\"

#Support windows xp
mingw: DEFINES += "_WIN32_WINNT=0x0501"
msvc {
    QMAKE_LFLAGS *= /SUBSYSTEM:WINDOWS",5.01"
    QMAKE_CXXFLAGS += "/utf-8"
}

INCLUDEPATH += $$PWD $$PWD/export

CONFIG(staticlib): CONFIG*=static
CONFIG(static): DEFINES *= RABBITCOMMON_STATIC_DEFINE
else: DEFINES *= RabbitCommon_EXPORTS

!equals(WITH_GUI, "OFF") {
    DEFINES *= HAVE_GUI
    SOURCES += $$PWD/RabbitCommonStyle.cpp \
        $$PWD/RabbitRecentMenu.cpp
    INSTALL_HEADERS += $$PWD/RabbitCommonStyle.h \
        $$PWD/RabbitRecentMenu.h
}

!equals(BUILD_UPDATE, "OFF"){
    DEFINES *= HAVE_UPDATE
    SOURCES += $$PWD/FrmUpdater/FrmUpdater.cpp
    INSTALL_HEADERS += $$PWD/FrmUpdater/FrmUpdater.h
    FORMS += $$PWD/FrmUpdater/FrmUpdater.ui
    BUILD_ADMINAUTHORISER = ON
}
!equals(BUILD_ABOUT, "OFF"){
    DEFINES *= HAVE_ABOUT
    SOURCES += $$PWD/DlgAbout/DlgAbout.cpp
    INSTALL_HEADERS += $$PWD/DlgAbout/DlgAbout.h
    FORMS += $$PWD/DlgAbout/DlgAbout.ui
}
!equals(BUILD_ADMINAUTHORISER, "OFF"){
    DEFINES *= HAVE_ADMINAUTHORISER
    SOURCES += $$PWD/AdminAuthoriser/adminauthoriser.cpp
    HEADERS += $$PWD/AdminAuthoriser/adminauthoriser.h \
               $$PWD/AdminAuthoriser/adminauthorization_p.h
    win32: SOURCES += $$PWD/AdminAuthoriser/adminauthorization_win.cpp
    else:mac: SOURCES += $$PWD/AdminAuthoriser/adminauthorization_mac.cpp
    else:unix:!emscripten:!android: SOURCES += $$PWD/AdminAuthoriser/adminauthorization_x11.cpp
    else: SOURCES += $$PWD/AdminAuthoriser/adminauthorization_dummy.cpp

    win32 {
        QT += winextras
        LIBS += -lAdvapi32 -lOle32 -lShell32 -lnetapi32 -lWs2_32
    } else:mac {
        QT += macextras
        LIBS += -framework Security
    } else:unix:!android {
        QT += dbus
        LIBS += -lutil
    }
}
isEmpty(OpenSSL_DIR): warning("Please set OpenSSL_DIR")
else {
    DEFINES *= HAVE_OPENSSL
    SOURCES += EvpAES.cpp
    HEADERS += EvpAES.h
    INSTALL_HEADERS += 
    LIBS += $$OpenSSL_DIR/lib/libssl.so \
        $$OpenSSL_DIR/lib/libcrypto.so 
}
!equals(BUILD_QUIWidget, "OFF"){
    SOURCES += $$PWD/QUIWidget/QUIWidget.cpp
    INSTALL_HEADERS += $$PWD/QUIWidget/QUIWidget.h
    RESOURCES += $$PWD/QUIWidget/Resource/QUIWidget.qrc
    CONFIG(debug, debug|release):RESOURCES += $$PWD/QUIWidget/Resource/QUIWidgetQss.qrc
}

!isEmpty(Log4Qt_DIR){
    DEFINES *= HAVE_LOG4QT
    LIBS *= -L$${Log4Qt_DIR}/lib -llog4qt
    INCLUDEPATH *= $${Log4Qt_DIR}/include
}

!isEmpty(log4cplus_DIR){
    DEFINES *= HAVE_LOG4CPLUS
    LIBS += -L$${log4cplus_DIR} -llog4cplus

    # Install log4cplus configure files
    log4cplus.target = log4cplus
    log4cplus.files = $$PWD/etc/log4config.conf
    android: log4cplus.path = $$system_path($${PREFIX}/assets/etc)
    else: log4cplus.path = $$system_path($${PREFIX}/etc)
    log4cplus.CONFIG += directory no_check_exist
    INSTALLS += log4cplus
}

SOURCES += \
    $$PWD/RabbitCommonLog.cpp \
    $$PWD/RabbitCommonDir.cpp \
    $$PWD/RabbitCommonRegister.cpp \
    $$PWD/RabbitCommonTools.cpp \
    $$PWD/RabbitCommonEncrypt.cpp

INSTALL_HEADERS += \
    $$PWD/RabbitCommonLog.h \
    $$PWD/RabbitCommonTools.h \
    $$PWD/RabbitCommonDir.h \
    $$PWD/export/rabbitcommon_export.h \
    $$PWD/export/rabbitcommon_export_windows.h \
    $$PWD/export/rabbitcommon_export_linux.h \
    $$PWD/RabbitCommonEncrypt.h

HEADERS += $$INSTALL_HEADERS \
    $$PWD/RabbitCommonRegister.h

RESOURCES += \
    $$PWD/Resource/ResourceRabbitCommon.qrc

unix_install_script.target = unix_install_script
unix_install_script.files = $$PWD/../Install/install.sh
unix_install_script.path = $$system_path($${PREFIX}/install)
unix: INSTALLS += install_script

TRANSLATIONS_DIR=$$PWD
TRANSLATIONS_NAME=RabbitCommon
include($$PWD/../pri/Translations.pri)

android{
    !isEmpty(OpenSSL_DIR) : ANDROID_EXTRA_LIBS = $$OpenSSL_DIR/lib/libssl.so \
        $$OpenSSL_DIR/lib/libcrypto.so        
}

# Install style files
style.target = style
style.files = $$PWD/Resource/style/*
CONFIG(release, debug|release): style.files += $$PWD/QUIWidget/Resource/qss/*
android: style.path = $$system_path($${PREFIX}/assets/data/style)
else: style.path = $$system_path($${PREFIX}/data/style)
style.CONFIG += directory no_check_exist
INSTALLS += style
