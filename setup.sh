#!/bin/bash

CATKIN_WS=$PWD/catkin_ws
CATKIN_SRC=$CATKIN_WS/src
HOMEDIR=$PWD

if [ ! -d "$CATKIN_WS" ]; then
	echo "Creating $CATKIN_WS ... "
	mkdir -p $CATKIN_SRC
fi

if [ ! -d "$CATKIN_SRC" ]; then
	echo "Creating $CATKIN_SRC ..."
fi

# Configure catkin_Ws
cd $CATKIN_WS
sudo apt --quiet -y install python-catkin-tools 
catkin init
catkin config --merge-devel
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

echo "source $CATKIN_WS/devel/setup.bash" >> $HOMEDIR/setup-px4.sh

####################################### Setup PX4 v1.10.1 #######################################
echo -e "\e[1;33m Setting up Px4 v1.10.1 \e[0m"
# Installing initial dependencies
sudo apt --quiet -y install \
	ca-certificates \
	gnupg \
	lsb-core \
	wget \
	;
# script directory
cd ${CATKIN_SRC}/px4_fast_planner/install

echo "Installing PX4 general dependencies"

sudo apt-get update -y --quiet
sudo DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
	astyle \
	build-essential \
	ccache \
	clang \
	clang-tidy \
	cmake \
	cppcheck \
	doxygen \
	file \
	g++ \
	gcc \
	gdb \
	git \
	lcov \
	make \
	ninja-build \
	python3 \
	python3-dev \
	python3-pip \
	python3-setuptools \
	python3-wheel \
	rsync \
	shellcheck \
	unzip \
	xsltproc \
	zip \
	;
	
# Python3 dependencies
echo
echo "Installing PX4 Python3 dependencies"
pip3 install --user -r $CATKIN_SRC/px4_fast_planner/install/px4_requirements.txt
wget https://raw.githubusercontent.com/PX4/Firmware/master/Tools/setup/requirements.txt
pip install --user -r $CATKIN_SRC/px4_fast_planner/install/requirements.txt

sudo -S DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
		gstreamer1.0-plugins-bad \
		gstreamer1.0-plugins-base \
		gstreamer1.0-plugins-good \
		gstreamer1.0-plugins-ugly \
		libeigen3-dev \
		libgazebo9-dev \
		libgstreamer-plugins-base1.0-dev \
		libimage-exiftool-perl \
		libopencv-dev \
		libxml2-utils \
		pkg-config \
		protobuf-compiler \
		libfreeimage-dev \
		;


#Setting up PX4 Firmware
if [ ! -d "$HOMEDIR/Firmware" ]; then
	cd $HOMEDIR
	git clone https://github.com/PX4/Firmware
else
	echo "Firmware already exists. Just pulling latest upstream...."
	cd $HOMEDIR/Firmware
	git pull
fi
cd $HOMEDIR/Firmware
make clean && make distclean
git checkout v1.10.1 && git submodule init && git submodule update --recursive
cd $HOMEDIR/Firmware/Tools/sitl_gazebo/external/OpticalFlow
git submodule init && git submodule update --recursive
cd $HOMEDIR/Firmware/Tools/sitl_gazebo/external/OpticalFlow/external/klt_feature_tracker
git submodule init && git submodule update --recursive
# NOTE: in PX4 v1.10.1, there is a bug in Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h:43:18
# #define HAS_GYRO TRUE needs to be replaced by #define HAS_GYRO true
sed -i 's/#define HAS_GYRO.*/#define HAS_GYRO true/' $HOMEDIR/Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h
cd $HOMEDIR/Firmware
DONT_RUN=1 make px4_sitl gazebo

