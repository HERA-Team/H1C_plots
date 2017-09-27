#!/bin/bash 

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'run_notebook.sh <arg1: hera_data_dir> <opt1: xx.uvc file> <opt2: yy.uvc file>'
    echo 'argument1 : JD directory where visibility data *.uvc files live'
    echo 'option1 : specific miriad uv file to use for xx pol'
    echo 'option2 : specific miriad uv file to use for yy pol'
    exit 0
fi

# assign data directory
export DATA_PATH=$1

# get JD
jd=`python -c "print '${DATA_PATH}'.split('/')[-1]"`

# get more env vars
BASENBDIR=$HOME/HERA_plots
export CALFILE=hsa7458_v001
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=$HOME/HERA_plots

export UVFILE_XX=$2
export UVFILE_YY=$3

# copy and run notebook
jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT --to notebook --execute $BASENBDIR/Data_Inspect.ipynb

# cd to git repo
cd $OUTPUTDIR

# add to git repo
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push
