#include <cstdio>
#include <cstdlib>

#include <errno.h>
#include <sysexits.h>
#include <unistd.h>

#include <launch.h>

#include <Menes/Function.h>

typedef Function<void, const char *, launch_data_t> LaunchDataIterator;

void launch_data_dict_iterate(launch_data_t data, LaunchDataIterator code) {
    launch_data_dict_iterate(data, [](launch_data_t value, const char *name, void *baton) {
        (*static_cast<LaunchDataIterator *>(baton))(name, value);
    }, &code);
}

int main(int argc, char *argv[]) {
    auto request(launch_data_new_string(LAUNCH_KEY_GETJOBS));
    auto response(launch_msg(request));
    launch_data_free(request);

    _assert(response != NULL);
    _assert(launch_data_get_type(response) == LAUNCH_DATA_DICTIONARY);

    int parent(getppid());

    bool cydia(false);

    launch_data_dict_iterate(response, [=, &cydia](const char *name, launch_data_t value) {
        if (launch_data_get_type(response) != LAUNCH_DATA_DICTIONARY)
            return;

        auto integer(launch_data_dict_lookup(value, LAUNCH_JOBKEY_PID));
        if (integer == NULL || launch_data_get_type(integer) != LAUNCH_DATA_INTEGER)
            return;

        auto pid(launch_data_get_integer(integer));
        if (pid != parent)
            return;

        auto string(launch_data_dict_lookup(value, LAUNCH_JOBKEY_PROGRAM));
        if (string == NULL || launch_data_get_type(string) != LAUNCH_DATA_STRING)
            return;

        auto program(launch_data_get_string(string));
        if (program == NULL)
            return;

        if (strcmp(program, "/Applications/Cydia.app/Cydia") == 0)
            cydia = true;
    });

    if (!cydia) {
        fprintf(stderr, "thou shalt not pass\n");
        return EX_NOPERM;
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
    return EX_UNAVAILABLE;
}
