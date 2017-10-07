#!/bin/bash

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'Usage:'
    echo 'run_notebook.sh <arg1: session ID> <arg2: HERA_plots/ path>'
    echo ''
    echo 'argument1 : the ID of the session to process'
    echo 'argument2 : path to HERA_plots/ directory'
    exit 0
fi

if [ -z "$1" ] ; then
    echo "arg1 is blank"
    exit 1
fi

if [ -z "$2" ] ; then
    echo "arg2 is blank"
    exit 1
fi

# Exit with an error if any sub-command fails.

set -e

# Create a temporary Lustre directory for exporting the data and command the
# Librarian to populate it.

sessid="$1"
staging_dir=$(mktemp -d --tmpdir=/lustre/aoc/projects/hera/nightlynb sessid$sessid_XXXXXX)
chmod ug+rwx "$staging_dir"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.HH.uv\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.HH.uvOR\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.json\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.calfits\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

DATA_PATH=

for item in "$staging_dir"/2* ; do
    if [ -n "$DATA_PATH" ] ; then
        echo >&1 "WARNING: multiple subdirectories staged? $DATA_PATH, $item"
        exit 1
    fi
    if [ "$(basename $item)" == "2*" ] ; then
        echo >&1 "WARNING: no subdirectory staged: $item"
        exit 1
    fi
    export DATA_PATH="$item"
done

jd=$(basename $DATA_PATH)

# get more env vars
BASENBDIR=$2
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=$2

# copy and run notebook
jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT \
  --to notebook \
  --ExecutePreprocessor.allow_errors=True \
  --ExecutePreprocessor.timeout=-1 \
  --execute $BASENBDIR/Data_Inspect.ipynb

exit 0
# cd to git repo
cd $OUTPUTDIR

# add to git repo
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push

sed -e 's/@@JD@@/'$jd'/g' < mail_template.txt > mail.txt
sendmail -vt < mail.txt

rm -rf "$staging_dir"
