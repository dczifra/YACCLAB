docker run \
    --rm --gpus all \
    --mount type=bind,source="$(pwd)",target=/workspace \
    -it doma945/nvidia_base bash