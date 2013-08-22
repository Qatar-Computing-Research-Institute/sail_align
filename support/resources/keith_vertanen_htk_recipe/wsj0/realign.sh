
# This script takes a given HMM model set and realigns our transcriptions
# to create an updated phone and triphone level MLFs.
#
# Parameters:
#    1 - Directory name of HMM model set to use.
#    2 - HMM list to use

cd $WSJ0_DIR

# HVite parameters:
#  -l       Path to use in the names in the output MLF
#  -o SWT   How to output labels, S remove scores, 
#           W do not include words, T do not include times
#  -b       Use this word as the sentence boundary during alignment
#  -C       Config files
#  -a       Perform alignment
#  -H       HMM macro definition files
#  -i       Output to this MLF file
#  -m       During recognition keep track of model boundaries
#  -t       Enable beam searching
#  -y       Extension for output label files
#  -I       Word level MLF file
#  -S       File contain the list of MFC files

HVite -B -A -T 1 -l '*' -o SWT -b silence -C $TRAIN_COMMON/config -a -H $TRAIN_WSJ0/$1/macros -H $TRAIN_WSJ0/$1/hmmdefs -i $TRAIN_WSJ0/aligned.mlf -m -t 250.0 -I $TRAIN_WSJ0/words.mlf -S train.scp $TRAIN_TIMIT/cmu6spsil $2 >$TRAIN_WSJ0/hvite_align.log

# We'll get a "sp sil" sequence at the end of each sentance.  Merge these
# into a single sil phone.  Also might get "sil sil", we'll merge anything
# combination of sp and sil into a single sil.
HLEd -A -T 1 -l '*' -i $TRAIN_WSJ0/aligned2.mlf $TRAIN_WSJ0/merge_sp_sil.led $TRAIN_WSJ0/aligned.mlf >$TRAIN_WSJ0/hled_sp_sil.log

# We may get context dependent phones forced aligned along word boundaries,
# so we'll convert back to monophones and create a new triphone MLF from
# the monophone labels.  This would only be needed if the models used in
# alignment were not monophones to begin with.
perl $TRAIN_SCRIPTS/ConvertToMono.pl $TRAIN_WSJ0/aligned2.mlf >$TRAIN_WSJ0/mono.mlf

# This converts the monophone MLF into a word internal triphone MLF.
# Note that this realignment could could the triphones1 file to change
# what it contains since we make switch to different pronouciations for
# certain words in the training set.
HLEd -A -T 1 -n $TRAIN_WSJ0/triphones1 -l '*' -i $TRAIN_WSJ0/wintri.mlf $TRAIN_WSJ0/mktri.led $TRAIN_WSJ0/mono.mlf >$TRAIN_WSJ0/hled_make_tri.log

# Forced alignment might fail for a few files, these will be missing
# from the MLF, so we need to prune these out of the script so we don't try 
# and train on them.
cp $WSJ0_DIR/train.scp $WSJ0_DIR/train_temp.scp
perl $TRAIN_SCRIPTS/RemovePrunedFiles.pl $TRAIN_WSJ0/aligned2.mlf $WSJ0_DIR/train_temp.scp >$WSJ0_DIR/train.scp
rm -f $WSJ0_DIR/train_temp.scp


