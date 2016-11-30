# German Incomplete Neutralization in Kaldi

The code in this repository can be used to identify phonetic and phonological
patterns in German word-final neutralization using Kaldi ASR. The included
experiments test the distribution of incomplete neutralization, complete
neutralization, and no neutralization (that is, voiceless, partially voiced,
and voiced consonants) in word-final position by using ASR to identify phones
in word-final position. The model is trained to assume that underlyingly voiced
consonants are always realized as semi-voiced consonants in word-final
position. However, the model is able to learn the features of fully voiced and
fully voiceless consonants from other contexts. It is then asked to determine
the distribution of these phones in the given environments.

## Systems Supported

Because this system uses bash scripting, it is generally restricted to Unix
systems (including Mac OS X), though it may also be possible to get it working
on Windows under Cygwin.

## Installation

The incomplete neutralization experiments use Kaldi ASR for training the model
and MATLAB for analyzing it. 

- To install Kaldi ASR, follow the instructions at [the Kaldi ASR
  documentation](http://kaldi-asr.org/doc/install.html).
- To purchase and install MATLAB, visit the MATLAB page at
  [Mathworks](https://www.mathworks.com/products/matlab).

It is also necessary to download the VM1 corpus and to unzip the documentation
contained within.

Once these have been installed, clone this repository.

    $ git clone https://github.com/thorsonlinguistics/german-neutralization.git

This can be put anywhere, but it is easiest to place it within Kaldi's `egs`
directory.

This will create a directory `german-neutralization` which contains the
following sub-directories. You do not need to take any action with these.

    - `german-neutralization/conf/` - configuration files for Kaldi-ASR
    - `german-neutralization/steps/` - useful scripts from Kaldi
    - `german-neutralization/utils/` - useful scripts from Kaldi

It will also create the following files:

    - `german-neutralization/config.sh` - local configuration
    - `german-neutralization/path.sh` - path variables
    - `german-neutralization/run.sh` - a script to run the model

It is necessary to modify `config.sh` and `path.sh` with paths pointing to your
installation of Kaldi, the VM1 corpus, and the VM1 documentation.
