#!/usr/bin/perl -w
use CGI qw(:all -debug);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

print header, start_html('Simple Menu');
warningsToBrowser(1);

@user_files = glob("users/*/*.jpg");
warn "@user_files";
$default = $user_files[0];
warn "$default";
print start_form;
print popup_menu('User Files', \@user_files, $default);
print end_form;
print end_html;
