#include <unistd.h>

int main(int argc, char *argv[]) {
    setuid(0);
    setgid(0);
    argv[0] = "/usr/bin/dpkg";
    execv(argv[0], argv);
    return 1;
}
