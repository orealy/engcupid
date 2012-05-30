#!/usr/bin/perl -w

# Structure of Project
#   Welcome / sign in page handled by welcome.cgi
#   Signup handled by signup.cgi. Succesful signup redirects to welcome page.
#   TODO:
#    Profile page
#    Edit Profile page
#    Browse page.

# Package managing the database.
use cupidDB;

# Globals
my %param_dict;

cupidDB->db_init();

print cupidDB->db_find_user("anne_37"), "\n";
print cupidDB->db_find_user("derp"), "\n";
