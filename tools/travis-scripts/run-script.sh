#!/bin/bash

# exit this script if any commmand fails
set -e

function build_linux(){

   echo "Building project ..."

   mkdir bin
   cmake -D CMAKE_BUILD_TYPE=Release -G Unix\ Makefiles -Bbin -Hbin/.. 

   cd bin
   
   if [ ! -f config.cfg ]; then
      echo "Configuration file (config.cfg) was not properly generated by CMake, pull request failed"
	  exit 1
   fi
   
   if [ ! -d input ]; then
      echo -e "\n\n************************************  CMake was unable to download the dataset: DOWNLOAD FORCED  ************************************" 
	  curl -L --progress-bar http://imagelab.ing.unimore.it/files/YACCLAB_dataset.zip > dataset.zip
	  unzip -qq dataset.zip
	  rm dataset.zip  
	  echo -e "***************************************************************  DONE!  *************************************************************\n\n"
   fi
   
   rm config.cfg
   cp ../doc/ConfigurationFileForTravisCiTests.cfg .
   mv ConfigurationFileForTravisCiTests.cfg config.cfg
 
   make 
   ./YACCLAB

}

function build_mac(){

   echo "Building project ..."

   mkdir bin
   cmake -D CMAKE_BUILD_TYPE=Release -G Xcode -Bbin -Hbin/.. 

   cd bin
   
   if [ ! -f config.cfg ]; then
      echo "Configuration file (config.cfg) was not properly generated by CMake, pull request failed"
	  exit 1
   fi

   if [ ! -d input ]; then
      echo -e "\n\n************************************  CMake was unable to download the dataset: DOWNLOAD FORCED  ************************************" 
	  curl -L --progress-bar http://imagelab.ing.unimore.it/files/YACCLAB_dataset.zip > dataset.zip
	  unzip -qq dataset.zip
	  rm dataset.zip  
	  echo -e "***************************************************************  DONE!  *************************************************************\n\n"
   fi
   
   rm config.cfg
   cp ../doc/ConfigurationFileForTravisCiTests.cfg .
   mv ConfigurationFileForTravisCiTests.cfg config.cfg
 
   # xcodebuild -project YACCLAB.xcodeproj -target YACCLAB -configuration Release > 
   xcodebuild -project YACCLAB.xcodeproj -target YACCLAB -configuration Release
   ./Release/YACCLAB
   
}

function pass(){
	echo "pass"
}

function run_pull_request(){

    # linux
    if [ "$BUILD_TARGET" == "linux" ]; then
        build_linux
    fi

    if [ "$BUILD_TARGET" == "mac" ]; then
        build_mac
    fi
}

# build pull request
#if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
	run_pull_request
#fi
