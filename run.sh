#!bin/bash

HOME_DIR=/vibrio_predictions_map/
PY_OUT_DIR=/vibrio_predictions_map/env_params
RF_MODELS_DIR=/vibrio_predictions_map/rf_models
R_OUT_DIR=/vibrio_predictions_map/raster_predictions
USERNAME=wmchapman@mta.ca
PASSWORD=Hygrometer16!

python3.12 ~/Documents/school/ecab/2025/vibrio_predictions_map/fetch_env_params.py --home_dir $HOME_DIR --out_dir $PY_OUT_DIR --raster_dir $R_OUT_DIR --user $USERNAME --pwd $PASSWORD
Rscript ~/Documents/school/ecab/2025/vibrio_predictions_map/make_vib_predictions.R --raster_dir $PY_OUT_DIR --model_dir $RF_MODELS_DIR --out_dir $R_OUT_DIR
