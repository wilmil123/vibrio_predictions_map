#!bin/bash

HOME_DIR=./
PY_OUT_DIR=./env_params
RF_MODELS_DIR=./rf_models
R_OUT_DIR=./raster_predictions

python3.12 ./fetch_env_params.py --home_dir $HOME_DIR --out_dir $PY_OUT_DIR --raster_dir $R_OUT_DIR --user $USERNAME --pwd $PASSWORD
Rscript ./make_vib_predictions.R --raster_dir $PY_OUT_DIR --model_dir $RF_MODELS_DIR --out_dir $R_OUT_DIR
