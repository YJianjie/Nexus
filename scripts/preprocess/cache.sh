#!/usr/bin/env bash

# ========== Logging & Experiment Settings ==========
SAVE_DIR=/zeron-vepfs/tjqc/jianjie.ye/Nexus/models                    # Where logs and checkpoints will be saved
EXPERIMENT=nuplan_diy           # Experiment name
JOB_NAME=diy                    # Job name used for logging/checkpoints

# ========== Cache Settings ==========
CACHE_DIR=/zeron-vepfs/tjqc/jianjie.ye/Nexus/cache/diy_cache                  # Path to cache directory

# ========== NuPlan Dataset Paths ==========
NUPLAN_SENSOR_ROOT=/tj-share/nuscenes/nuplan/dataset/nuplan-v1.1/sensor_blobs  # Path to sensor blobs
# NUPLAN_DATA_ROOT=/dev/shm/nuplan_root/nuplan-v1.1/splits/mini     # Path to train/val split data
NUPLAN_DATA_ROOT=/zeron-vepfs/tjqc/public_datasets/nuplan/nuplan-v1.1/trainval
# NUPLAN_MAPS_ROOT=/dev/shm/nuplan_maps      # Path to map files
# NUPLAN_MAPS_ROOT=/tj-share/nuscenes/nuplan/dataset/maps      # Path to map files
NUPLAN_MAPS_ROOT=/zeron-vepfs/tjqc/public_datasets/nuplan/maps

# ========== NuPlan Devkit Path ==========
export NUPLAN_DEVKIT_PATH=/zeron-vepfs/tjqc/jianjie.ye/Nexus/third_party/nuplan-devkit  # Path to nuplan-devkit repo

# ========== Python Environment ==========
export PYTHONPATH=$PWD:$PYTHONPATH
export PYTHONPATH=$NUPLAN_DEVKIT_PATH:$PYTHONPATH

# ========== OpenBLAS and OpenMP Settings ==========
export OPENBLAS_NUM_THREADS=1    # To avoid OpenBlas creating too many threads
export OMP_NUM_THREADS=1         # Control the number of threads per process for OpenMP

# ========== Data Split (Optional) ==========
# Uncomment the following lines if you need to use data splits
# SPLIT="YOUR_SPLIT"  # e.g., "1/4", "2/4", etc.
# CACHE_DIR="$CACHE_DIR/cache_$(echo $SPLIT | sed 's/\//_/g')"
# echo "CURRENT SPLIT: $SPLIT"
# echo "CACHE_DIR: $CACHE_DIR"

# ========== Worker Configuration ==========
NUM_WORKERS=16  # Number of workers for caching

python nuplan_extent/planning/script/run_training.py \
    group=$SAVE_DIR \
    cache.cache_path=$CACHE_DIR \
    experiment_name=$EXPERIMENT \
    job_name=$JOB_NAME \
    cache.force_feature_computation=false \
    cache.versatile_caching=false \
    py_func=cache \
    +caching=cache_nuplan_nexus \
    scenario_builder=nuplan \
    scenario_builder.data_root=$NUPLAN_DATA_ROOT \
    scenario_builder.map_root=$NUPLAN_MAPS_ROOT \
    scenario_builder.sensor_root=$NUPLAN_SENSOR_ROOT \
    +scenario_filter.limit_total_scenarios=2000 \
    scenario_builder.scenario_mapping.subsample_ratio_override=1.0 \
    worker=single_machine_thread_pool \
    worker.use_process_pool=true \
    worker.max_workers=16
    # +split=$SPLIT
