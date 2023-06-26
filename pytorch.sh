#!/bin/bash

# This script will be run before the main container starts.

echo "Hello from the initcontainer!"

git clone https://github.com/pytorch/serve.git

cd serve

pip install torch-model-archiver

torch-model-archiver --model-name mnist_kf --version 1.0 \
--model-file examples/image_classifier/mnist/mnist.py \
--serialized-file examples/image_classifier/mnist/mnist_cnn.pt \
--handler  examples/image_classifier/mnist/mnist_handler.py

ls

mkdir -pv /mnt/models/config
mkdir -pv /mnt/models/model-store

cat > /mnt/models/config.properties <<EOF
inference_address=http://0.0.0.0:8085
management_address=http://0.0.0.0:8081
metrics_address=http://0.0.0.0:8082
grpc_inference_port=7070
grpc_management_port=7071
enable_envvars_config=true
install_py_dep_per_model=true
enable_metrics_api=true
metrics_mode=prometheus
NUM_WORKERS=1
number_of_netty_threads=4
job_queue_size=10
model_store=/mnt/models/model-store
model_snapshot={"name":"startup.cfg","modelCount":1,"models":{"mnist_kf":{"1.0":{"defaultVersion":true,"marName":"mnist_kf.mar","minWorkers":1,"maxWorkers":5,"batchSize":1,"maxBatchDelay":5000,"responseTimeout":120}}}}
EOF

mv mnist_kf.mar /mnt/models/model-store/


# Once the initialization work is complete, exit the script.

exit 0
