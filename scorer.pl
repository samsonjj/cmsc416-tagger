# scorer.pl
#
# Title: Programming Assignment 3
# Author: Jonathan Samson
# Date: March 12, 2019
# Class: CMSC 416-001 Spring 2019, Virginia Commonwealth University 
#
# PROGRAM SUMMARY
# This program creates a scores a specified file which has been POS tagged, by comparing a against a specified key file.
#
# PROBLEM STATEMENT
# Part of speech tagging (POS tagging) is a very important problem in NLP. The problem consists of
# taking a sample text and marking each word with it's part of speech according to its usage in the
# text. For example, the sentence "That is a dog" might be tagged to become "That/PRONOUN is/VERB
# a/DETERMINER dog/NOUN". The possible tags are chosen from a tag set. The golden standard for POS
# tagging is that which is performed by a human, and reaches 100% accuracy. The baseline standard
# is that which chooses the most likely tag based only on the given word, using some corpus to find
# these probabilities. This program is designed to evaluate the accuracy of a specified file which
# has been POS tagged. It does so by comparing each of the tagged tokens against its correctly tagged
# counterpart in the specified key file. It prints the total accuracy (correct/total) to STDOUT, as
# well as the confusion matrix, which specifies the frequency of each tag prediction. 
#
# Example USAGE:
#   (IN ) perl scorer.pl pos-test-with-tags.txt pos-test-key.txt
#   (OUT) total: 56824
#   (OUT) correct: 48002
#   (OUT) accuracy: 0.844748697733352
#   (OUT) ACTUAL   | ``:
#   (OUT) PREDICTED|     ``-535       
#   (OUT) ACTUAL   | WRB:
#   (OUT) PREDICTED|     WRB-131      RB-1         NN-1         
#   (OUT) ACTUAL   | WP$:
#   (OUT) PREDICTED|     WP$-21       
#   (OUT) ACTUAL   | WP:
#   (OUT) PREDICTED|     WP-111       
#   (OUT) ACTUAL   | WDT:
#   (OUT) PREDICTED|     WP-1         WDT-139      NN-2         IN-138       
#   (OUT) ACTUAL   | VBZ:
#   (OUT) PREDICTED|     VBZ-1025     POS-77       NNS-34       NN-100       
#   (OUT) ACTUAL   | VBP:
#   etc...
#
# ALGORITHM
# The program follows the following steps, which are marked with comments throughout the program.
# (1) Open the two files provided as command line arguemnts 1 (Test File) and 2 (Key File).
# (2) Iterate through both files, tokenizing line by line and storing all tags in an array for each file.
# (3) Compare the arrays, counting the number of correct predictions, and storing each prediction in
#     the Confusion Matrix.
# (4) Print out total accuracy and confusion matrix contents.

use strict;
use warnings;
use feature 'say';


#################### (1) ####################

# Read in file names
my $argCount = scalar @ARGV;

# Die if there are less than two files entered
if( $argCount < 2 ) {
    die "Please enter two files as input arguments";
}
my $taggedFile = $ARGV[0];
my $keyFile = $ARGV[1];

# Open files.
open(my $fhTagged, '<:encoding(UTF-16)', $taggedFile)
    or die "Coult not open file '$taggedFile' $!";
open(my $fhKey, '<', $keyFile)
    or die "Coult not open file '$keyFile' $!";


#################### (2) ####################

# Initialize Confusion Matrix hash, in which we record frequency of ACTUAL classes vs PREDICTED tags.
# Example: VB -> NN -> 3 means that when comparing the key file to the tagged (predicted) file, VB's were predicted to be NN's 3 times.
my %confusionMatrix = ();
# Used to record a list of tags, for presentation of confusion matrix later
my %tagList = ();

# Initialize arrays for storing token/tag pairs.
my @taggedTags = ();
my @keyTags = ();

