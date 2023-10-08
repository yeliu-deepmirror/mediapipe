FROM 592906237467.dkr.ecr.ap-east-1.amazonaws.com/dm/common-images-bazel:5.1.1-ubuntu-20.04 as bazel

FROM 592906237467.dkr.ecr.ap-east-1.amazonaws.com/dm/common-images-clang-llvm:15.0.6-ubuntu-20.04 as clang-llvm

################################################################################

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 AS builder

RUN rm /etc/apt/sources.list.d/*

# Install tools for building.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential=12.8* \
    cmake=3.16.3* \
    curl=7.68.0* \
    git=1:2.25.1* \
    pkg-config=0.29.1* \
    software-properties-common=0.99.9* \
    unzip=6.0* \
    wget=1.20.3* \
    && rm -rf /var/lib/apt/lists/*

# Install lib dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libatlas-base-dev=3.10.3* \
    libavcodec-dev=7:4.2.7* \
    libavformat-dev=7:4.2.7* \
    libblas-dev=3.9.0* \
    libgl1-mesa-dev=21.2.6* \
    libgtk-3-dev=3.24.20* \
    liblapack-dev=3.9.0* \
    libsuitesparse-dev=1:5.7.1* \
    libswscale-dev=7:4.2.7* \
    libvtk7-dev=7.1.1* \
    libeigen3-dev \
    && rm -rf /var/lib/apt/lists/*

# Compile all libs with install prefix /tmp/build.

COPY installers/opencv.sh /tmp/installers/
RUN bash /tmp/installers/opencv.sh /tmp/build && rm /tmp/installers/opencv.sh

################################################################################

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# Set locale.
RUN apt-get update -y && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install tools for installers.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential=12.8* \
    cmake=3.16.3* \
    curl=7.68.0* \
    git=1:2.25.1* \
    pkg-config=0.29.1* \
    software-properties-common=0.99.9* \
    unzip=6.0* \
    wget=1.20.3* \
    libcurl4-openssl-dev \
    sshfs \
    sudo \
    vim \
    python3-dev \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Install lib dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libavcodec-dev=7:4.2.7* \
    libavformat-dev=7:4.2.7* \
    libswscale-dev=7:4.2.7* \
    libvtk7-dev=7.1.1* \
    libsuitesparse-dev=1:5.7.1* \
    libglu1-mesa-dev=9.0.1* \
    libgl1-mesa-dev=21.2.6* \
    libglew-dev=2.1.0* \
    libgtk2.0-dev \
    libgtk-3-dev=3.24.20* \
    libcgal-dev \
    libboost-graph-dev \
    libboost-serialization-dev \
    libmetis-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN ldconfig

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip=20.0.2* \
    python3-tk \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install cpplint==1.6.0
RUN pip3 install evo==1.24.0
RUN pip3 install bokeh==3.1.1

COPY --from=builder /tmp/build /usr/local

# Copy LLVM.
ENV PATH /opt/llvm/bin:$PATH
COPY --from=clang-llvm /data /opt
ENV LLVM_VERSION 15.0.6

# Copy Bazel.
COPY --from=bazel /usr/local/lib/bazel /usr/local/lib/bazel
RUN ln -s /usr/local/lib/bazel/bin/bazel /usr/local/bin/bazel
