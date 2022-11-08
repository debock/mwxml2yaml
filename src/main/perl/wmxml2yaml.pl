#!/usr/bin/perl

# description: Converts Wikimedia XML file to YAML

# synopsis:
#   perl wmxml2yaml FILE

# version: 0.1.0
# project-id: af7bfb1f-d8f9-41f6-a6c9-fdf181e1e227
# created on: 2022-11-05

# Modules #
###########

use XML::Parser;

use utf8;                                # Source code encoded using UTF-8
use open ':std', ':encoding(UTF-8)';     # Terminal provides/expects UTF-8

use strict;

# Main #
########

my $file_name = '../../../test/resources/wikipedia-de_test.xml';

if ($#ARGV >= 0) {
  $file_name = $ARGV[0];
}

my $xml_parser = XML::Parser->new(ErrorContext => 2);

$xml_parser->setHandlers(Start => \&start_handler,
                         End   => \&end_handler,
                         Char  => \&char_handler,
                        );


$xml_parser->parsefile($file_name);

my ($is_content, $char_text_collected);
my (@current_branch, $indention);
my ($parser_ref, $element_name, $attribute_name, $attribute_value);
sub start_handler {
  $parser_ref = shift @_;
  $element_name = shift @_;;
  
  push (@current_branch, $element_name);
  if ($#current_branch > 0) {
    $indention .= "  ";
  }
  
  print "$indention$element_name:\n";
  
  while ($attribute_name = shift @_) {
    $attribute_value = shift @_;
    if (index($attribute_name, ':') >=0 ) {
      print "$indention  \"+$attribute_name\": \"$attribute_value\"\n";
    }
    else {
      print "$indention  +$attribute_name: \"$attribute_value\"\n";
    }
  }
  $is_content = 0;
}

# Subroutines #
###############

my @multi_lines;
sub end_handler {
  ($parser_ref, $element_name) = @_;
 
  if ($char_text_collected ne '') {
    if (index($char_text_collected, "\n") >= 0) {
      @multi_lines = split(/\n/,$char_text_collected);
      $multi_lines[$#multi_lines] =~ s/ +$//;
      $char_text_collected = join ("\n$indention    ", @multi_lines);
      print "$indention  +content: |-\n$indention    $char_text_collected\n";
    }
    else {
      $char_text_collected =~ s/\\/\\\\"/g;
      $char_text_collected =~ s/"/\\"/g;
      print "$indention  +content: \"$char_text_collected\"\n";
    }
  }

  if ($current_branch[$#current_branch] eq $element_name) {
    pop(@current_branch);
    $indention = substr($indention, 0, length($indention) - 2);
  }
  else {
    die ("Closing tag not equal to last opening tag. Quit!\n");
  }
  
  $is_content = 2;
  $char_text_collected = '';
}

my $char_text;
sub char_handler{
  ($parser_ref, $char_text) = @_;
  
  if ($is_content == 0) {
    $char_text_collected = $parser_ref->recognized_string();
    $is_content = 1;
  }
  elsif ($is_content == 1) {
    $char_text_collected .= $parser_ref->recognized_string();
  }
}
