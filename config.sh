#!/bin/sh

# This file defines several environment variables which must be defined before
# the experiment can be run. For legal reasons, the contents of the corpus
# cannot be released publicly, so you will need to download it yourself.

# The root Verb-Mobil directory, which contains the various data subdirectories
VM=/projects/speech/corpus/VM1

# The Verb-Mobil documentation directory, which is initially a zipped file in
# the root.
VM_DOC=./vm1-doc/

# The directory in which to store the MFCC features. This will be created in
# the run process.
featdir=mfcc

# The training command to use. run.pl is good for basic usage.
train_cmd=run.pl

# The decode command to use. run.pl is good for basic usage.
decode_cmd=run.pl
