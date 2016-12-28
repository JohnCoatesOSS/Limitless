#define _GNU_SOURCE
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <inttypes.h>
#include <errno.h>
#include <string.h>

#ifndef PKGLIB_MISSING_H
#define PKGLIB_MISSING_H

extern "C" {
	void *memrchr(const void *s, int c, size_t n);
	void *rawmemchr(const void *s, int c);
	char *strchrnul(const char *s, int c);
	int getservbyport_r(int port, const char *prots, struct servent *se, char *buf, size_t buflen, struct servent **res);
}

typedef void (*sighandler_t)(int);

extern char **environ;

#define AI_IDN 0x0040

#endif

