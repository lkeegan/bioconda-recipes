#!/bin/bash
set -eu -o pipefail

# pre-built version
if [ "$(uname)" == "Darwin" ]; then
    outdir=$PREFIX/share/$PKG_NAME-$PKG_VERSION-$PKG_BUILDNUM
    mkdir -p $outdir
    mkdir -p $PREFIX/bin
    cp -r bin lib $outdir
    ln -s $outdir/bin/salmon $PREFIX/bin
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Custom built version running into problems with NFS segfaults
    # https://github.com/COMBINE-lab/salmon/issues/34
    # Download and use tcmalloc in our build to avoid
    mkdir -p $SRC_DIR/external
    wget -O $SRC_DIR/external/gperftools-2.5.tar.gz https://github.com/gperftools/gperftools/releases/download/gperftools-2.5/gperftools-2.5.tar.gz
    cd $SRC_DIR/external
    tar -xzvpf gperftools-2.5.tar.gz
    cd gperftools-2.5
    export CXXFLAGS='-std=c++11'
    ./configure --prefix=$SRC_DIR/external/install
    make install
    # build Salmon
    cd $SRC_DIR
    mkdir -p build
    # Use the tcmalloc installed above
    sed -i 's#set (HAVE_FAST_MALLOC FALSE)#set (HAVE_FAST_MALLOC TRUE)\nset (FAST_MALLOC_LIB ${CMAKE_CURRENT_SOURCE_DIR}/external/install/lib/libtcmalloc.a)#' CMakeLists.txt
    sed -i 's/Boost_USE_STATIC_LIBS ON/Boost_USE_STATIC_LIBS OFF/' CMakeLists.txt
    sed -i 's#set(Boost_ADDITIONAL_VERSIONS "1.53" "1.53.0" "1.54" "1.55" "1.56" "1.57.0" "1.58")#set(Boost_ADDITIONAL_VERSIONS "1.53" "1.53.0" "1.54" "1.55" "1.56" "1.57.0" "1.58" "1.74.0")#' CMakeLists.txt
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBOOST_ROOT=$PREFIX -DBoost_DEBUG=ON -DBoost_NO_BOOST_CMAKE=ON ..
    make install
fi