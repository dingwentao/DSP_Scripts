#! /usr/bin/env bash
# use chmod +x AdrParallelScript.sh
numberofProcessors=$1
jobstxt=$2
joblog=${jobstxt/.txt/}-$(date +"%y%m%d-%H%M%S").log

export PATH=/home/.MATLAB/R2018a/bin:$PATH  #change to your path

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
    nohup matlab -nodisplay -nodesktop -r "arena_data_reader_batch($twofiles);exit"
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
