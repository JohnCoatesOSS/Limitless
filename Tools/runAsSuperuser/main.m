//
//  main.m
//  runAsSuperuser
//
//

#import <Foundation/Foundation.h>
#import <sysexits.h>

int main(int argc, char *argv[]) {
    NSLog(@"runAsSuperuser printing arguments received");
    for(int i=0; i< argc - 1; i++){
        NSLog(@"%s", argv[i]);
    }
    
    setuid(0);
    setgid(0);
    
    if (argc < 2 || argv[1][0] != '/')
        argv[0] = "/usr/bin/dpkg";
    else {
        --argc;
        ++argv;
    }
    
    execv(argv[0], argv);
    
    // process should have been overlayed and this will not execute
    // unless command being run was not found
    return EX_UNAVAILABLE;
}
