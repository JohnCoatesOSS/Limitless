#include <unistd.h>

int main(int argc, char *argv[]) {
    setuid(0);
    setgid(0);

    if (argc < 2 || argv[1][0] != '/')
        argv[0] = "/usr/bin/dpkg";
    else {
        --argc;
        ++argv;
    }

    execv(argv[0], argv);
    return 1;
}
