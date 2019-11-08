ARG BASE_IMAGE=renku/singleuser:latest
FROM $BASE_IMAGE

LABEL maintainer="Swiss Data Science Center <info@datascience.ch>"

## cuda base
## from https://gitlab.com/nvidia/cuda/blob/ubuntu18.04/10.0/base/Dockerfile
USER root
RUN apt-get update && apt-get install -y --no-install-recommends gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.0.130
ENV CUDA_PKG_VERSION 10-0=$CUDA_VERSION-1

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
        cuda-compat-10-0 && \
    ln -s cuda-10.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0"

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

## cuda runtime
## https://gitlab.com/nvidia/container-images/cuda/blob/ubuntu18.04/10.0/runtime
ENV NCCL_VERSION 2.4.2
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-libraries-$CUDA_PKG_VERSION \
        cuda-nvtx-$CUDA_PKG_VERSION \
        libnccl2=$NCCL_VERSION-1+cuda10.0 && \
    apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*

## cuda devel
## https://gitlab.com/nvidia/container-images/cuda/blob/ubuntu18.04/10.0/devel

RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-libraries-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-minimal-build-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        libnccl-dev=$NCCL_VERSION-1+cuda10.0 && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs


## CUDNN 7 
## https://gitlab.com/nvidia/container-images/cuda/blob/ubuntu18.04/10.0/devel/cudnn7
ENV CUDNN_VERSION 7.6.0.64

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda10.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda10.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs

USER $NB_USER

## Tensorflow GPU
RUN /opt/conda/bin/pip install tensorflow-gpu==1.14

# # Tensorboard jupyter extension 
# RUN    pip install nbserverproxy \
#     && jupyter serverextension enable --py nbserverproxy \
#     && jupyter labextension install @renku/jupyterlab-vnc


###### Installation of NVTOP
#RUN apt install -y nvtop
# USER $NB_USER
# RUN git clone https://github.com/Syllo/nvtop.git
# RUN mkdir -p nvtop/build
# RUN cd nvtop/build && cmake .. -DNVML_RETRIEVE_HEADER_ONLINE=True 
# RUN cd nvtop/build && make
# # If it errors with "Could NOT find NVML (missing: NVML_INCLUDE_DIRS)"
# # try the following command instead, otherwise skip to the build with make.
# #vcmake .. -DNVML_RETRIEVE_HEADER_ONLINE=True
# USER root
# RUN cd nvtop/build && make install # You may need sufficient permission for that (root)
# RUN cd ../..
##### End of installation of NVTOP



USER $NB_USER


# Uncomment and adapt if code is to be included in the image
# COPY src /code/src

# install the python dependencies
COPY requirements.txt environment.yml /tmp/
RUN conda env update -q -f /tmp/environment.yml && \
    /opt/conda/bin/pip install -r /tmp/requirements.txt && \
    conda clean -y --all && \
    conda env export -n "root"
