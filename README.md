# ai-suite-rocm

This is a simple project to make hosting local LLM and AI tools easily on Linux with AMD GPUs using ROCM.

To use you have to clone the repo and build the docker image, it's the same image for all the services.

```bash
git clone https://github.com/M4TH1EU/ai-suite-rocm.git
cd ai-suite-rocm/
docker build . -t 'ai-suite-rocm:6.0' -f Dockerfile
```

Then you can start and stop whichever service you want using their respectives start/stop scripts.

For example, you can start stablediffusion using :
```bash
# Start
./start_stablediffusion.sh

# Stop
./stop_stablediffusion.sh
```


If like me you like storing all your models and big files on another disk, have a look at the make_folders.sh script (it creates symlinks).

*This has been tested on Fedora 39 with kernel 6.7.4 using latest docker version with an AMD RX 6800 XT.*
