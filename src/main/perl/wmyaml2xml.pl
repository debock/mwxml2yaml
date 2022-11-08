#!/usr/bin/perl

# description: Converts Wikimedia YAML file to original XML

# synopsis:
#   perl wmyaml2xml FILE

# version: 0.1.0
# project-id: af7bfb1f-d8f9-41f6-a6c9-fdf181e1e227
# created on: 2022-11-07

use strict;

use utf8;                                # Source code encoded using UTF-8
use open ':std', ':encoding(UTF-8)';     # Terminal provides/expects UTF-8

my $file_name = 'test.yaml';

if ($#ARGV >= 0) {
  $file_name = $ARGV[0];
}

open (FI, "<$file_name") or die("Cannot open '$file_name': $!\nQuit!\n");

my (@current_branch, $last_branch_element);
my ($yaml_elem, $yaml_key, $prev_yaml_key, $yaml_value, $prev_yaml_value, $colon_po);
my ($indention, $prev_indention, $indention_length, $prev_indention_length);
my ($is_multiline_string, $is_multiline_string_end, @multiline_string_lines, $multiline_string);
my $multiline_line;
my ($has_attributes, $has_content, $xml_elem_with_attributes);
my $is_yaml_key_with_no_linebreak;
my $l;
my $output;

$prev_indention_length = -1;

