# auto generate dump upon crash
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
