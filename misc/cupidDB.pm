package cupidDB;
use DBI;

my $db;

# Initialise the database. Must be called before other functions.
sub db_init {
  if (!-e 'user.db') {
    print ("creating new table\n");
    $db = DBI->connect("dbi:SQLite:user.db", "", "",
                       {RaiseError => 1, AutoCommit => 1});
    &db_create();
    &db_refresh();
  } else {
    $db = DBI->connect("dbi:SQLite:user.db", "", "",
                       {RaiseError => 1, AutoCommit => 1});
  }
}

# Create the 'users' database.
sub db_create {
  # Columns in table:
  # Single Items
  # username, DOB, email, name, password, username
  # Looking For vs Me
  # age, gender, editor, engineering_discipline, favourite_star_wars_movie,
  # height, operating_systems, programming_languages, weight
  $db->do("CREATE TABLE users 
    (
      username TEXT,
      email TEXT,
      password TEXT,
      name TEXT,
      DOB TEXT,
      gender_me TEXT,
      gender_looking TEXT,
      age_me TEXT, 
      age_looking TEXT,
      editor_me TEXT,
      editor_looking TEXT,
      engineering_discipline_me TEXT,
      engineering_discipline_looking TEXT,
      favourite_star_wars_movie_me TEXT,
      favourite_star_wars_movie_looking TEXT,
      height_me TEXT,
      height_looking TEXT,
      operating_systems_me TEXT,
      operating_systems_looking TEXT,
      programming_languages_me TEXT,
      programming_languages_looking TEXT,
      weight_me TEXT,
      weight_looking TEXT
    )");
}

sub db_insert (%) {
  my (%user_data) = @_;
  # Form to arrays of the fields, and the corresponding values.
  my @fields = keys %user_data;
  my @values = ();
  for my $field (@fields) {
    push(@values, $user_data{$field});
  }
  my $fields_insert = join ", ", @fields;
  my $values_insert = "'".join("', '", @values)."'";
  print "adding\n";
  print "$fields_insert\n";
  print "@values\n";
  print "$values_insert\n";

  print ("INSERT INTO users ($fields_insert) VALUES ($values_insert);\n");
  $db->do("INSERT INTO users ($fields_insert) VALUES ($values_insert);\n");
}

sub db_access {
  # TODO
  return 0;
}

sub db_find_user ($) {
  shift @_ if $_[0] eq 'cupidDB';
  my ($target_user) = @_;
  my $user_row = $db->selectall_hashref("SELECT * FROM users WHERE username='$target_user'", "username");
  if (defined %$user_row) {
    # print "found user: $target_user\n";
    # %{$user_key{$key}} is a REFERNCE to a hash.
    # my %user_hash = %{$tmp_hash{$key}};
    return 1;
  } else {
    # print "unable to find: $target_user\n";
    return 0;
  }
}

sub parse_user_profile {
  my (@users) = @_;
  my %user_hash = ();

  for my $user (@users) {
    print "processing $user\n";
    open(F, "$user/profile") or die("failed to open $user profile");
    @lines = <F>;

    # Primary fields
    for ($i = 0; $i < scalar(@lines); $i++) {
      print "line $i: $lines[$i]";
      $primary = "";
      # format | blah:    field
      if ($lines[$i] =~ /^(\S*?):\s*(.+)/) {
          $primary = "$1";
          print "found primary:$primary\n";
          if (defined $2) {
            my $value = $2;
            $user_hash{$primary} = $value;
          } else {
            die "not expected\n";
          }
      # format | blah:    
      } else {
        ($primary) = ($lines[$i] =~ /^(\S*?):/);
        $i++;
        print "special line is: $lines[$i]";
        while ($i < scalar(@lines) and $lines[$i] =~ /^\s+(\S*?):\s*(.*)/) {
          print "special case!!\n";              
          if ($1 eq "looking_for") {
            $user_hash{"$primary"."_looking"} = $2;
          } elsif ($1 eq "me") {
            $user_hash{"$primary"."_me"} = $2;
          } else {
            die "wasn't expecting that...";
          }
          $i++;
        } 
        # We went one too far.
        $i--;
      }
    }
  }

  print "returning:\n";
  for (keys %user_hash) {
    print "$_:$user_hash{$_}\n";
  }
  return %user_hash;
}

sub db_refresh {
  eval {
    local $db->{PrintError} = 0;
    $db->do("DROP TABLE users");
  };
  &db_create();

  # Scan the users directory and add entries to the table.
  my @users = glob("../users/a*");
  for my $user (@users) {
    my %user_data = parse_user_profile($user); 
    db_insert(%user_data);
  }
}

return (1);
