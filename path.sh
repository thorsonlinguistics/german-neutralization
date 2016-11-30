# The root directory of Kaldi
export KALDI_ROOT=`pwd`/../../../../

# Utils in Kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH

# Make sure that the tools are installed
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 \
  "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" \
  && exit 1

# Export the common path
. $KALDI_ROOT/tools/config/common_path.sh

# Use C-style sorting
export LC_ALL=C
