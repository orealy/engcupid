#!/usr/bin/perl -w

# Package managing the database.
use cupidDB;

# Globals
my %param_dict;

cupidDB->init();

# Extract all fields from the synthetic data.
$dir = 'users';
opendir(DIR, $dir) or die "Failed to open $dir\n";
while (defined($user_dir = readdir(DIR))) {
  if ((-d "$dir/$user_dir") and ($user_dir =~ /\w/)) {
    $file = "$dir/$user_dir/profile";
    if (-e $file) {
      # Parse the profile for entries
      # in the data.
      print &parse_user_profile($file);
    }
  }
}

for (keys %param_dict) {
  print;
  print "\n";
}

print cupidDB->find_user("john"), "\n";
print cupidDB->find_user("derp"), "\n";

sub parse_user_profile($) {
  open(F, $_[0]);
  @file = <F>;

  %tmp_user = ();
  $lc = 0;
  while ($lc < scalar(@file)) {
    $line = $file[$lc];
    if ($line =~ /^(\S+?):\s*(\S+)/) { # username:   blah_2131
      $tmp_user{$1} = $2;
    } elsif ($line =~ /^(\S+?):/) { # age:   \n
      $category = $1;
      $sub_lc = $lc;
      while ($file[$sub_lc] =~ /^\s+(\S+):\s+(.*)$/) {
        print "cat, class, answer: $category, $1, $2\n";
        $tmp_user{$category}{$1} = {$2};
        $sub_lc++;
      }
      $lc = $sub_lc--;
    } else {
      warn "unhandled line type\n";
    }
    $lc++;
  }
  return %tmp_user;
}
