#!/bin/bash
rm -f /var/lib/dpkg/info/"$1".prerm
rm -f /var/lib/dpkg/info/"$1".postrm
rm -f /var/lib/dpkg/info/"$1".preinst
rm -f /var/lib/dpkg/info/"$1".postinst
rm -f /var/lib/dpkg/info/"$1".extrainst_