# Iterate through the lines of the tagged (test) file.
while( my $line = <$fhTagged> ) {

    # Get rid of square brackets.
    $line =~ s/[\[\]]//g;
    # Get rid of newline character and trailing whitespace.
    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    # Create array of token/tag pairs, splitting by whitespace.
    my @array = split(/\s+/, $line);
    
    # Process the tag out of each token/tag pair.
    for my $pair ( @array ) {

        # Split up the token and tag, by the forward slash.
        my @parts = split(/\//, $pair);

        # Forward slashes within the text can cause the pair to be split too many times.
        # Combine parts until we have only two (word and tag).
        my $partsLength = scalar @parts;
        while( $partsLength > 2 ) {
            $parts[1] = $parts[0].$parts[1];
            shift @parts;
            $partsLength = scalar @parts;
        }
        
        # Add tag to array.
        push( @taggedTags, $parts[1] );
    }
}

# Iterate through lines of the key file.
while( my $line = <$fhKey> ) {

    # Get rid of square brackets.
    $line =~ s/[\[\]]//g;
    # Get rid of newline character and trailing whitespace.
    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    # Create array of token/tag pairs, splitting by whitespace.
    my @array = split(/\s+/, $line);
    
    # Process the tag out of each token/tag pair.
    for my $pair ( @array ) {

        # Split up the word and tag.
        my @parts = split(/\//, $pair);

        # Forward slashes within the text can cause the pair to be split too many times.
        # Combine parts until we have only two (word and tag).
        my $partsLength = scalar @parts;
        while( $partsLength > 2 ) {
            $parts[1] = $parts[0].$parts[1];
            shift @parts;
            $partsLength = scalar @parts;
        }
        
        # Add the tag to the array.
        push( @keyTags, $parts[1] );
    }
}

# Check lengths of the two matrices. If they are unequal, files are not compatible or an error occured.
my $lengthTagged = scalar @taggedTags;
my $lengthKey = scalar @keyTags;
if( $lengthTagged != $lengthKey ) {
    die "An error occured when parsing files where an unequal number of tokens was read from each."
}


#################### (3) ####################

# Record total number of correct guesses.
my $correct = 0;

# Go through each tag in the test array, comparing to corresponding tag in the key array.
for( my $i=0; $i<$lengthTagged; $i++ ) {

    # Check if tag is correct. Increase $correct count if so.
    my @correctTags = split( /\|/, $keyTags[$i]);
    my %correctTags = map { $_ => 1 } @correctTags;
    if( exists $correctTags{$taggedTags[$i]} ) {
        $correct++;
    }

    # If the tag/key count exists, increment it. Otherwise, set the count to 1.
    # Represents how many times we have seen the tag from taggedFile when predicting the tag from keyFile
    if( exists $confusionMatrix{$keyTags[$i]} && exists $confusionMatrix{$keyTags[$i]}{$taggedTags[$i]}) {
        $confusionMatrix{$keyTags[$i]}{$taggedTags[$i]}++;
    }
    else {
        $confusionMatrix{$keyTags[$i]}{$taggedTags [$i]} = 1;
    }

    # If we have not seen either of these tags yet, add it to the tag list.
    if( !exists $tagList{$taggedTags[$i]} ) {
        $tagList{$taggedTags[$i]} = 0;
    }
    if( !exists $tagList{$keyTags[$i]} ) {
        $tagList{$keyTags[$i]} = 0;
    }
}

#################### (4) ####################

# Print total number of tags, and number correctly predicted.
print "total: $lengthTagged\n";
print "correct: $correct\n";

# Print accuracy.
my $accuracy = $correct / $lengthTagged;
print "accuracy: $accuracy\n";

# Print confusion matrix.
for my $actualTag (reverse sort keys %tagList) {
    print "ACTUAL   | $actualTag:\nPREDICTED|     ";
    my $count = 1;
    for my $predictedTag (reverse sort keys %tagList) {
        my $frequency = 0;
        $frequency = $confusionMatrix{$actualTag}{$predictedTag} if( exists $confusionMatrix{$actualTag}{$predictedTag} );
        if( $frequency != 0) {
            if( $count % 7 == 0) {
                print "\nPREDICTED|     ";
            }
            my $tagAndCount = "$predictedTag-$frequency";
            my $result = sprintf("%-12s ", $tagAndCount);
            print $result;
            $count++;
        }
    }
    print "\n";
}