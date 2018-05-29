#!/bin/bash
# export the variables created in '.env'
set -a
source .env
set +a

# echo $TEGOLA_PORT

expire_dir=$IMPOSM3_EXPIRE
# this will be essentially treated as a pidfile
queued_jobs="./in_progress.list"
# output of seeded
completed_jobs="./completed.list"
# a directory to place the worked expiry lists
# THIS MUST BE OUTSIDE OF $expire_dir
completed_dir=$IMPOSM3_EXPIRE_PURGED

# assert no other jobs are running
if [[ -f $queued_jobs ]]; then
  echo "$queued_jobs exists, is another seed process running?"
  exit
else
  touch $queued_jobs
  if [[ ! $? ]]; then
    echo "error writing queue list, exiting"
    rm $queued_jobs
    exit
  fi
fi

# en existance of completed directory
if [[ ! -d $completed_dir ]]; then
  echo "$completed_dir directory not found"
  echo "mkdir $completed_dir"
  mkdir $completed_dir
fi

# files newer than this amount of seconds will
# not be used for this job
imp_time="0.1" # minutes
# sleep $imp_time"m"
imp_list=`find $expire_dir -type f -mmin +$imp_time`

for f in $imp_list; do
  echo "$f" >> $queued_jobs
done

for f in $imp_list; do
  echo "seeding from $f"
  echo "tegola-issue-214 cache seed --config="tegola-env-bake.toml" --tile-list="$(echo $f)" --tile-name-format="/zxy" --min_zoom=4 --max_zoom=14 --overwrite"
  tegola-issue-214 cache seed --config="tegola-env-bake.toml" --tile-list="$(echo $f)" --tile-name-format="/zxy" --min_zoom=4 --max_zoom=14 --overwrite
  err=$?
  if [[ $err != "0" ]]; then
    #error
    echo "tegola exited with error code $err"
    # rm $queued_jobs
    exit
  fi

  echo "$f" >> $completed_jobs
  mv $f $completed_dir
done

echo "finished seeding"
# rm $queued_jobs
