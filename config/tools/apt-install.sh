#!/bin/bash
# Copyright (c) Christopher Di Bella.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

set -e



apt_install() {
   echo "Installing system tools"
   # DISTRO=`lsb_release -a 2>&1 | egrep 'Distributor:\s+' | cut -d':' -f2 | tr -d '\t'`
   CODENAME=`lsb_release -a 2>&1 | egrep 'Codename:\s+' | cut -d':' -f2 | tr -d '\t'`

   # Find linux distro (kudos https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script)
   if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      DISTRO=$NAME
   elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      DISTRO=$(lsb_release -si)
   elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      DISTRO=$DISTRIB_ID
   elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      DISTRO=Debian
   else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      DISTRO=$(uname -s)
   fi

   # We need to know who runs non-root commands
   if [[ $1 == "" ]]; then
      echo "$0: ./$0 username"
      echo "`username` should be \"`whoami`\" or \"root\""
      exit 1
   fi

   if [[ $(id -u) -ne 0 ]]; then
      echo "$0: must be run as root"
      exit 1
   fi

   # if [[ $DISTRO == 'Ubuntu' ]]; then
      # GCC_LATEST_REPO='ppa:ubuntu-toolchain-r/test'
   # else
      GCC_LATEST_REPO='deb http://deb.debian.org/debian testing main'
   # fi
   
   apt-get update || true
   apt-get dist-upgrade -y
   apt-get install -y curl gnupg wget software-properties-common
   wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
   add-apt-repository "deb http://apt.llvm.org/$CODENAME/ llvm-toolchain-$CODENAME main" || true
   add-apt-repository "${GCC_LATEST_REPO}" || true
   echo "d6"
   apt-get update || true
   echo "d7"
   apt-get install -y   \
       build-essential  \
       bzip2            \
       clang-format     \
       clang-tidy-11       \
       clang-tools-11      \
       clang            \
       clangd           \
       gcc-10           \
       g++-10           \
       gdb              \
       git              \
       gzip             \
       libc++-11-dev       \
       libc++abi-11-dev    \
       libclang-dev     \
       lld              \
       lldb             \
       llvm-dev         \
       llvm-runtime     \
       llvm             \
       ninja-build      \
       openssh-server   \
       python3          \
       python3-pip      \
       python3-clang-11 \
       sed              \
       tar              \
       unzip            \
       zip              \
       zlib1g
   python3 -m pip install pip --upgrade
}

install_cmake() {
   echo "Installing CMake..."
   if [[ $1 == "root" ]]; then
      python3 -m pip install cmake
   else
      sudo -u $1 python3 -m pip install --user cmake
   fi
}

install_vcpkg() {
   if [[ ! -d ./vcpkg ]]; then
	   git clone https://github.com/Microsoft/vcpkg.git
   fi
   pushd vcpkg
   git pull
   cp ../config/vcpkg/* triplets/community/.
   ./bootstrap-vcpkg.sh -disableMetrics
   ./vcpkg install --clean-after-build catch2:x64-linux-libcxx
   popd
}

if [ ! -f "${PWD}/config/tools/apt-install.sh" ]; then
   >&2 echo "apt-install.sh must be run from the top-level directory of the project."
   exit 1
fi

apt_install $1
install_cmake $1
install_vcpkg
echo "Done :-)"
