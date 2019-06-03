#! /usr/bin/env bash
numberofProcessors=$1
jobstxt=$2
joblog=${jobstxt/.txt/}-$(date +"%y%m%d-%H%M%S").log
chunk_size=64
code_dir="'/data/RSC_HPC/scripts'"


export PATH=/opt/ohpc/pub/apps/MATLAB/R2018a/bin:$PATH  #change to your path

set -o monitor 
# means: run background processes in a separate processes...
trap add_next_job CHLD 
# execute add_next_job when we receive a child complete signal

readarray todo_array < $jobstxt
index=0
max_jobs=$numberofProcessors
echo "Number of Process: " $max_jobs

function add_next_job {
    # if still jobs to do then add one
    if [[ $index -lt ${#todo_array[*]} ]]
    then
        echo adding job ${todo_array[$index]}
        do_job ${todo_array[$index]} & 
        index=$(($index+1))
    fi
}

function do_job {
    echo "starting job $1"
    STARTTIME=`date`
    twofiles=$1
    IFS=, read xmlpath datapath <<<$twofiles
    #echo $datapath
    datapath=${datapath#"'"};datapath=${datapath%"'"}
    #echo $datapath
    dat_dir="'$(dirname $datapath)'"
    dat_file="$(basename $datapath)"
    dat_filestem="'$(echo "$dat_file" | cut -f 1 -d '.')'"
    #echo $dat_dir
    #echo $code_dir
    #echo $dat_filestem
    #nohup matlab -nodisplay -nodesktop -nosplash -nojvm -r "arena_data_reader_batch($twofiles);exit"
    nohup matlab -nodisplay -nodesktop -nosplash -nojvm -r "Colorado_chunk_processor_water($dat_dir,$dat_dir,$code_dir,$dat_filestem,$chunk_size); exit"	
    ENDTIME=`date`
    echo "ADR job $twofiles completed"
    echo $1 $STARTTIME $ENDTIME>> $joblog
}

# add initial set of jobs
while [[ $index -lt $max_jobs ]]
do
    add_next_job
done

# wait for all jobs to complete
wait
echo "All jobs completed"
