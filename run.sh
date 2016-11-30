#!/bin/bash

set -e

# Import the configuration
source ./config.sh

# Import the necessary path variables
source ./path.sh

# Prepare the data from the corpus. This automatically generates the data which
# Kaldi requires to train, including the lexicon, transcript files, etc. 
local/vm1_data_prep.py $VM $VM_DOC

# Finishes language preparation for Kaldi from the automatically generated
# files. 
utils/prepare_lang.sh data/local/dict '!SIL' data/local/lang data/lang

# Prepares the default language model, which is a simple unigram grammar.
mkdir -p data/local/tmp/
utils/make_unigram_grammar.pl < data/train_ambiguous/raw_text \
  > data/local/tmp/G.txt
local/vm1_prepare_grammar.sh

# Create the feature directory; the name of this directory is defined in
# config.sh.
if [ ! -d $featdir ]; then
  mkdir $featdir
fi

# Generates the features for each of the training and testing directories.
for x in test_ambiguous test_unambiguous train_ambiguous train_unambiguous; do
  steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/$x exp/make_feat/$x $featdir
  steps/compute_cmvn_stats.sh data/$x exp/make_feat/$x $featdir
done

##### MONOPHONE MODEL

# Trains a monophone model on a small sample of unambiguous data to get
# started.
utils/subset_data_dir.sh data/train_unambiguous 1000 data/train_unambiguous.1k
steps/train_mono.sh --nj 4 --cmd "$train_cmd" data/train_unambiguous.1k \
  data/lang exp/mono

# Aligns the ambiguous data for testing using the monophone model.
steps/align_si.sh --nj 8 --cmd "$train_cmd" data/test_ambiguous \
  data/lang exp/mono exp/mono_ambi_ali

# Aligns the unambiguous data for future use using the monophone model.
steps/align_si.sh --nj 8 --cmd "$train_cmd" data/train_unambiguous \
  data/lang exp/mono exp/mono_ali

# Decodes the ambiguous test data with the monophone model.
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph
steps/decode.sh --config conf/decode.config --nj 8 --cmd "$decode_cmd" \
  exp/mono/graph data/test_ambiguous exp/mono/decode

##### TRIPHONE MODEL

# Constructs a basic triphone model using the unambiguous data and the
# monophone alignments.
steps/train_deltas.sh --cmd "$train_cmd" 1800 9000 data/train_unambiguous \
  data/lang exp/mono_ali exp/tri1

# Aligns the ambiguous data for testing using the triphone model.
steps/align_si.sh --nj 8 --cmd "$train_cmd" \
  data/test_ambiguous data/lang exp/tri1 exp/tri1_ambi_ali

# Aligns the unambiguous data for future use using the triphone model.
steps/align_si.sh --nj 8 --cmd "$train_cmd" \
  data/train_unambiguous data/lang exp/tri1 exp/tri1_ali

# Decodes the ambiguous test data with the triphone model.
utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph
steps/decode.sh --config conf/decode.config --nj 8 --cmd "$decode_cmd" \
  exp/tri1/graph data/test_ambiguous exp/tri1/decode

##### LDA+MLLT MODEL

# Constructs a more complex triphone model using LDA+MLLT.
steps/train_lda_mllt.sh --cmd "$train_cmd" \
  --splice-opts "--left-context=3 --right-context=3" \
  1800 9000 data/train_unambiguous data/lang exp/tri1_ali exp/tri2b
utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph

# Decodes the ambiguous test data using the LDA+MLLT triphone model.
steps/decode.sh --config conf/decode.config --nj 20 --cmd "$decode_cmd" \
  exp/tri2b/graph data/test_ambiguous exp/tri2b/decode

# Aligns the ambiguous data for testing using the advanced triphone model.
steps/align_si.sh --nj 8 --cmd "$train_cmd" \
  data/test_ambiguous data/lang exp/tri2b exp/tri2b_ambi_ali