while ($l = <FI>) {
  $output = '';  

  $l =~ m/^([ ]*)(.+)/;
  $indention = $1;
  $yaml_elem = $2;
  
  if ($yaml_elem eq ' ' ) {
    $indention .= ' ';
    if (length($indention) > ($prev_indention_length+2)) {
      $indention = substr($indention, 0, $prev_indention_length + 2);
      $yaml_elem = substr($indention, $prev_indention_length + 1);
    }
    else {
      $yaml_elem = '';
    }
  }
  
  $indention_length = length($indention);
  
  if ($is_multiline_string == 1) {
    if ($indention_length > $prev_indention_length) {
      $multiline_line = substr($l, $indention_length);
      push(@multiline_string_lines, $multiline_line);
    }
    else {
      $is_multiline_string = 0;
      $is_multiline_string_end = 1;
    }
  }
  
  if ($is_multiline_string == 0) {
    if ($yaml_elem =~ m/\|\-$/) {
      $is_multiline_string = 1;
      $multiline_string = '';
      @multiline_string_lines = ();
    }
    else {
      if ($indention_length > $prev_indention_length) {
        push(@current_branch, $prev_yaml_key);
      }
      
      if ($yaml_elem =~ m/^\"/) {
        $colon_po = index($yaml_elem, '":');
        ($yaml_key, $yaml_value) = (substr($yaml_elem, 1, $colon_po-1), substr($yaml_elem, $colon_po+4, -1));
      }
      else {
        $colon_po = index($yaml_elem, ':');
        ($yaml_key, $yaml_value) = (substr($yaml_elem, 0, $colon_po), substr($yaml_elem, $colon_po+3, -1));
      }
      
      if ($yaml_value =~ m/^\"/ and $yaml_value =~ m/\"$/) {
        $yaml_value = substr($yaml_value, 1, -1);
      }

      if ($has_attributes == 0) {
        if ($yaml_key =~ m/^\+/) {
          $has_attributes = 1;
          $has_content = 0;
          if ($yaml_key ne '+content') {
            $xml_elem_with_attributes = "$prev_indention<$prev_yaml_key " . substr($yaml_key, 1) . "=\"$yaml_value\"";
          }
          else {
            $has_content = 1;
            $xml_elem_with_attributes = "$prev_indention<$prev_yaml_key>$yaml_value";
          }
        }
        else {
          if ($prev_indention_length != -1) {
            if ($prev_yaml_value ne '' ) {
              $output .= "$prev_indention<$prev_yaml_key>$prev_yaml_value<\/$prev_yaml_key>\n";
            }
            else {
              if ($is_yaml_key_with_no_linebreak == 0) {
                if ($prev_indention_length == $indention_length) {
                  $output .= "$prev_indention<$prev_yaml_key \/>\n";
                }
                else {
                  $output .= "$prev_indention<$prev_yaml_key>\n";
                }
              }
              else {
                $output .= "\n$prev_indention<$prev_yaml_key>\n";
              }
            }
          }
        }
      }
      else {
        if ($yaml_key =~ m/^\+/) {
          if ($yaml_key ne '+content') {
            $xml_elem_with_attributes .= ' ' . substr($yaml_key, 1) . '="' . $yaml_value . '"';
          }
          else {
            $has_content = 1;
            $xml_elem_with_attributes .= ">$yaml_value";
          }
        }
        else {
          $has_attributes = 0;
          if ($has_content == 0) {
            $output .= "$xml_elem_with_attributes>";
            $is_yaml_key_with_no_linebreak = 1;
          }
          else {
            $output .= "$xml_elem_with_attributes";
          }
          $xml_elem_with_attributes = '';
        }
      }
    }

    if ($is_multiline_string_end == 1) {
      $multiline_string_lines[$#multiline_string_lines] = substr($multiline_string_lines[$#multiline_string_lines], 0, -1);
      $multiline_string = join('', @multiline_string_lines);
      $output .= "$multiline_string";
      $has_content = 1;
      $is_multiline_string_end = 0;
      $multiline_string = '';
    }

    if ($indention_length < $prev_indention_length) {
      my $count_closing_elems = ($prev_indention_length - $indention_length) / 2;
      my $closing_idention = $indention . '  ' x $count_closing_elems;
      for (my $i = 0; $i < $count_closing_elems; $i++) {
        $closing_idention = substr($closing_idention, 0, -2);
        if ($has_content == 1) {
          $has_content = 0;
          $is_yaml_key_with_no_linebreak = 0;
          $last_branch_element = pop(@current_branch);
          $output .= "<\/$last_branch_element>\n";
        }
        elsif ($is_yaml_key_with_no_linebreak == 1) {
          $has_content = 0;
          $is_yaml_key_with_no_linebreak = 0;
          $last_branch_element = pop(@current_branch);
          $output .= "<\/$last_branch_element>\n";
        }
        else {
          $last_branch_element = pop(@current_branch);
          $output .= "$closing_idention<\/$last_branch_element>\n";
        }
      }
    }

  }
  
  if ($output =~ m/^([ ]+)<([^>]+)([^>]*)><\/\2>$/) {
    print "$1<$2$3 \/>\n";
  }
  else {
    print "$output";
  }
  
  if ($is_multiline_string == 0) {
    $prev_indention = $indention;
    $prev_indention_length = $indention_length;
    $prev_yaml_key = $yaml_key;
    $prev_yaml_value = $yaml_value;
  }
}

$indention = '';
$indention_length = 0;

$has_attributes = 0;
if ($has_content == 0) {
  print "$xml_elem_with_attributes>";
  $is_yaml_key_with_no_linebreak = 1;
}
else {
  print "$xml_elem_with_attributes";
}

if ($indention_length < $prev_indention_length) {
  my $count_closing_elems = ($prev_indention_length - $indention_length) / 2;
  my $closing_idention = $indention . '  ' x $count_closing_elems;
  for (my $i = 0; $i < $count_closing_elems; $i++) {
    $closing_idention = substr($closing_idention, 0, -2);
    if ($has_content == 1) {
      $has_content = 0;
      $is_yaml_key_with_no_linebreak = 0;
      $last_branch_element = pop(@current_branch);
      print "<\/$last_branch_element>\n";
    }
    elsif ($is_yaml_key_with_no_linebreak == 1) {
      $has_content = 0;
      $is_yaml_key_with_no_linebreak = 0;
      $last_branch_element = pop(@current_branch);
      print "<\/$last_branch_element>\n";
    }
    else {
      $last_branch_element = pop(@current_branch);
      print "$closing_idention<\/$last_branch_element>\n";
    }
  }
}

close (FI);
