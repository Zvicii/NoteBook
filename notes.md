- [Windows auto generate dump upon crash](#windows-auto-generate-dump-upon-crash)
- [RPATH under macosx](#rpath-under-macosx)
- [macOS Codesign](#macos-codesign)
- [Multiple gcc/g++ version control](#multiple-gccg-version-control)
- [link order is very strict under gcc](#link-order-is-very-strict-under-gcc)
- [hide libraries symbols](#hide-libraries-symbols)
- [get shared library exported symbols](#get-shared-library-exported-symbols)
- [Debug File Formats On Different Platforms](#debug-file-formats-on-different-platforms)
- [Check existence of member function or variable](#check-existence-of-member-function-or-variable)
- [Check gcc include path](#check-gcc-include-path)
- [Linux iterate over files and process them](#linux-iterate-over-files-and-process-them)
- [static link libstdc++](#static-link-libstdc)
- [static link libc++](#static-link-libc)
- [cmake build framework](#cmake-build-framework)

# Windows auto generate dump upon crash

```
#ifndef TESTS_APP_DUMP_H_
#define TESTS_APP_DUMP_H_
#include <windows.h>

#include <DbgHelp.h>
#include "extension/file_util/path_util.h"
#include "extension/strings/string_util.h"
#include "extension/time/time.h"

BOOL CALLBACK MyMiniDumpCallback(PVOID, const PMINIDUMP_CALLBACK_INPUT input, PMINIDUMP_CALLBACK_OUTPUT output) {
    if (input == NULL || output == NULL)
        return FALSE;

    BOOL ret = FALSE;
    switch (input->CallbackType) {
        case IncludeModuleCallback:
        case IncludeThreadCallback:
        case ThreadCallback:
        case ThreadExCallback:
            ret = TRUE;
            break;
        case ModuleCallback: {
            if (!(output->ModuleWriteFlags & ModuleReferencedByMemory)) {
                output->ModuleWriteFlags &= ~ModuleWriteModule;
            }
            ret = TRUE;
        } break;
        default:
            break;
    }

    return ret;
}

void WriteDump(EXCEPTION_POINTERS* exp, const std::wstring& path) {
    HANDLE h = ::CreateFile(
        path.c_str(), GENERIC_WRITE | GENERIC_READ, FILE_SHARE_WRITE | FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    MINIDUMP_EXCEPTION_INFORMATION info;
    info.ThreadId = ::GetCurrentThreadId();
    info.ExceptionPointers = exp;
    info.ClientPointers = NULL;

    MINIDUMP_CALLBACK_INFORMATION mci;
    mci.CallbackRoutine = (MINIDUMP_CALLBACK_ROUTINE)MyMiniDumpCallback;
    mci.CallbackParam = 0;

    MINIDUMP_TYPE mdt = (MINIDUMP_TYPE)(MiniDumpWithIndirectlyReferencedMemory | MiniDumpScanMemory);

    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), h, mdt, &info, NULL, &mci);
    ::CloseHandle(h);
}

LONG WINAPI MyUnhandledExceptionFilter(EXCEPTION_POINTERS* exp) {
    nbase::TimeStruct local_time;
    nbase::Time::Now().LocalExplode(&local_time);
    std::wstring file = nbase::StringPrintf(L"%04d%02d%02d_%02d%02d%02d.dmp", local_time.year, local_time.month, local_time.day_of_month,
        local_time.hour, local_time.minute, local_time.second);

    auto app_cur_dir = base::extension::GetCurrentExeDirectory();
    auto app_dump_path = nbase::UTF8ToUTF16(app_cur_dir);
    app_dump_path.append(L"/").append(file);

    WriteDump(exp, app_dump_path);

    return EXCEPTION_CONTINUE_SEARCH;
}

#endif  // TESTS_APP_DUMP_H_
```

```
int main(int argc, char* argv[]) {
    ::SetUnhandledExceptionFilter(MyUnhandledExceptionFilter);
    return 0;
}
```

# RPATH under macosx

最佳实践：  
1、所有的动态库 rpath 都设置为@rpath  
2、可执行文件的 rpath 设为其所要查找的目录，比如@loader_path;@loader_path/../Frameworks

```
set_target_properties(${TARGET_NAME} PROPERTIES
  BUILD_WITH_INSTALL_RPATH ON
  INSTALL_RPATH "@loader_path;@loader_path/../lib"
)
```

# macOS Codesign

1、首先需要一份 developer id 证书  
2、codesign -o runtime -f -s "cert name" -v ${\_install_excutable_path} --deep

若 cmake generator 为 xcode 则无需显式调用 codesign, 如果生成的是 bundle 则需要加上--deep 参数

```
set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--deep"
    )
```

# Multiple gcc/g++ version control

```
sudo apt install build-essential
sudo apt -y install gcc-7 g++-7 gcc-8 g++-8 gcc-9 g++-9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
sudo update-alternatives --config gcc
There are 3 choices for the alternative gcc (providing /usr/bin/gcc).

  Selection    Path            Priority   Status
------------------------------------------------------------
  0            /usr/bin/gcc-9   9         auto mode
  1            /usr/bin/gcc-7   7         manual mode
* 2            /usr/bin/gcc-8   8         manual mode
  3            /usr/bin/gcc-9   9         manual mode
Press <enter> to keep the current choice[*], or type selection number:
```

# link order is very strict under gcc

for example, cmake target A depends on zlib, the following cmake script works fine:

```cmake
target_link_libraries(${TARGET_NAME} A z)
```

however, if you put A before z, target A will result in undefined syntax error:

```cmake
target_link_libraries(${TARGET_NAME} z A) # will fail
```

# hide libraries symbols

There is no point to hide symbols from static libraries, just use them on sharead libraries.

```cmake
# linux or maxOS
add_compile_options(-fvisibility=hidden)
# this option only affect the current target.
# So you have to add this compile option to every libraries, static or dynamic,
# in order to hide symbols you dont want to export.

# under linux there is a handy `exclude-lib` link option to hide symbols imported from static libraries,
# so its ok not adding `-fvisibility=hidden` option to static libraries under linux,
# just exclude them when linking the final dynamic library.
add_link_options("LINKER:--exclude-libs,ALL")

# so we can use the following script
if(UNIX)
    if(NOT APPLE)
        add_link_options("LINKER:--exclude-libs,ALL" "LINKER:--as-needed")
        set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    endif()
    add_compile_options(-fvisibility=hidden)
endif()
```

# get shared library exported symbols

```
// linux
nm -D *.so | awk '{if($2=="T"){print $3}}'
// macOS
nm -g *.so | awk '{if($2=="T"){print $3}}'
```

# Debug File Formats On Different Platforms

https://docs.sentry.io/platforms/native/guides/crashpad/data-management/debug-files/file-formats/

# Check existence of member function or variable

```c++
#define define_has_member(member_name)                                        \
    template <typename T>                                                     \
    class has_member_##member_name {                                          \
        typedef char yes_type;                                                \
        typedef long no_type;                                                 \
        template <typename U>                                                 \
        static yes_type test(decltype(&U::member_name));                      \
        template <typename U>                                                 \
        static no_type test(...);                                             \
                                                                              \
    public:                                                                   \
        static constexpr bool value = sizeof(test<T>(0)) == sizeof(yes_type); \
    }
#define has_member(class_, member_name) has_member_##member_name<class_>::value
```

# Check gcc include path

```
gcc -xc -E -v -
gcc -xc++ -E -v -
```

# Linux iterate over files and process them

```bash
# 1
find . -name "*.txt" -exec bash -c 'echo "Processing {}";' \;
# 2
for i in *; do echo "Processing $i"; done
```

# static link libstdc++

```
target_link_options(${TARGET_NAME} PRIVATE -static-libgcc -static-libstdc++)
```

# static link libc++

```
target_link_options(${TARGET_NAME} PRIVATE -static -lc++abi)
```

# cmake build framework

```
add_library(dynamicFramework SHARED
            dynamicFramework.c
            dynamicFramework.h
)
set_target_properties(dynamicFramework PROPERTIES
  FRAMEWORK TRUE
  FRAMEWORK_VERSION A
  MACOSX_FRAMEWORK_IDENTIFIER com.cmake.dynamicFramework
  MACOSX_FRAMEWORK_INFO_PLIST Info.plist
  # "current version" in semantic format in Mach-O binary file
  VERSION 16.4.0
  # "compatibility version" in semantic format in Mach-O binary file
  SOVERSION 1.0.0
  PUBLIC_HEADER dynamicFramework.h
  XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
)
```
