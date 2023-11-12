FROM rocm/dev-ubuntu-22.04:5.7-complete
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8
WORKDIR /tmp

# Install python 3.10 and requirements
RUN apt-get update -y && apt-get install -y software-properties-common && \ 
    add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update &&\
    apt-get install -y \
    wget \
    git \
    python3.10 \
    python3-dev \
    python3.10-tk \
    python-is-python3 \
    python3.10-venv \
    rsync
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10
RUN python3.10 -m pip install --upgrade pip wheel setuptools

# Install requirements for ROCM build-stuff
RUN apt-get install -y hipblas hipblaslt hipsparse hipcub hip-runtime-amd rocthrust rocthrust-dev rocrand

# Install PyTorch
RUN python3.10 -m pip install torch torchvision --index-url https://download.pytorch.org/whl/nightly/rocm5.7

# Create ai folder for saving projects
RUN mkdir /ai/

# Install bitsandbytes, required for many AI tools, with ROCM fork/PR
WORKDIR /ai/git/bitsandbytes
RUN git clone https://github.com/TimDettmers/bitsandbytes.git /ai/git/bitsandbytes
# Clone the ROCM PR branch cause it isn't merged yet
RUN git fetch origin refs/pull/756/head:rocmport && git checkout rocmport
# Set the env variables to the container ROCM setup
ENV ROCM_HOME=/opt/rocm-5.7.0
ENV ROCM_TARGET=gfx1030
# Build and install globally
RUN make hip && pip install .


# Install StableDiffusion in /ai/
WORKDIR /ai/stablediffusion-webui
RUN git clone -b dev https://github.com/AUTOMATIC1111/stable-diffusion-webui /ai/git/stablediffusion-webui
RUN cp -R /ai/git/stablediffusion-webui/* /ai/stablediffusion-webui/
# Create VENV for StableDiffusion with inherit pytorch
RUN python3.10 -m venv /ai/venv/stablediffusion/ --system-site-packages
RUN /ai/venv/stablediffusion/bin/python launch.py --skip-torch-cuda-test --exit 
RUN /ai/venv/stablediffusion/bin/python -m pip install opencv-python-headless tomesd protobuf --upgrade


# Install Kobold AI in /ai/
WORKDIR /ai/koboldai
RUN git clone https://github.com/YellowRoseCx/koboldcpp-rocm.git -b main --depth 1 /ai/git/koboldai
RUN cp -R /ai/git/koboldai/* /ai/koboldai/
# Build KoboldAI for ROCM
RUN make LLAMA_HIPBLAS=1 -j4


# Install LlamaCPP in /ai/
WORKDIR /ai/llamacpp
RUN git clone https://github.com/ggerganov/llama.cpp.git -b master /ai/git/llamacpp
RUN cp -R /ai/git/llamacpp/* /ai/llamacpp/
# Build LlamaCPP for ROCM
RUN make LLAMA_HIPBLAS=1 -j4
RUN pip install --ignore-installed flask requests

# Install KoyhaSS in /ai/
WORKDIR /ai/kohya_ss
# RUN apt-get install -y libgl1 libglib2.0-0 libgoogle-perftools-dev  python3-html5lib python3-apt python3.10-distutils
RUN git clone https://github.com/bmaltais/kohya_ss.git -b master /ai/git/kohya_ss
# For some reason, the .release file is required and isn't copied automatically
RUN cp -R /ai/git/kohya_ss/* /ai/kohya_ss/ && cp /ai/git/kohya_ss/.release /ai/kohya_ss/
# Create VENV for KoyhaSS with inherit pytorch
RUN python3.10 -m venv /ai/venv/kohya_ss/ --system-site-packages
# Install python requirements
RUN /ai/venv/kohya_ss/bin/python -m pip install --upgrade pip wheel
RUN /ai/venv/kohya_ss/bin/python -m pip install -r requirements.txt && /ai/venv/kohya_ss/bin/python -m pip uninstall tensorflow
RUN /ai/venv/kohya_ss/bin/python -m pip install accelerate tensorboard tensorflow-rocm lion_pytorch
RUN /ai/venv/kohya_ss/bin/python -m pip install typing_extensions --upgrade

# Set safe directory for extensions and stuff
RUN git config --global --add safe.directory "*"

# Go back to ai folder when done
WORKDIR /ai

# Setup PyTorch ENVs for AMD GPUs
ENV PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.8,max_split_size_mb:128
# ENV HIP_VISIBLE_DEVICES="0"
# ENV AMDGPU_TARGETS="gfx1030"
# ENV HSA_OVERRIDE_GFX_VERSION='10.3.0'
