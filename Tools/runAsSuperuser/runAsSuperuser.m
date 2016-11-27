//
//  main.m
//  runAsSuperuser
//
//

#import <Foundation/Foundation.h>
#import <sysexits.h>
#import <launch.h>

char **dpkgArgvWithDebugArgumentAppended(int argc, char *argv[]) {
    char **newArgv = (char **)malloc((argc + 2) * sizeof(*newArgv));
    if (!newArgv) {
        NSLog(@"failed to malloc enough memory for newArgv!");
        return nil;
    }
    
    memmove(newArgv, argv, sizeof(*newArgv) * argc);
    const char *debugArgument = "--debug=2000";
    NSLog(@"appending %s to dpkg", debugArgument);
    // make a copy so we're not point to stack memory
    newArgv[argc] = strdup(debugArgument);
    newArgv[argc + 1] = 0;

    return newArgv;
}

int main(int argc, char *argv[]) {
    NSLog(@"runAsSuperuser printing arguments received");
    int index = 0;
    char *argument = argv[index];
    while (argument != 0) {
        argument = argv[index];
        NSLog(@"%i: %s", index, argument);
        index += 1;
    }
    
    setuid(0);
    setgid(0);
    
    if (argc < 2 || argv[1][0] != '/'){
        argv[0] = (char *)"/usr/bin/dpkg";
//        argv = dpkgArgvWithDebugArgumentAppended(argc, argv);
    } else {
        --argc;
        ++argv;
    }
    
//    int fd = open("/var/mobile/Library/Logs/Cydia/dpkg.log", O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
//    dup2(fd, 1); // stdout
//    dup2(fd, 2);  // stderr
//    close(fd);
    
    execv(argv[0], argv);
    
    // process should have been overlayed and this will not execute
    // unless command being run was not found
    return EX_UNAVAILABLE;
}
