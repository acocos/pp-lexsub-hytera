#!/usr/bin/perl -w

# Sample Tokenizer
# written by Josh Schroeder, based on code by Philipp Koehn

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use FindBin qw($Bin);
use strict;
#use Time::HiRes;

my $mydir = "./nonbreaking_prefixes";

my %NONBREAKING_PREFIX = ();
my $language = "en";
my $QUIET = 0;
my $HELP = 0;


my $use_penn_treebank_tokenization = 0;

#my $start = [ Time::HiRes::gettimeofday( ) ];

while (@ARGV) {
	$_ = shift;
	/^-l$/ && ($language = shift, next);
	/^-q$/ && ($QUIET = 1, next);
	/^-h$/ && ($HELP = 1, next);
}

if ($HELP) {
	print "Usage ./tokenizer.perl (-l [en|de|...]) < textfile > tokenizedfile\n";
	exit;
}
if (!$QUIET) {
	print STDERR "Tokenizer v3\n";
	print STDERR "Language: $language\n";
}

load_prefixes($language,\%NONBREAKING_PREFIX);

if (scalar(%NONBREAKING_PREFIX) eq 0){
	print STDERR "Warning: No known abbreviations for language '$language'\n";
}

while(<STDIN>) {
	if (/^<.+>$/ || /^\s*$/) {
		#don't try to tokenize XML/HTML tag lines
		print $_;
	}
	else {
		print &tokenize($_);
	}
}

#my $duration = Time::HiRes::tv_interval( $start );
#print STDERR ("EXECUTION TIME: ".$duration."\n");


sub tokenize {
	my($text) = @_;
	chomp($text);
	$text = " $text ";
	
	# seperate out all "other" special characters
	$text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-\"\|])/ $1 /g;


	$text =~ s/\;/ \; /g;
	$text =~ s/\:/ \: /g;
	$text =~ s/�/ \` /g;
	$text =~ s/�/ \' /g; 
	$text =~ s/�/ \`\` /g; 
	$text =~ s/�/ \'\' /g;
	
	# replace the pipe character, which is 
	# a special reserved character in Moses
	$text =~ s/\|/ -PIPE- /g;

	if($use_penn_treebank_tokenization) {
		$text =~ s/\(/ -LRB- /g;
		$text =~ s/\)/ -RRB- /g;
		$text =~ s/\[/ -LSB- /g;
		$text =~ s/\]/ -RSB- /g;
		$text =~ s/\{/ -LCB- /g;
		$text =~ s/\}/ -RCB- /g;

		$text =~ s/\"\s*$/ \'\' /g;
		$text =~ s/^\s*\"/ \`\` /g;
		$text =~ s/(\S)\"\s/$1 \'\' /g;
		$text =~ s/\s\"(\S)/ \`\` $1/g;
		$text =~ s/(\S)\"/$1 \'\' /g;
		$text =~ s/\"(\S)/ \`\` $1/g;

		$text =~ s/\\'\s*$/ \' /g;
		$text =~ s/^\s*\'/ \` /g;
		$text =~ s/(\S)\'\s/$1 ' /g;
		$text =~ s/\s\'(\S)/ \` $1/g;

		$text =~ s/\'ll/ -CONTRACT-ll/g;
		$text =~ s/\'re/ -CONTRACT-re/g;
		$text =~ s/\'ve/ -CONTRACT-ve/g;
		$text =~ s/n\'t/ n-CONTRACT-t/g;
		$text =~ s/\'LL/ -CONTRACT-LL/g;
		$text =~ s/\'RE/ -CONTRACT-RE/g;
		$text =~ s/\'VE/ -CONTRACT-VE/g;
		$text =~ s/N\'T/ N-CONTRACT-T/g;
		$text =~ s/cannot/can not/g;
		$text =~ s/Cannot/Can not/g;
	}


	

	#multi-dots stay together
	$text =~ s/\.([\.]+)/ DOTMULTI$1/g;
	while($text =~ /DOTMULTI\./) {
		$text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
		$text =~ s/DOTMULTI\./DOTDOTMULTI/g;
	}

	#multi-dashes stay together
	$text =~ s/\-([\-]+)/ DASHMULTI$1/g;
	while($text =~ /DASHMULTI\-/) {
		$text =~ s/DASHMULTI\-([^\-])/DASHDASHMULTI $1/g;
		$text =~ s/DASHMULTI\-/DASHDASHMULTI/g;
	}

	# seperate out "," except if within numbers (5,300)
	$text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
	# separate , pre and post number
	$text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
	$text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;
	      

	if(!$use_penn_treebank_tokenization) {
		$text =~ s/\"/ " /g;
		# turn ` into '
		$text =~ s/\`/\'/g;
	
		#turn '' into "
		$text =~ s/\'\'/ \" /g;
	} 


	if ($language eq "en") {
		#split contractions right
		$text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;
		#special case for "1990's"
		$text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
		$text =~ s/ '\s+s / 's /g;
		$text =~ s/ '\s+s / 's /g;
	} elsif (($language eq "fr") or ($language eq "it")) {
		#split contractions left	
		$text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([^\p{IsAlpha}])[']([\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1' $2/g;
	} else {
		$text =~ s/\'/ \' /g;
	}
	$text =~ s/\' \'/\'\'/g;
	
	#word token method
	my @words = split(/\s/,$text);
	$text = "";
	for (my $i=0;$i<(scalar(@words));$i++) {
		my $word = $words[$i];
		if ( $word =~ /^(\S+)\.$/) {
			my $pre = $1;
			if (($pre =~ /\./ && $pre =~ /\p{IsAlpha}/) || ($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==1) || ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[\p{IsLower}]/))) {
				#no change
			} elsif (($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==2) && ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[0-9]+/))) {
				#no change
			} else {
				$word = $pre." .";
			}
		}
		$text .= $word." ";
	}		

	$text =~ s/'\s+'/''/g;

	# clean up extraneous spaces
	$text =~ s/ +/ /g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;

	#restore multi-dots
	while($text =~ /DOTDOTMULTI/) {
		$text =~ s/DOTDOTMULTI/DOTMULTI./g;
	}
	$text =~ s/DOTMULTI/./g;
	

	#restore multi-dashes
	while($text =~ /DASHDASHMULTI/) {
		$text =~ s/DASHDASHMULTI/DASHMULTI-/g;
	}
	$text =~ s/DASHMULTI/-/g;

	$text =~ s/-CONTRACT-/'/g;
	
	#ensure final line break
	$text .= "\n" unless $text =~ /\n$/;

	return $text;
}

sub load_prefixes {
	my ($language, $PREFIX_REF) = @_;
	
	my $prefixfile = "$mydir/nonbreaking_prefix.$language";
	
	#default back to English if we don't have a language-specific prefix file
	if (!(-e $prefixfile)) {
		$prefixfile = "$mydir/nonbreaking_prefix.en";
		print STDERR "WARNING: No known abbreviations for language '$language', attempting fall-back to English version...\n";
		die ("ERROR: No abbreviations files found in $mydir\n") unless (-e $prefixfile);
	}
	
	if (-e "$prefixfile") {
		open(PREFIX, "<:utf8", "$prefixfile");
		while (<PREFIX>) {
			my $item = $_;
			chomp($item);
			if (($item) && (substr($item,0,1) ne "#")) {
				if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) {
					$PREFIX_REF->{$1} = 2;
				} else {
					$PREFIX_REF->{$item} = 1;
				}
			}
		}
		close(PREFIX);
	}
	
}

