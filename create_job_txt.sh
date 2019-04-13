#!/bin/bash

# J. Tian
# create: 19-04-12
# update: 19-04-12


if [ "$#" -ne 1 ]; then
    echo "enter only one (1) argument, which is project name, 

    Japan_Antarctica_Project
    Greeland_Project
    Dome_Fuji_2019_Sounder
    Dome_Fuji_2019_FMCW
    
for example: \"sh 16_jobs.sh Japan_Antarctica_Project\""
    exit
fi

project_name=$1

timestamp_file="txt.timestamps_${project_name}"

if [ -f ${timestamp_file} ]; then
    rm -f ${timestamp_file}
fi

if [ -f ${job_list} ]; then
    rm -f ${job_list}
fi

ls "/data/${project_name}" | grep -e "201[1|2]*"> ${timestamp_file}

job_list="txt.job_list_${project_name}"

echo "reading datasets under GPS timestamps"
while IFS='' read -r line || [[ -n "$line" ]]; do
  prefix="/data/${project_name}/${line}"
  # only when .dat exists can we execute commands
  for i in $(ls /data/${project_name}/${line} | grep dat$); do
    echo "'${prefix}/${line}_config.xml','${prefix}/${i}'" >> ${job_list}
  done
done < "${timestamp_file}"

echo "done reading all GPS timestamps"

line_count=$(grep -w "data" -c ${job_list})
line_per_file=$(echo "${line_count}/16 + 1" | bc)

echo "spliting into 16 files for scheduling"


rm -f txt.list_xml_dat_${project_name}__*
split -l ${line_per_file} -d ${job_list} ${job_list}__

rm -f ${job_list}
