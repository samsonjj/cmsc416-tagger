# This program is designed to score a POS tagging created by tagger.pl of the same project
# Reports overall accuracy and confusion matrix
#
# Example execution:
#   perl scorer.pl pos-test-with-tags.txt pos-test-key.txt > pos-tagging-report.txt

use strict;
use warnings;
use feature 'say';


# Confusion Matrix, in which we record occurences of ACTUAL classes vs PREDICTED classes
# Example: VB -> NN -> 3 means that when comparing the key file to the tagged (predicted) file, VB's were predicted to be NN's 3 times
my %confusionMatrix = ();
# Used to record a list of tags, for presentation of confusion matrix later
my %tagList = ();


# Read in file names
my $argCount = scalar @ARGV;

# Die if there are less than two files entered
if( $argCount < 2 ) {
    die "Please enter two files as input arguments";
}
my $taggedFile = $ARGV[0];
my $keyFile = $ARGV[1];

#
# Open files.
#
open(my $fhTagged, '<:encoding(UTF-16)', $taggedFile)
    or die "Coult not open file '$taggedFile' $!";
open(my $fhKey, '<', $keyFile)
    or die "Coult not open file '$keyFile' $!";


#
# Load word/tag pairs into memory.
#
my @taggedTags = ();
my @keyTags = ();

while( my $line = <$fhTagged> ) {

    # Get rid of square brackets.
    $line =~ s/[\[\]]//g;
    # Get rid of newline character.
    chomp $line;
    # Get rid of trailing whitespace
    $line =~ s/^\s+|\s+$//g;
    # Seperate each token/tag pair
    my @array = split(/\s+/, $line);
    
    for my $pair ( @array ) {
        # Split up the word and tag
        my @parts = split(/\//, $pair);
        
        push( @taggedTags, $parts[1] );
    }
}
while( my $line = <$fhKey> ) {

    # Get rid of square brackets.
    $line =~ s/[\[\]]//g;
    # Get rid of newline character.
    chomp $line;
    # Get rid of trailing whitespace
    $line =~ s/^\s+|\s+$//g;
    # Seperate each token/tag pair
    my @array = split(/\s+/, $line);
    
    for my $pair ( @array ) {
        # Split up the word and tag
        my @parts = split(/\//, $pair);
        
        push( @keyTags, $parts[1] );
    }
}

my $lengthTagged = scalar @taggedTags;
my $lengthKey = scalar @keyTags;
if( $lengthTagged != $lengthKey ) {
    die "An error occured when parsing files where an unequal number of tokens was read from each."
}

# Record total number of correct guesses
my $correct = 0;

for( my $i=0; $i<$lengthTagged; $i++ ) {

    # Check if tag is correct. Increase $correct count if so.
    if( $taggedTags[$i] eq $keyTags[$i] ) {
        $correct++;
    }

    # If the tag/key count exists, increment it. Otherwise, set the count to 1.
    # Represents how many times we have seen the tag from taggedFile when predicting the tag from keyFile
    if( exists $confusionMatrix{$taggedTags[$i]} && exists $confusionMatrix{$taggedTags[$i]}{$keyTags[$i]}) {
        $confusionMatrix{$taggedTags[$i]}{$keyTags[$i]}++;
    }
    else {
        $confusionMatrix{$taggedTags[$i]}{$keyTags[$i]} = 1;
    }

    # If we have not seen either of these tags yet, add it to the tag list.
    if( !exists $tagList{$taggedTags[$i]} ) {
        $tagList{$taggedTags[$i]} = 0;
    }
    if( !exists $tagList{$keyTags[$i]} ) {
        $tagList{$keyTags[$i]} = 0;
    }
}

for my $tag (keys %tagList) {
    say $tag;
}

print "correct: $correct\n";

my $accuracy = $correct / $lengthTagged;
print "accuracy: $accuracy";