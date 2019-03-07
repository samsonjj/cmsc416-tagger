# This program creates a model based on input train file and outputs a tag sequence based on the next test file.
# perl tagger.pl pos-train.txt pos-test.txt > pos-test-with-tags.txt

use strict;
use warnings;
use feature 'say';

my $trainFile = "PA3/pos-train.txt";
my $testFile = "pA3/pos-test.txt";
# Multi-layer hash which contains at the top level the different tokens found in the train file.
# The next level contains hashes the different possible tags for the word in question, paired with its frequency
my %tokens = ();

#
# DEAL WITH TRAIN FILE
#
open(my $fhTrain, '<:encoding(UTF-8)', $trainFile)
    or die "Coult not open file '$trainFile' $!";

# Iterate through each line in the training file
while( my $line = <$fhTrain> ) {

    # Get rid of square brackets.
    $line =~ s/[\[\]]//g;
    # Get rid of newline character.
    chomp $line;
    # Get rid of trailing whitespace
    $line =~ s/^\s+|\s+$//g;
    # Seperate each token/tag pair
    my @array = split(/\s+/, $line);

    # Process each string into the hash
    for my $pair ( @array ) {
        # Split up the word and tag
        my @parts = split(/\//, $pair);
        
        if( exists $tokens{$parts[0]} && exists $tokens{$parts[0]}{$parts[1]} ) {
            $tokens{$parts[0]}{$parts[1]}++; 
        }
        else {
            $tokens{$parts[0]}{$parts[1]} = 1;
        }
    }
}

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
open(my $fhTest, '<', $testFile)
    or die "Coult not open file '$testFile' $!";

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