- [Windows capture dump upon crash](#windows-capture-dump-upon-crash)
  - [bat script auto generate](#bat-script-auto-generate)
  - [ProcDump](#procdump)
  - [code into app](#code-into-app)
- [Linux capture core dump](#linux-capture-core-dump)
  - [传统 gdb 调试](#传统-gdb-调试)
  - [更现代的崩溃报告系统及调试](#更现代的崩溃报告系统及调试)
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
- [check if exe/dll matches pdb](#check-if-exedll-matches-pdb)
- [proxmox macOS VM config example](#proxmox-macos-vm-config-example)

# Windows capture dump upon crash

## bat script auto generate

https://github.com/Zvicii/NoteBook/blob/main/enable_full_memory_dump.bat  
执行这个 bat 脚本，崩溃时 crash 会生成在脚本中指定的目录

## ProcDump

https://learn.microsoft.com/zh-cn/sysinternals/downloads/procdump  
使用示例：
`procdump -e -x path/to/save/dump process_to_start process_parameters`

## code into app

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

# Linux capture core dump

## 传统 gdb 调试

要让系统生成 core 文件，需要做以下操作：  
`ulimit -c unlimited （必选）`  
设置 core 文件大小，unlimited 代表无穷大  
临时的操作，当前 shell 生效，重启或新开终端无效，除非写到.bashrc 里  
`sudo service apport stop` （必选）  
关闭 ubuntu 系统崩溃上报，否则不会生成核心转储  
临时的操作，重启失效，若要永久操作，需要修改`/etc/default/apport`，修改为 enabled=0  
修改 core 文件样式 （可选）  
不修改的话默认 core  
`echo "core.%p.%e" > /proc/sys/kernel/core_pattern`, 具体命名规则详见 man 5 core

## 更现代的崩溃报告系统及调试

安装 systemd-coredump  
`sudo apt install systemd-coredump`  
core dumps 存储在/var/lib/systemd/coredump  
客户端工具 `coredumpctl`  
`coredumpctl` 【列出所有 core dumps】  
`coredumpctl gdb` 【打开最近的 core dumps】  
`coredumpctl gdb 1234`【打开 pid=1234 进程最近的 core dumps】

# RPATH under macosx

最佳实践：  
1、所有的动态库 INSTALL_NAME_DIR 都设置为@rpath (cmake 已默认配置，所以不需要再显式配置 INSTALL_NAME_DIR property, 见https://cmake.org/cmake/help/latest/prop_tgt/MACOSX_RPATH.html#prop_tgt:MACOSX_RPATH)  
2、可执行文件和动态库的 INSTALL_RPATH 设为其所要查找的目录, 比如@loader_path;@loader_path/../Frameworks(注意, 不要在 INSTALL_RPATH 中配置@rpath, ld 会在加载动态库时自动添加@rpath, 如果@rpath 为空, 又在 INSTALL_RPATH 中添加了@rpath 会导致路径解析失败)

```
set_target_properties(${TARGET_NAME} PROPERTIES
  BUILD_WITH_INSTALL_RPATH ON
  INSTALL_RPATH "@loader_path;@loader_path/../lib"
)
```

# macOS Codesign

1、首先需要一份 developer id 证书, 导出证书安装到别的设备的话, 要用 p12 格式导出
2、`codesign --timestamp -o runtime -f -s "cert name" -v ${\_install_excutable_path} --deep`  
3、`security find-identity -p codesigning` 查看可用证书

若 cmake generator 为 xcode 则无需显式调用 codesign, 如果生成的是 bundle 则需要加上--deep 参数

```
set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--deep"
    )
```

note:  
1、所有证书的信任要设置成系统默认，如果改成始终信任会导致 `unable to build chain to self-signed root`  
2、如果信任已经是系统默认, 仍然提示 `unable to build chain to self-signed root`, 说明对应版本的 Apple WWDRCA 未安装  
3、Apple WWDRCA 版本要和签发你证书的版本匹配，看证书的签发者名称-组织单位栏，https://www.apple.com/certificateauthority/  
4、Apple WWDRCA 证书一定要放在系统证书不能放在登录证书  
5、将开发者证书放在登录证书中，右键登录可以更改钥匙串"登录"，把两个锁定条件关掉就不会锁定了

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

you can use link group to avoid worrying about link order

```
target_link_libraries(${PROJECT_NAME} -Wl,--start-group)
target_link_libraries(${TARGET_NAME} z A)
target_link_libraries(${PROJECT_NAME} -Wl,--end-group)
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

# check if exe/dll matches pdb

https://www.debuginfo.com/tools/chkmatch.html

```
ChkMatch -c lib.dll lib.pdb
```

# proxmox macOS VM config example

```
agent: 1
args: -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -cpu host,kvm=on,vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc
balloon: 0
bios: ovmf
bootdisk: ide2
cores: 32
ide0: local:iso/BigSur-full.img,cache=unsafe,size=14G
ide2: local:iso/OpenCore-v10.iso,cache=unsafe
machine: q35
memory: 32768
name: macOS-NeIM-02
net0: vmxnet3=FE:34:E3:AB:33:AB,bridge=vmbr0
numa: 0
onboot: 1
ostype: other
scsihw: virtio-scsi-pci
smbios1: uuid=aae83434-76bc-4585-971f-0d4a3a7326c7
sockets: 1
vga: vmware
virtio0: ssd002:vm-150-disk-0,cache=unsafe,discard=on,size=700G
vmgenid: d039aac7-9130-4f31-8755-a7719e8ee80e
```
