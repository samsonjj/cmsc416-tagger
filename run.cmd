perl tagger.pl pos-train.txt pos-test.txt > pos-test-with-tags.txt
perl scorer.pl pos-test-with-tags.txt pos-test-key.txt