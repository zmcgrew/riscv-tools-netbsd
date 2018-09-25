#!/usr/bin/env bash

#Load NMAKES from environment, or figure it out
if [ "x$NMAKES" = "x" ]; then
  NMAKES=`sysctl hw.ncpuonline | sed 's/hw.ncpuonline = //g'`
  NMAKES=`expr $NMAKES \* 2`
fi

MAKES="-j${NMAKES}"

openocd() {
    cd "${TOP}/riscv-openocd"
    rm -rf build-openocd
    mkdir build-openocd
    ./bootstrap &&
    cd build-openocd &&
    ../configure \
        --prefix=${RISCV} \
        --enable-remote-bitbang \
        --enable-jtag_vpi \
        --disable-jlink \
        --disable-werror &&
        gmake ${MAKES} && gmake install
}

fesvr() {
    cd "${TOP}/riscv-fesvr"
    rm -rf build-fesvr
    mkdir build-fesvr
    cd build-fesvr
    ../configure \
        --prefix=${RISCV} &&
        gmake ${MAKES} && gmake ${MAKES} install
}

spike() {
    fesvr
    cd "${TOP}/riscv-isa-sim"
    rm -rf build-isa
    mkdir build-isa
    cd build-isa
    alias sed="gsed"
    ../configure \
        --prefix=${RISCV} \
        --with-fesvr=${RISCV} &&
        gmake ${MAKES} && gmake ${MAKES} install
}

binutils() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-binutils-gdb"
    rm -rf build-binutils
    mkdir build-binutils
    cd build-binutils
    ../configure \
        --target=riscv64--netbsd \
        --with-arch=rv64 \
        --with-abi=lp64d \
        --disable-gdb \
        --prefix=${RISCV} \
        --with-guile=no \
        --disable-sim \
        --enable-tls \
        --disable-intl \
        --disable-werror &&
    gmake ${MAKES} && gmake ${MAKES} install
}

binutils-newlib() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-binutils-gdb"
    rm -rf build-binutils
    mkdir build-binutils
    cd build-binutils
#--disable-gdb
    ../configure \
        --target=riscv64-unknown-elf \
        --with-arch=rv64imafd \
        --with-abi=lp64d \
        --prefix=${RISCV} \
        --with-guile=no \
        --disable-sim \
        --enable-tls \
        --disable-intl \
        --disable-werror &&
    gmake ${MAKES} && gmake ${MAKES} install
}

gcc-noheaders() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-gcc" &&
        rm -rf build-gcc &&
        mkdir build-gcc &&
        cd build-gcc &&
        ../configure \
            --target=riscv64--netbsd \
            --with-arch=rv64imafd \
            --with-abi=lp64d \
            --prefix=${RISCV} \
            --without-headers \
            --disable-multilib \
            --disable-werror \
            --disable-shared \
            --enable-static \
            --disable-threads \
            --enable-tls \
            --enable-languages=c,c++ \
            --disable-libatomic \
            --disable-libmudflap \
            --disable-libssp \
            --disable-libquadmath \
            --disable-libgomp \
            --disable-nls &&
        echo "Preparing to call gmake..." &&
        gmake ${MAKES} all-gcc &&
        echo "Preparing to install gcc in $RISCV" &&
        gmake ${MAKES} install-gcc
#       cd "${RISCV}/bin" &&
#        echo "Creating symlinks to match NetBSD tool names" &&
#       for i in $(ls riscv64-netbsd-elf-*) ; do ln -s $i riscv64--netbsd-${i##riscv64-netbsd-elf-} ; done
}

gcc-stage1() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-gcc"
    rm -rf build-gcc
    mkdir build-gcc
    cd build-gcc
    ../configure \
        --target=riscv64-unknown-elf \
        --with-arch=rv64imafd \
        --with-abi=lp64d \
        --prefix=${RISCV} \
        --without-headers \
        --with-newlib \
        --disable-multilib \
        --disable-werror \
        --disable-shared \
        --disable-threads \
        --enable-tls \
        --enable-languages=c,c++ \
        --disable-libatomic \
        --disable-libmudflap \
        --disable-libssp \
        --disable-libquadmath \
        --disable-libgomp \
        --disable-nls &&
        gmake ${MAKES} all-gcc &&
        gmake ${MAKES} install-gcc
}

newlib() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-newlib"
    rm -rf build-newlib
    mkdir build-newlib
    cd build-newlib
    ../configure \
        --target=riscv64-unknown-elf \
        --prefix=${RISCV} \
        --enable-newlib-io-long-double \
        --enable-newlib-io-long-long \
        --enable-newlib-io-c99-formats &&
    gmake && gmake install
}

