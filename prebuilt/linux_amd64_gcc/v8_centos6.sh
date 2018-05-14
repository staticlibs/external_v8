#!/bin/bash
#
# Copyright 2018, alex at staticlibs.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x

# variables
export V8_GIT_TAG=6.7.288.32
export D="sudo docker exec builder"

# docker
sudo docker pull centos:6
sudo docker run \
    -id \
    --name builder \
    -w /opt \
    -v `pwd`:/host \
    -e PERL5LIB=/opt/rh/devtoolset-6/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-6/root/usr/lib/perl5:/opt/rh/devtoolset-6/root//usr/share/perl5/vendor_perl \
    -e LD_LIBRARY_PATH=/opt/rh/httpd24/root/usr/lib64:/opt/rh/devtoolset-6/root/usr/lib64:/opt/rh/devtoolset-6/root/usr/lib:/opt/rh/python27/root/usr/lib64 \
    -e PYTHONPATH=/opt/rh/devtoolset-6/root/usr/lib64/python2.6/site-packages:/opt/rh/devtoolset-6/root/usr/lib/python2.6/site-packages \
    -e PKG_CONFIG_PATH=/opt/rh/python27/root/usr/lib64/pkgconfig \
    -e PATH=/opt/rh/rh-git29/root/usr/bin:/opt/rh/python27/root/usr/bin:/opt/rh/devtoolset-6/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/depot_tools:/opt/tools_linux_patchelf \
    centos:6 \
    bash

# dependencies
$D yum install -y \
    centos-release-scl-rh
$D yum install -y \
    devtoolset-6 \
    python27 \
    rh-git29 \
    zip \
    xz \
    glib2-devel

# tools
$D git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
$D git clone --depth=1 https://github.com/wilton-iot/tools_linux_gn.git
$D git clone --depth=1 https://github.com/wilton-iot/tools_linux_patchelf.git
$D fetch --nohooks v8
$D git -C v8 checkout ${V8_GIT_TAG}
$D gclient sync
$D rm -f /opt/depot_tools/gn
$D mv /opt/tools_linux_gn/gn /opt/depot_tools/

# build
$D gn gen /opt/v8/out.gn/x64.release --root=/opt/v8 --args='binutils_path="/opt/rh/devtoolset-6/root/usr/bin/" is_clang=false is_cfi=false is_component_build=true is_debug=false is_desktop_linux=true is_official_build=true icu_use_data_file=false libcpp_is_static=true strip_debug_info=true treat_warnings_as_errors=false use_gold=false use_sysroot=false v8_embedder_string="-wilton" v8_target_cpu="x64" v8_use_multi_snapshots=false v8_use_snapshot=false'
$D ninja -C /opt/v8/out.gn/x64.release/

# icu
$D cp /opt/v8/out.gn/x64.release/libicui18n.so .
$D strip ./libicui18n.so
$D patchelf --set-rpath '$ORIGIN/.' ./libicui18n.so
$D mv libicui18n.so /host
$D cp /opt/v8/out.gn/x64.release/libicuuc.so .
$D strip ./libicuuc.so
$D patchelf --set-rpath '$ORIGIN/.' ./libicuuc.so
$D mv libicuuc.so /host

# v8
$D cp /opt/v8/out.gn/x64.release/libv8_libbase.so .
$D strip ./libv8_libbase.so
$D patchelf --set-rpath '$ORIGIN/.' ./libv8_libbase.so
$D mv libv8_libbase.so /host
$D cp /opt/v8/out.gn/x64.release/libv8_libplatform.so .
$D strip ./libv8_libplatform.so
$D patchelf --set-rpath '$ORIGIN/.' ./libv8_libplatform.so
$D mv libv8_libplatform.so /host
$D cp /opt/v8/out.gn/x64.release/libv8.so .
$D strip ./libv8.so
$D patchelf --set-rpath '$ORIGIN/.' ./libv8.so
$D mv libv8.so /host
