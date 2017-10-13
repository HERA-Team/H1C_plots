#!/bin/bash

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'Usage:'
    echo 'export sessid=<sessid>'
    echo 'qsub -V -q hera run_notebook.sh'
    exit 0
fi

# get sessid (hacky way that only works until Nov. 30th)
cd /lustre/aoc/projects/hera/nkern/Software/HERA_plots
export sessid=$(./check_lib.py)

if [ -z "$sessid" ] ; then
    echo "environ variable 'sessid' is undefined"
    exit 1
fi

# Exit with an error if any sub-command fails.
set -e

# Create a temporary Lustre directory for exporting the data and command the
# Librarian to populate it.

staging_dir=$(mktemp -d --tmpdir=/lustre/aoc/projects/hera/nightlynb sessid$sessid.XXXXXX)
chmod ug+rwx "$staging_dir"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.HH.uv\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.HH.uvOR\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.json\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.calfits\"}"
librarian_stage_files.py --wait local "$staging_dir" "$search"

search="{\"session-id-is-exactly\": $sessid, \"name-matches\": \"%.flag_summary.npz\"}"
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
BASENBDIR=/lustre/aoc/projects/hera/nkern/Software/HERA_plots
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=/lustre/aoc/projects/hera/nkern/Software/HERA_plots

# copy and run notebook
echo "starting notebook execution..."

jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT \
  --to notebook \
  --ExecutePreprocessor.allow_errors=True \
  --ExecutePreprocessor.timeout=-1 \
  --execute $BASENBDIR/Data_Inspect.ipynb

echo "finished notebook execution..."

exit 0
# cd to git repo
cd $OUTPUTDIR

# add to git repo
echo "adding to GitHub repo"
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push

echo "sending email to heraops"
sed -e 's/@@JD@@/'$jd'/g' < mail_template.txt > mail.txt
sendmail -vt < mail.txt

echo "removing staging dir"
rm -rf "$staging_dir"

