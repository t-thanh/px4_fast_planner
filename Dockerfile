FROM turlucode/ros-melodic:cuda10.1-cudnn7

MAINTAINER t-thanh <tien.thanh@eu4m.eu>

RUN apt-get update && apt-get install -y sudo wget
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
RUN /bin/bash -c 'sudo apt-get update && sudo apt-get install -y git && source /opt/ros/melodic/setup.bash && \
	cd ~/ && git clone https://github.com/t-thanh/px4_fast_planner && cd px4_fast_planner && ./setup.sh'
RUN echo "source ~/px4_fast_planner/setup-px4.sh" > ~/.bashrc
# Launch terminator
CMD ["terminator"]
