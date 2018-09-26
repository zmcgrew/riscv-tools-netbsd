# Building NetBSD on the RISC-V #

## Required Build Dependencies ##

* gmake -- For the GNU tools, NetBSD will use it's own make
* bison
* flex
* gsed
* gawk
* autoconf
* automake
* pkg-config
* libtool
* bash

#### NetBSD pkg_add ####
```
pkg_add gmake bison flex gsed gawk autoconf automake pkg-config libtool bash
```

## Fetch the toolchain and simulator source ##

  While the newer version from
  [riscv-tools](https://github.com/riscv/riscv-tools) will probably
  work, the one that I've tested and built with is can be found in
  [riscv-tools-netbsd](https://github.com/zmcgrew/riscv-tools-netbsd). At
  the very least you'll probably want the `netbsd_build.sh` script
  from there to simplify building the tools.
  
  ```
  git clone --depth 1 https://github.com/zmcgrew/riscv-tools-netbsd.git ~/riscv-tools-netbsd
  cd riscv-tools-netbsd
  ```

### Setup your path for the tools ###
You may want to put this in your shell's rc file.
```
PATH=$PATH:~/.riscv-tools/bin
export PATH
```

### Build the simulator *(And the 1st toolchain)* ###
```
./netbsd_build.sh simulator
```
### Build the toolchain for the kernel ###
```
./netbsd_build.sh crosstools
```
### Fetch the NetBSD RISC-V branch ###
```
mkdir ~/netbsd && cd ~/netbsd
git clone --depth 1 -b riscv https://github.com/zmcgrew/src.git src
ln -s src/build_riscv.sh ./build_riscv.sh
```
### Build the NetBSD tools ###
```
cd ~/netbsd
./build_riscv.sh tools
```
### Build the NetBSD kernel ###
```
cd ~/netbsd
./build_riscv.sh kernel=GENERIC
```
### Boot the NetBSD kernel ###
```
spike bbl
```