gcc-stage2() {
    cd "${TOP}/riscv-gnu-toolchain/riscv-gcc"
    rm -rf build-gcc
    mkdir build-gcc
    cd build-gcc
    ../configure \
        --disable-multilib \
        --target=riscv64-unknown-elf \
        --with-arch=rv64imafd \
  --with-abi=lp64d \
        --prefix=${RISCV} \
        --with-headers=${RISCV}/riscv64-unknown-elf/include \
        --with-newlib \
        --disable-werror \
        --disable-shared \
        --disable-threads \
        --enable-tls \
        --enable-languages=c,c++ \
        --disable-libatomic \
        --disable-libmudflap \
        --disable-libssp \
        --disable-libquadmath \
        --disable-libgomp \
        --disable-nls &&
        gmake ${MAKES} &&
  gmake ${MAKES} install
}

gcc() {
    gcc-stage1
    newlib
    gcc-stage2
}

crosstools() {
    binutils
    gcc-noheaders
}

pk() {
    cd "${TOP}/riscv-pk"
    rm -rf build-pk
    mkdir build-pk
    cd build-pk
    PATH=${PATH}:${RISCV}/bin
#    CFLAGS="-nostdlib -ffreestanding"
    CPP="riscv64-unknown-elf-cpp"
    CC="riscv64-unknown-elf-gcc"
    OBJCOPY="riscv64-unknown-elf-objcopy"
    READELF="riscv64-unknown-elf-readelf"
    RANLIB="riscv64-unknown-elf-ranlib"
#    LD="riscv64-unknown-elf-ld"
    GCC="yes"
    export PATH
#    export CFLAGS
    export CXX=
    export CC=
#    export OBJCOPY
#    export READELF
#    export RANLIB
#    export GCC
#    export LD
    printenv CFLAGS
    ../configure \
        --prefix=${RISCV} \
        --host=riscv64-unknown-elf \
        --enable-logo &&
#        LDFLAGS=" -nostartfiles -nostdlib -static " &&
        gmake ${MAKES} &&
        gmake ${MAKES} install
}

bbl-netbsd() {
    cd "${TOP}/riscv-pk"
    rm -rf build-pk
    mkdir build-pk
    cd build-pk
    PATH=${PATH}:${RISCV}/bin
#    CFLAGS="-nostdlib -ffreestanding"
    CPP="riscv64-unknown-elf-cpp"
    CC="riscv64-unknown-elf-gcc"
    OBJCOPY="riscv64-unknown-elf-objcopy"
    READELF="riscv64-unknown-elf-readelf"
    RANLIB="riscv64-unknown-elf-ranlib"
    GCC="yes"
    export PATH
#    export CFLAGS
    export CPP=
    export CC=
#    export OBJCOPY
#    export READELF
#    export RANLIB
#    export GCC
    printenv CFLAGS
#        --enable-logo=yes \
#        --enable-print-device-tree \
    ../configure \
        --prefix=${RISCV} \
        --host=riscv64-unknown-elf \
        --with-payload="${HOME}/netbsd/rv64/obj/sys/arch/riscv/compile/GENERIC/netbsd" &&
        LDFLAGS=" -nostartfiles -nostdlib -static " &&
        gmake ${MAKES} &&
        gmake ${MAKES} install
}

simulator() {
    binutils-newlib
    gcc
    openocd
    spike
    pk
}

clean() {
    rm -rf "${TOP}/riscv-openocd/build-openocd"
    rm -rf "${TOP}/riscv-fesvr/build-fesvr"
    rm -rf "${TOP}/riscv-isa-sim/build-isa"
    rm -rf "${TOP}/riscv-gnu-toolchain/riscv-binutils-gdb/build-binutils"
    rm -rf "${TOP}/riscv-gnu-toolchain/riscv-gcc/build-gcc"
    rm -rf "${TOP}/riscv-gnu-toolchain/riscv-newlib/build-newlib"
    rm -rf "${TOP}/riscv-pk/build-pk"
}

TOP=$(pwd)
RISCV=${RISCV:="${HOME}/.riscv-tools"}

if [ "x$@" = "x" ]; then
    echo "No command specified."
    echo "Please specify one of: "
    cat <<EOF
    simulator  -- Build the spike simulator and supporting tools
    crosstools -- Build the toolchain for compiling NetBSD
    clean      -- Delete the build directories from the above commands
EOF
    exit 1
fi

$@
