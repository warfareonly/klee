FROM ubuntu:16.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>

RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    cmake \
    curl \
    flex \
    git \
    google-perftools \
    libboost-all-dev \
    libgoogle-perftools-dev \
    libncurses5-dev \
    minisat \
    nano \
    ninja \
    perl \
    python \
    python-pip \
    software-properties-common \
    subversion \
    unzip \
    zlib1g-dev \
    wget
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add -

RUN mkdir -p /llvm/llvm-34; svn co  http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_34/final /llvm/llvm-34/source;
RUN svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_34/final /llvm/llvm-34/source/tools/clang
RUN svn co https://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_34/final/ /llvm/llvm-34/source/projects/compiler-rt
RUN mkdir /llvm/llvm-34/build; cd /llvm/llvm-34/build; cmake ../source -DCMAKE_BUILD_TYPE=Release -DCMAKE_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_WERROR=OFF -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_CXX_FLAGS="-std=c++11"
RUN cd /llvm/llvm-34/build; make -j32; make install


RUN mkdir /stp; git clone https://github.com/stp/stp.git /stp/source
RUN mkdir /stp/build; cd /stp/build; cmake ../source/; make -j32; make install



RUN mkdir /klee; git clone https://github.com/klee/klee-uclibc.git /klee/uclibc
RUN cd /klee/uclibc; ./configure --make-llvm-lib; make -j32;
RUN curl -OL https://github.com/google/googletest/archive/release-1.7.0.zip; mv release-1.7.0.zip /klee/test.zip; cd /klee; unzip test.zip;
RUN git clone https://github.com/rshariffdeen/klee.git /klee/source; cd /klee/source; git checkout seedmode-external-calls
RUN mkdir /klee/build; cd /klee/build;  cmake -DCMAKE_CXX_FLAGS="-fno-rtti"   -DENABLE_SOLVER_STP=ON   -DENABLE_POSIX_RUNTIME=ON   -DENABLE_KLEE_UCLIBC=ON   -DKLEE_UCLIBC_PATH=/klee/uclibc  -DGTEST_SRC_DIR=/klee/test  -DENABLE_SYSTEM_TESTS=OFF   -DENABLE_UNIT_TESTS=OFF -DLLVM_CONFIG_BINARY=/llvm/llvm-34/build/bin/llvm-config ../source/;
RUN cd /klee/build; make -j32; make install


RUN git clone https://github.com/Z3Prover/z3.git /z3;
RUN cd /z3; git checkout z3-4.8.1; python scripts/mk_make.py;
RUN cd /z3/build; make -j32; make install
ENV PYTHONPATH=/z3/build/python


# Tidy up the container
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
