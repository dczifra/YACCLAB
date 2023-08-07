FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

RUN apt -qq update                  && \
    DEBIAN_FRONTEND=noninteractive apt -qq install build-essential    \
    python3-pip opencl-headers ocl-icd-opencl-dev cmake g++ -y

RUN apt-get update \
  && apt-get -y install build-essential \
  && apt-get -y install cmake git g++

RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git
RUN mkdir -p /opencv/build && cd /opencv/build
RUN cmake \
  -D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
  -D BUILD_LIST="core,imgcodecs,imgproc,core,cudafeatures2d,cudaarithm,cudafilters,cudaimgproc,cudawarping,cudev,features2d,imgcodecs,imgproc" \
  -D WITH_CUDA=ON \
  -D WITH_CUDNN=ON \
  -D WITH_CUBLAS=ON \
  -D CUDA_ARCH_BIN=7.5,8.0,8.6 \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  /opencv
RUN make -j8
RUN make install

RUN DEBIAN_FRONTEND=noninteractive apt-get install gnuplot -y
RUN pip3 install pandas

WORKDIR /workspace