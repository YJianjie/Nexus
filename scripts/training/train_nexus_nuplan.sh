#!/usr/bin/env bash

# ========== Logging & Experiment Settings ==========
SAVE_DIR=/zeron-vepfs/tjqc/jianjie.ye/Nexus/models                    # Where logs and checkpoints will be saved
EXPERIMENT=nuplan_mini           # Experiment name
JOB_NAME=try                    # Job name used for logging/checkpoints

# ========== Cache Settings ==========
# CACHE_DIR=/zeron-vepfs/tjqc/jianjie.ye/Nexus/cache/nuplan_trainval_cache                  # Path to cache directory
CACHE_DIR=/zeron-vepfs/tjqc/jianjie.ye/Nexus/cache/nuplan_mini_cache                  # Path to cache directory
# CACHE_META_PATH=/zeron-vepfs/tjqc/jianjie.ye/Nexus/cache/nuplan_trainval_cache/metadata/nuplan_trainval_cache_metadata_node_0.csv      # Path to cache metadata CSV
CACHE_META_PATH=/zeron-vepfs/tjqc/jianjie.ye/Nexus/cache/nuplan_mini_cache/metadata/nuplan_mini_cache_metadata_node_0.csv      # Path to cache metadata CSV

# ========== NuPlan Dataset Paths ==========
export NUPLAN_DEVKIT_PATH="/zeron-vepfs/tjqc/jianjie.ye/Nexus/third_party/nuplan-devkit"      # Path to nuplan-devkit repo
export NUPLAN_SENSOR_ROOT="tj-share/nuscenes/nuplan/dataset/nuplan-v1.1/sensor_blobs"      # Path to sensor blobs
# export NUPLAN_DATA_ROOT="/dev/shm/nuplan_root/nuplan-v1.1/splits/mini"          # Path to train/val split data
export NUPLAN_DATA_ROOT="/zeron-vepfs/tjqc/public_datasets/nuplan/nuplan-v1.1/mini"          # Path to train/val split data
# export NUPLAN_MAPS_ROOT="/tj-share/nuscenes/nuplan/dataset/maps"          # Path to map files
export NUPLAN_MAPS_ROOT="/zeron-vepfs/tjqc/public_datasets/nuplan/maps"          # Path to map files

# ========== Training Configuration ==========
NUM_GPUS=4
BATCH_SIZE_PER_GPU=16
NUM_ACCUM_BATCHES=$((1024 / BATCH_SIZE_PER_GPU / NUM_GPUS))
# NUM_WORKERS=$((BATCH_SIZE_PER_GPU * NUM_GPUS))      # Adjust based on hardware
NUM_WORKERS=4               # Set manually if needed

# ========== Python Environment ==========
export PYTHONPATH=$PWD:$PYTHONPATH
export PYTHONPATH=$NUPLAN_DEVKIT_PATH:$PYTHONPATH

# ========== Weights & Biases ==========
export WANDB_PROJECT="YOUR_WANDB_PROJECT"
export WANDB_EXP_NAME="YOUR_WANDB_EXP_NAME"
export WANDB_ENTITY="YOUR_WANDB_ENTITY"

# lightning.trainer.params.profiler=simple:查看函数运行时间，可选值为 simple, pytorch, pytorch_profiler, none
python -W ignore $PWD/nuplan_extent/planning/script/run_training.py \
    group=$SAVE_DIR \
    cache.cache_path=$CACHE_DIR \
    cache.cache_metadata_path=$CACHE_META_PATH \
    cache.force_feature_computation=false \
    cache.use_cache_without_dataset=true \
    cache.versatile_caching=false \
    experiment_name=$EXPERIMENT \
    job_name=$JOB_NAME \
    py_func=train \
    seed=0 \
    +training=training_nuplan_nexus \
    scenario_builder=nuplan \
    scenario_builder.data_root=$NUPLAN_DATA_ROOT \
    lightning.trainer.params.max_epochs=350 \
    lightning.trainer.params.max_time=14:32:00:00\
    lightning.trainer.params.gradient_clip_val=1.0 \
    lightning.trainer.params.num_sanity_val_steps=0 \
    lightning.trainer.params.strategy=ddp_find_unused_parameters_true \
    lightning.trainer.params.fast_dev_run=false\
    lightning.trainer.params.detect_anomaly=false \
    lightning.trainer.params.log_every_n_steps=10\
    lightning.trainer.params.profiler=simple \
    lightning.trainer.checkpoint.monitor=loss/train_loss \
    +lightning.trainer.overfitting.enable=false \
    +lightning.trainer.overfitting.params.overfit_batches=0 \
    +lightning.trainer.params.val_check_interval=1.0 \
    lightning.trainer.params.accumulate_grad_batches=$NUM_ACCUM_BATCHES\
    data_loader.params.batch_size=$BATCH_SIZE_PER_GPU \
    data_loader.params.num_workers=$NUM_WORKERS \
    data_loader.params.pin_memory=true \
    worker=single_machine_thread_pool \
    model=nexus \
    optimizer=adamw \
    optimizer.lr=1e-3 \
    optimizer.weight_decay=0.01 \
    scenario_filter=all_scenarios \
    lr_scheduler=warmup_cos_lr \
    +lightning.trainer.resume_training=true \
    +checkpoint.resume=true \
    +checkpoint.strict=true \
    +checkpoint.ckpt_path=null