# Author: Jonathan Samson
# Date: March 12, 2019
# Class: CMSC 416-001 Spring 2019, Virginia Commonwealth University 
#
# PROGRAM SUMMARY
# This program creates a tagging model based on specified train file and outputs a tagged version of the specified test file.
#
# PROBLEM STATEMENT
# Part of speech tagging (POS tagging) is a very important problem in NLP. The problem consists of
# taking a sample text and marking each word with it's part of speech according to its usage in the
# text. For example, the sentence "That is a dog" might be tagged to become "That/PRONOUN is/VERB
# a/DETERMINER dog/NOUN". The possible tags are chosen from a tag set. The golden standard for POS
# tagging is that which is performed by a human, and reaches 100% accuracy. The baseline standard
# is that which chooses the most likely tag based only on the given word, using some corpus to find
# these probabilities. The baseline standard is implemented in this program.
#
# EXAMPLE USAGE
# We might have a large training file pos-train.txt which consists of many tagged sentences following the below style:
#   [ Pierre/NNP Vinken/NNP ]
#   ,/, 
#   [ 61/CD years/NNS ]
#   old/JJ ,/, will/MD join/VB 
#   [ the/DT board/NN ]
#   as/IN 
#   [ a/DT nonexecutive/JJ director/NN Nov./NNP 29/CD ]
#   ./. 
#
# We might also have a test file pos-test.txt which looks like the following:
#   No , 
#   [ it ]
#   [ was n't Black Monday ]
#   . 
#
# Running the following command uses data from pos-train.txt to tag pos-test.txt and produces the output that follows:
#   (IN)  perl tagger.pl pos-train.txt pos-test.txt
#   (OUT) No/DT ,/,
#   (OUT) [ it/PRP ]
#   (OUT) [ was/VBD n't/RB Black/NNP Monday/NNP ]
#   (OUT) ./.

# ALGORITHM
# The program follows the following steps, which are marked with comments throughout the program.
# (1) Open the two files provided as command line arguemnts 1 (train file) and 2 (train test).
# (2) Iterate through each line in the training file and create tagging model.
#   a. Tokenize the lines into token/tag pairs.
#   b. Adjust the count of each token/tag pair in the %tokens hash.
# (3)
# When creating our model (probability distribution) if a word has multiple possible tags, we add 1 to the frequency for both

use strict;
use warnings;
use feature 'say';

#################### (1) ####################

# Get number of command line arguments.
my $argCount = scalar @ARGV;

# If the user did not enter enough arguments, quit.
if( $argCount < 2 ) {
    die "Please enter two files as input arguments";
}

# Read in command line arguments (file names).
my $trainFile = $ARGV[0];
my $testFile = $ARGV[1];

# Open training file.
open(my $fhTrain, '<:encoding(UTF-8)', $trainFile)
    or die "Coult not open file '$trainFile' $!";

# Open test file.
open(my $fhTest, '<', $testFile)
    or die "Coult not open file '$testFile' $!";


#################### (2) ####################

# Initialize token hash.
# %tokens: Multidimensional hash which stores the frequency for each tag for each token.
# Example: $frequency = %tokens{$token}{$tag};
my %tokens = ();

# Iterate through each line in the training file, adjusting counts of different token/tag pairs as they are found.
while( my $line = <$fhTrain> ) {

    # Get rid of square brackets (phrase boundry markers), which are unnecessary for POS tagging.
    $line =~ s/[\[\]]//g;

    # Get rid of newline characters and trailing whitespace.
    chomp $line;
    $line =~ s/^\s+|\s+$//g;

    # Create array of token/tag pairs, splittings by whitespace.
    my @array = split(/\s+/, $line);

    # Process each token/tag pair into the hash.
    for my $pair ( @array ) {

        # Split up the word and tag, by the forward slash.
        my @parts = split(/\//, $pair);

        # Forward slashes within the text can cause the pair to be split too many times.
        # Combine parts until we have only two (word and tag).
        my $partsLength = scalar @parts;
        while( $partsLength > 2 ) {
            $parts[1] = $parts[0].$parts[1];
            shift @parts;
            $partsLength = scalar @parts;
        }
        
        # It is possible a word might have multiple tags, Example: "more/JJR|RBR".
        # Adjust the frequency for each tag.
        my $word = $parts[0];
        my @tags = split( /\|/, $parts[1] );
        for my $tag (@tags) {
            # If we have the pair stored already, increment frequency.
            if( exists $tokens{$word} && exists $tokens{$word}{$tag} ) {
                $tokens{$word}{$tag}++; 
            }
            # Otherwise, set frequency to 1.
            else {
                $tokens{$word}{$tag} = 1;
            }
        }
    }
}


#################### (3) ####################

# Change frequency counts within the hash to probabilities
# Example: (2, 3, 5) turns into (.2, .3, .5)
for my $word ( keys %tokens ) {

    # Store the max frequency of the tags associated with this word
    my $maxFrequency = 0;
    # Store max tag
    my $maxTag = "";

    # Iterate through each tag's count, and change max if new max found
    for my $tag ( keys %{ $tokens{$word} } ) {
        # Test if max
        if( $tokens{$word}{$tag} > $maxFrequency ) {
            # If max, record tag and frequency
            $maxTag = $tag;
            $maxFrequency = $tokens{$word}{$tag};
        }
    }

    # Store a new key/value pair [key = "max", value = maxTag], to be used later
    $tokens{$word}{"max"} = $maxTag;
}

# for my $word ( keys %tokens ) {
#     say "$word";

#     # Iterate through each tag's count and add to totalFrequency
#     for my $tag ( keys %{ $tokens{$word} } ) {
#         say "  $tag -> $tokens{$word}{$tag}";
#     }
# }

#
# TAG THE TEST FILE
#

while( my $line = <$fhTest> ) {
    
    # Keep track of if there were square brackets
    my $brackets = 0;

    # Get rid of square brackets.
    if( $line =~ s/[\[\]]//g ) {
        $brackets = 1;
    }
    # Get rid of newline character.
    chomp $line;
    # Get rid of trailing whitespace
    $line =~ s/^\s+|\s+$//g;
    # Seperate each token
    my @array = split(/\s+/, $line);


    # Keep track if we are on the first word of the array (for spacing purposes)
    my $first = 1;
    if( $brackets == 1 ) {
        print "[ ";
    }
    for my $token (@array) {
        print " " if $first == 0;
        print "$token/";
        if( exists $tokens{$token} ) {
            print $tokens{$token}{"max"};
        }
        else {
            print "NN";
        }
        $first = 0;
    }
    if( $brackets == 1 ) {
        print " ]";
    }

    print "\n";
}


# Example of rule:
# Eliminate VBN if VBD is an option when VBN|VBD follows "<start> PRP"