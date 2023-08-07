# Install

```
git clone https://github.com/dczifra/YACCLAB
cd YACCLAB
./docker/build.sh (Takes a lot of time, you can skip it ==> Than the next command will pull from dockerhub)
./docker/run.sh
mkdir build
cd build
cmake -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda OpenCV_DIR=/opencv/ -D YACCLAB_ENABLE_CUDA=ON -D YACCLAB_DOWNLOAD_DATASET=ON ..
make -j16
./YACCLAB
```



* [Official](https://docs.opencv.org/4.x/d7/d9f/tutorial_linux_install.html)
* [OpenCV contrib](https://github.com/opencv/opencv_contrib)
* [OpenCV + CUDA ](https://docs.opencv.org/3.4/d6/d15/tutorial_building_tegra_cuda.html)
* https://towardsdatascience.com/opencv-cuda-aws-ec2-no-more-tears-60af2b751c46
* https://stackoverflow.com/questions/66228170/cmake-in-my-opencv-4-2-0-source-code-couldnt-find-any-cudnn-installed-in-my-mac