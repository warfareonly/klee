# FROM ubuntu:16.04
FROM ubuntu:18.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>

ARG DEBIAN_FRONTEND=noninteractive

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
    iputils-ping \
    netcat-openbsd \
    minisat \
    nano \
    # ninja \
    ninja-build \
    sudo \
    perl \
    python \
    # python-pip \
    python3-pip \
    software-properties-common \
    subversion \
    unzip \
    zlib1g-dev \
    wget

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add -

ENV LLVM_VERSION=6.0

RUN apt-get install -y clang-${LLVM_VERSION} \
                       llvm-${LLVM_VERSION} \
                       llvm-${LLVM_VERSION}-dev \
                       llvm-${LLVM_VERSION}-tools


RUN mkdir /stp; git clone https://github.com/stp/stp.git /stp/source
RUN mkdir /stp/build; cd /stp/build; cmake ../source/; make -j32; make install

RUN ln -sf /usr/bin/llvm-config-6.0 /usr/bin/llvm-config
RUN ln -sf /usr/bin/clang-6.0 /usr/bin/clang

RUN mkdir /klee; git clone https://github.com/klee/klee-uclibc.git /klee/uclibc
RUN cd /klee/uclibc; ./configure --make-llvm-lib; make ;
RUN curl -OL https://github.com/google/googletest/archive/release-1.7.0.zip; mv release-1.7.0.zip /klee/test.zip; cd /klee; unzip test.zip;
RUN git clone https://github.com/rshariffdeen/klee.git /klee/source; cd /klee/source; git checkout concolic
RUN mkdir /klee/build; cd /klee/build;  cmake -DCMAKE_CXX_FLAGS="-fno-rtti"   -DENABLE_SOLVER_STP=ON   -DENABLE_POSIX_RUNTIME=ON   -DENABLE_KLEE_UCLIBC=ON   -DKLEE_UCLIBC_PATH=/klee/uclibc  -DGTEST_SRC_DIR=/klee/test  -DENABLE_SYSTEM_TESTS=OFF   -DENABLE_UNIT_TESTS=OFF ../source/;
RUN cd /klee/build; make -j32; make install

# RUN cmake \
#         -DENABLE_SOLVER_Z3=ON \
#         -DENABLE_POSIX_RUNTIME=ON \
#         -DENABLE_KLEE_UCLIBC=ON \
#         -DKLEE_UCLIBC_PATH=/klee-uclibc \
#         -DENABLE_UNIT_TESTS=OFF \
#         -DENABLE_SYSTEM_TESTS=OFF \
#             .. && \
#     make

RUN git clone https://github.com/Z3Prover/z3.git /z3;
RUN cd /z3; git checkout z3-4.8.1; python scripts/mk_make.py;
RUN cd /z3/build; make -j32; make install
ENV PYTHONPATH=/z3/build/python
ENV LLVM_COMPILER=clang

# Tidy up the container
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN curl -O https://bootstrap.pypa.io/pip/3.5/get-pip.py
RUN python3 get-pip.py
RUN python3 -m pip install --upgrade "pip < 19.2"
RUN pip3 install wllvm
# RUN python -m pip install wllvm flask
# RUN pip3 install --upgrade pip
# RUN pip3 install wllvm flask

RUN useradd -m klee && \
    echo klee:klee | chpasswd && \
    cp /etc/sudoers /etc/sudoers.bak && \
    echo 'klee  ALL=(root) NOPASSWD: ALL' >> /etc/sudoers


USER klee
WORKDIR /home/klee
ENV LD_LIBRARY_PATH /klee/klee_build/lib/
