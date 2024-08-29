#ifndef GAMINGMOUSE_PROCESS_H
#define GAMINGMOUSE_PROCESS_H

#include <sys/sysctl.h>

typedef struct ProcessInfo {
    pid_t ppid;
    pid_t pgid;
} ProcessInfo;

ProcessInfo getProcessInfo(pid_t pid);

#endif /* GAMINGMOUSE_PROCESS_H */
