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
    Grand_Junction_2019
 
for example: \"sh 16_jobs.sh Japan_Antarctica_Project\""
    exit
fi

project_name=$1

job_list_prefix="txt.job_list_${project_name}__"

sh create_job_txt.sh ${project_name}
for i in {00..15}; do
    eval "sbatch batch_process.job ${job_list_prefix}${i}"
done
