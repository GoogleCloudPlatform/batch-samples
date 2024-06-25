FROM nvidia/cuda:12.5.0-devel-rockylinux9

# Copy python and shell scripts
COPY scripts /scripts

# Install various dependencies
RUN yum install -y python3-pip libcudnn8 unzip
RUN pip3 install install torchvision pillow
