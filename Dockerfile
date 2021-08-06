FROM mzahana/px4-ros-melodic-cuda10.1:latest

MAINTAINER t-thanh <tien.thanh@eu4m.eu>

USER root
RUN apt-get update && sudo apt-get install -y sudo wget terminator
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN export uid=1000 gid=1000
RUN mkdir -p /home/docker
RUN echo "docker:x:${uid}:${gid}:docker,,,:/home/docker:/bin/bash" >> /etc/passwd
RUN echo "docker:x:${uid}:" >> /etc/group
#RUN echo "docker ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chmod 0440 /etc/sudoers
RUN chown ${uid}:${gid} -R /home/docker

USER docker
WORKDIR /home/docker
RUN mkdir -p /home/docker/.config/terminator/config
RUN /bin/bash -c 'source /opt/ros/melodic/setup.bash && \
	mkdir -p /home/docker/catkin_ws/src && cd /home/docker/catkin_ws && catkin_make && \
	source /home/docker/catkin_ws/devel/setup.bash && \
	echo "source /home/docker/catkin_ws/devel/setup.bash" >> /home/docker/setup-px4.sh && \
	sudo apt --quiet -y install ca-certificates gnupg lsb-core wget && \
	cd /home/docker/catkin_ws/src && git clone https://github.com/t-thanh/px4_fast_planner && \
	git clone https://github.com/Jaeyoung-Lim/mavros_controllers.git && \
	git clone https://github.com/catkin/catkin_simple && \
	git clone https://github.com/ethz-asl/eigen_catkin && \
	git clone https://github.com/ethz-asl/mav_comm && \
	git clone https://github.com/mzahana/Fast-Planner.git && \
	cd Fast-Planner && git checkout changes_for_ros_melodic && \
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install astyle build-essential ccache clang clang-tidy cmake cppcheck doxygen file g++ gcc gdb git lcov make ninja-build python3 python3-dev python3-pip python3-setuptools python3-wheel rsync shellcheck unzip xsltproc zip && \
	pip3 install --user -r /home/docker/catkin_ws/src/px4_fast_planner/install/px4_requirements.txt && \
	sudo -S DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly libeigen3-dev libgazebo9-dev libgstreamer-plugins-base1.0-dev libimage-exiftool-perl libopencv-dev libxml2-utils pkg-config protobuf-compiler libfreeimage-dev'
RUN cd /home/docker && git clone https://github.com/PX4/Firmware && cd Firmware && make clean && make distclean && \
	git checkout v1.10.1 && git submodule init && git submodule update --recursive && \
	cd /home/docker/Firmware/Tools/sitl_gazebo/external/OpticalFlow && git submodule init && git submodule update --recursive && \
	cd /home/docker/Firmware/Tools/sitl_gazebo/external/OpticalFlow/external/klt_feature_tracker && \
	git submodule init && git submodule update --recursive && \
	sed -i 's/#define HAS_GYRO.*/#define HAS_GYRO true/' /home/docker/Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h && \
	cd /home/docker/Firmware && DONT_RUN=1 make px4_sitl gazebo
RUN /bin/bash -c 'source /home/docker/catkin_ws/devel/setup.bash && \
	echo "source /home/docker/Firmware/Tools/setup_gazebo.bash /home/docker/Firmware $HOME/Firmware/build/px4_sitl_default" >> /home/docker/setup-px4.sh && \
	echo "export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/home/docker/Firmware/Tools/sitl_gazebo::/home/docker/Firmware" >> /home/docker/setup-px4.sh && \
	echo "export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins" >> /home/docker/setup-px4.sh && \
	echo "export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/home/docker/catkin_ws/src/px4_fast_planner/models" >> /home/docker/setup-px4.sh && \
	cp /home/docker/catkin_ws/src/px4_fast_planner/config/10017_iris_depth_camera /home/docker/Firmware/ROMFS/px4fmu_common/init.d-posix/ && \
	source /home/docker/setup-px4.sh && \
	sudo apt install ros-melodic-mavros ros-melodic-mavros-extras ros-melodic-nlopt libarmadillo-dev -y && \
	cd /home/docker/catkin_ws && catkin_make'
RUN echo "source /home/docker/setup-px4.sh" > ~/.bashrc
# Launch terminator
CMD terminator -u
