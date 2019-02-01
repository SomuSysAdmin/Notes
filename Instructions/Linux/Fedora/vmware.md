# VMware Workstation 15.0.2

## VMware Kernel Module Installation
### Kernel Module Updater - Modules must be compiled
[Source of Answer](https://askubuntu.com/questions/292049/vmware-workstation-error-modules-must-be-compiled-how-to-fix)

Failed to run '/usr/bin/vmware-modconfig'

To solve, run:
```
sudo vmware-modconfig --console --install-all
```

### Unable to install all Modules
Error:
```
# sudo vmware-modconfig --console --install-all
[AppLoader] GLib does not have GSettings support.
Stopping vmware (via systemctl):                           [  OK  ]
make: Entering directory '/tmp/modconfig-cPSlpm/vmmon-only'
Using kernel build system.
/usr/bin/make -C /lib/modules/4.19.14-300.fc29.x86_64/build/include/.. SUBDIRS=$PWD SRCROOT=$PWD/. \
  MODULEBUILDDIR= modules
make[1]: Entering directory '/usr/src/kernels/4.19.14-300.fc29.x86_64'
Makefile:962: *** "Cannot generate ORC metadata for CONFIG_UNWINDER_ORC=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel".  Stop.
make[1]: Leaving directory '/usr/src/kernels/4.19.14-300.fc29.x86_64'
make: *** [Makefile:110: vmmon.ko] Error 2
make: Leaving directory '/tmp/modconfig-cPSlpm/vmmon-only'
make: Entering directory '/tmp/modconfig-cPSlpm/vmnet-only'
Using kernel build system.
/usr/bin/make -C /lib/modules/4.19.14-300.fc29.x86_64/build/include/.. SUBDIRS=$PWD SRCROOT=$PWD/. \
  MODULEBUILDDIR= modules
make[1]: Entering directory '/usr/src/kernels/4.19.14-300.fc29.x86_64'
Makefile:962: *** "Cannot generate ORC metadata for CONFIG_UNWINDER_ORC=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel".  Stop.
make[1]: Leaving directory '/usr/src/kernels/4.19.14-300.fc29.x86_64'
make: *** [Makefile:110: vmnet.ko] Error 2
make: Leaving directory '/tmp/modconfig-cPSlpm/vmnet-only'
Unable to install all modules.  See log for details.
```

Solution:
```
# dnf -y install elfutils-libelf-devel
```

## VMware won't open OVA files
### Issue with OVFtool
```
$ ovftool
/usr/lib/vmware-ovftool/ovftool.bin: error while loading shared libraries: libnsl.so.1: cannot open shared object file: No such file or directory
```

Solution
```
$ sudo dnf install libnsl
```
## VMware can't find Kernel Header

Solution:
```
# dnf -y install kernel-devel
```
