#!/bin/bash

# D. Tao
# create: 19-05-07

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

timestamp_file="txt.timestamps_${project_name}"

dat_list="txt.dat_list_${project_name}"

mat_list="txt.mat_list_${project_name}"

if [ -f ${timestamp_file} ]; then
    rm -f ${timestamp_file}
fi

if [ -f ${dat_list} ]; then
    rm -f ${dat_list}
fi

if [ -f ${mat_list} ]; then
    rm -f ${mat_list}
fi

ls "/data/${project_name}" | grep -e "201[1|2]*"> ${timestamp_file}

echo "reading all .dat and .mat files"
while IFS='' read -r line || [[ -n "$line" ]]; do
  prefix="/data/${project_name}/${line}"
  # only when .dat exists can we execute commands
  for i in $(ls /data/${project_name}/${line} | grep dat$); do
	if [ -f ${prefix}/${line}_config.xml ]; then
		filename="${prefix}/${i}"
		echo "${filename%.*}" >> ${dat_list}
	fi
  done
  for i in $(ls /data/${project_name}/${line} | grep mat$); do
	if [ -f ${prefix}/${line}_config.xml ]; then
		filename="${prefix}/${i}"
		ext=$(echo "$filename" | rev | cut -d"_" -f1  | rev)
		if [ "$ext" != "counters.mat" ]; then
			echo "${filename%.*}" >> ${mat_list}
		fi
	fi
  done
done < "${timestamp_file}"

echo "done reading all .dat and .mat files"

checking_list="txt.checking_list_${project_name}"
diff $dat_list $mat_list > $checking_list

echo "done writing all checking results"

rm -f ${timestamp_file}
rm -f ${dat_list}
rm -f ${mat_list}