#Copying this to  setup-px4.sh file
grep -xF 'source $HOMEDIR/Firmware/Tools/setup_gazebo.bash $HOMEDIR/Firmware $HOMEDIR/Firmware/build/px4_sitl_default' $HOMEDIR/setup-px4.sh || echo "source $HOMEDIR/Firmware/Tools/setup_gazebo.bash $HOMEDIR/Firmware $HOMEDIR/Firmware/build/px4_sitl_default" >> $HOMEDIR/setup-px4.sh
grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$HOMEDIR/Firmware' $HOMEDIR/setup-px4.sh || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:$HOMEDIR/Firmware" >> $HOMEDIR/setup-px4.sh
grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$HOMEDIR/Firmware/Tools/sitl_gazebo' $HOMEDIR/setup-px4.sh || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:$HOMEDIR/Firmware/Tools/sitl_gazebo" >> $HOMEDIR/setup-px4.sh
grep -xF 'export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins' $HOMEDIR/setup-px4.sh || echo "export GAZEBO_PLUGIN_PATH=\$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins" >> $HOMEDIR/setup-px4.sh
grep -xF 'export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:'$HOMEDIR'/catkin_ws/src/px4_fast_planner/models' $HOMEDIR/setup-px4.sh || echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:$CATKIN_WS/src/px4_fast_planner/models" >> $HOMEDIR/setup-px4.sh

# Copy PX4 SITL param file
cp $CATKIN_SRC/px4_fast_planner/config/10017_iris_depth_camera $HOMEDIR/Firmware/ROMFS/px4fmu_common/init.d-posix/

source $HOMEDIR/setup-px4.sh


# Install MAVROS
sudo apt install ros-melodic-mavros ros-melodic-mavros-extras -y
####################################### mavros_controllers setup #######################################
echo -e "\e[1;33m Adding mavros_controllers \e[0m"
#Adding mavros_controllers
if [ ! -d "$CATKIN_SRC/mavros_controllers" ]; then
    echo "Cloning the mavros_controllers repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/Jaeyoung-Lim/mavros_controllers.git
    cd ../
else
    echo "mavros_controllers already exists. Just pulling ..."
    cd $CATKIN_SRC/mavros_controllers
    git pull
    cd ../ 
fi

#Adding catkin_simple
if [ ! -d "$CATKIN_SRC/catkin_simple" ]; then
    echo "Cloning the catkin_simple repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/catkin/catkin_simple
    cd ../
else
    echo "catkin_simple already exists. Just pulling ..."
    cd $CATKIN_SRC/catkin_simple
    git pull
    cd ../ 
fi

#Adding eigen_catkin
if [ ! -d "$CATKIN_SRC/eigen_catkin" ]; then
    echo "Cloning the eigen_catkin repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/ethz-asl/eigen_catkin
    cd ../
else
    echo "eigen_catkin already exists. Just pulling ..."
    cd $CATKIN_SRC/eigen_catkin
    git pull
    cd ../ 
fi

#Adding eigen_catkin
if [ ! -d "$CATKIN_SRC/mav_comm" ]; then
    echo "Cloning the mav_comm repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/ethz-asl/mav_comm
    cd ../
else
    echo "mav_comm already exists. Just pulling ..."
    cd $CATKIN_SRC/mav_comm
    git pull
    cd ../ 
fi


####################################### Fast-planner setup #######################################
echo -e "\e[1;33m Adding Fast-Planner \e[0m"
# Required for Fast-Planner
sudo apt install ros-melodic-nlopt libarmadillo-dev -y

#Adding Fast-Planner
if [ ! -d "$CATKIN_SRC/Fast-Planner" ]; then
    echo "Cloning the Fast-Planner repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/mzahana/Fast-Planner.git
    cd ../
else
    echo "Fast-Planner already exists. Just pulling ..."
    cd $CATKIN_SRC/Fast-Planner
    git pull
    cd ../ 
fi

# Checkout ROS Melodic branch 
cd $CATKIN_SRC/Fast-Planner
git checkout changes_for_ros_melodic

####################################### Building catkin_ws #######################################
cd $CATKIN_WS
catkin_make

