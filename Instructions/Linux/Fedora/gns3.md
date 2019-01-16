# VPCS Installation in Fedora
```
cd /tmp
svn checkout http://svn.code.sf.net/p/vpcs/code/trunk vpcs
cd vpcs/src
rgetopt='int getopt(int argc, char *const *argv, const char *optstr);'
sed -i "s/^int getopt.*/$rgetopt/" getopt.h
unset -v rgetopt
sed -i 's/i386/x86_64/' Makefile.linux
sed -i 's/-s -static//' Makefile.linux
./mk.sh 64
sudo install -m 755 vpcs /usr/local/bin
```

This will install VPCSv0.8c :
```
VPCS[1]> sh ver

Welcome to Virtual PC Simulator, version 0.8c
Dedicated to Daling.
Build time: Jan 16 2019 04:09:02
Copyright (c) 2007-2015, Paul Meng (mirnshi@gmail.com)
All rights reserved.

VPCS is free software, distributed under the terms of the "BSD" licence.
Source code and license can be found at vpcs.sf.net.
For more information, please visit wiki.freecode.com.cn.
```
