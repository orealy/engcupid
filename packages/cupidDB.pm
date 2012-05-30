package cupidDB;
use base qw (Exporter);
our @EXPORT = qw(parse_user_profile);
use DBI;

my $db;

# Initialise the database. Must be called before other functions.
sub db_init {
  if (!-e 'user.db') {
    $db = DBI->connect("dbi:SQLite:user.db", "", "",
                       {RaiseError => 1, AutoCommit => 1});
    &db_create();
  } else {
    $db = DBI->connect("dbi:SQLite:user.db", "", "",
                       {RaiseError => 1, AutoCommit => 1});
  }

  if (-e "updated") {
    system('/bin/rm', 'updated');
    &db_refresh();
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

# Insert a hash representing a single user into the database.
sub db_insert (%) {
  my (%user_data) = @_;
  # Form to arrays of the fields, and the corresponding values.
  my @fields = keys %user_data;
  my @values = ();
  for my $field (@fields) {
    push(@values, $user_data{$field});
  }
  # Stringify the arrays for the database.
  my $fields_insert = join ", ", @fields;
  my $values_insert = "'".join("', '", @values)."'";

  $db->do("INSERT INTO users ($fields_insert) VALUES ($values_insert);\n");
}

# Does nothing.
sub db_access {
  # TODO
  return 0;
}

# Search for a user in the database.
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

sub db_all_user_data($) {
  shift @_ if $_[0] eq 'cupidDB';
  my ($user) = @_;
  my $hash_ref = $db->selectall_hashref("SELECT * FROM users WHERE username='$user'", 'username');
  my %hash = %$hash_ref;
  my $user_hash_ref = $hash{$user};
  my %user_hash = %$user_hash_ref;
  return %user_hash;
}

sub db_find_user_attr ($$) {
  shift @_ if $_[0] eq 'cupidDB';
  my ($user, $attr) = @_;
  my $data_ref = $db->selectall_arrayref("SELECT $attr FROM users WHERE username='$user'");
  my $data_row = ${$data_ref}[0];
  my $data = ${$data_row}[0];
  return $data;
}

# Helper function to extract all fields from a 
sub parse_user_profile ($) {
  my ($user) = @_;
  my %user_hash = ();

  if (!-e "users/$user/profile") {
    return %user_hash;
  }

  open(F, "users/$user/profile") or die("failed to open $user profile");
  @lines = <F>;

  # Primary fields
  for ($i = 0; $i < scalar(@lines); $i++) {
    $primary = "";
    # format | username:    bob_52
    if ($lines[$i] =~ /^(\S*?):\s*(.+)/) {
        $primary = "$1";
        if (defined $2) {
          my $value = $2;
          $user_hash{$primary} = $value;
        } else {
          die "not expected\n";
        }
    # format | age:    
    # format |     me:    19
    # format |     looking_for: 100
    } else {
      ($primary) = ($lines[$i] =~ /^(\S*?):/);
      $i++;
      while ($i < scalar(@lines) and $lines[$i] =~ /^\s+(\S*?):\s*(.*)/) {
        if ($1 eq "looking_for") {
          $user_hash{"$primary"."_looking"} = $2;
        } elsif ($1 eq "me") {
          $user_hash{"$primary"."_me"} = $2;
        } else {
          die "wasn't expecting that...";
        }
        $i++;
      } 
      $i--; # We went one too far.
    }
  }

  return %user_hash;
}

# Remake the database. Takes a while.
sub db_refresh {
  # Scan the users directory and add entries to the table.
  my @users = glob("users/*");
  for my $user (@users) {
    $user =~ /^.*\/(.*)/;
    $user = $1;
    if (!db_find_user($user) or (-e "users/$user/updated")) {
      if (-e "users/$user/updated") {
        system('/bin/rm', "users/$user/updated");
        $db->do("DELETE FROM users WHERE username='$user'");
      }
      my %user_data = parse_user_profile($user); 
      db_insert(%user_data);
    }
  }
}

return (1);
