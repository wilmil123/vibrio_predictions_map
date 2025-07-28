import argparse
import glob
import os
import copernicusmarine
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

parser = argparse.ArgumentParser()
parser.add_argument('--home_dir')
parser.add_argument('--out_dir')
parser.add_argument('--raster_dir')
parser.add_argument('--user')
parser.add_argument('--pwd')
args = parser.parse_args()

home_dir = args.home_dir
out_dir = args.out_dir
raster_dir = args.raster_dir
copern_user = args.user
copern_pwd = args.pwd
print("Successfully parsed command line arguments.")

time_now = datetime.now()
time_now = time_now.replace(tzinfo=ZoneInfo("America/Moncton"))
yest_date = time_now - timedelta(1)

# clear folders
copern_folder_contents = glob.glob(f"{out_dir}/*")
for file in copern_folder_contents:
    os.remove(file)

raster_folder_contents = glob.glob(f"{raster_dir}/*")
for file in raster_folder_contents:
    os.remove(file)

print("Successfully cleared folders.")

# log in
copernicusmarine.login(
    username = copern_user,
    password = copern_pwd,
    force_overwrite = True
)

# sailinity/so
copernicusmarine.subset(
  dataset_id="cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m",
  variables=["so"],
  minimum_longitude=-70,
  maximum_longitude=-55,
  minimum_latitude=42,
  maximum_latitude=51,
  start_datetime=f"{yest_date}T00:00:00",
  end_datetime=f"{yest_date}T00:00:00",
  minimum_depth=0.49402499198913574,
  maximum_depth=0.49402499198913574,
  output_filename = f"salinity_{yest_date.strftime('%Y-%m-%d')}.nc",
  output_directory = out_dir,
)

# sst/thetao
copernicusmarine.subset(
  dataset_id="cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m",
  variables=["thetao"],
  minimum_longitude=-70,
  maximum_longitude=-55,
  minimum_latitude=42,
  maximum_latitude=51,
  start_datetime=f"{yest_date}T00:00:00",
  end_datetime=f"{yest_date}T00:00:00",
  minimum_depth=0.49402499198913574,
  maximum_depth=0.49402499198913574,
  output_filename = f"temperature_{yest_date.strftime('%Y-%m-%d')}.nc",
  output_directory = out_dir
)
