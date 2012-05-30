#!/usr/bin/perl -wT
use lib qw(packages pages);
use CGI qw(:all -debug);
use CGI::Cookie;
use cupidWrapper;
use welcome_page;
use signup_page;
use browse_users_page;
use edit_profile_page;
use login_page;
use public_profile_page;
use account_maintenance_page;
use messages_page;
use get_env_page;
use get_cookies;
use cupidDB;

# Globals
my %param_dict;

delete @ENV{'PATH', 'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
cupidDB->db_init();

#-------------------MAIN--------------------
# Redirect to page based on path.
my $pi = path_info();
if ($pi =~ /^$/) { # Add a path_info field. Stops relative links breaking.
	print redirect('engcupid.cgi/')
} elsif ($pi =~ /^\/$/ or $pi =~ /welcome/) { # No path -> Welcome Screen.
	render_welcome();
} elsif ($pi =~ /signup/) { # Signup to the website.
	render_signup();
} elsif ($pi =~ /edit_profile/) { # Edit the profile.
	render_edit_profile();
} elsif ($pi =~ /browse_users/) { # Browse through the site's users.
	render_browse();
} elsif ($pi =~ /login/) { # Login to the site.
	handle_login();
} elsif ($pi =~ /public_profile/) { # Show a user's public profile.
	render_public_profile();
} elsif ($pi =~ /logout/) { # Logout from the site.
	$my_cookie = cookie(-name=>'username', -value=>'');
	add_content("<p>You are now logged out.</p>\n");
	render_page(-cookie=>$my_cookie);
} elsif ($pi =~ /activate_user/) { # Activate an account.
	($new_user) = (param("username") =~ /(\w{3,20})/);
	if (-d "users/$new_user") {
		open (F, "> users/$new_user/status");
		printf F "active\n";
		close F;
	}
	print redirect('welcome');
} elsif ($pi =~ /maintenance/) { # Account Maintenance page.
	render_account_maintenance();
} elsif ($pi =~ /delete/) { # Delete the user's account.
	my ($current_user) = (cookie('username') =~ /(\w{3,20})/);

	if ("$current_user" and -d "users/$current_user") {
		system('/bin/rm', '-r', "users/$current_user");
		add_content("<p>$current_user\'s account has been deleted.</p>\n");
	} else {
		add_content("$current_user is not a user account.")
	}

	$my_cookie = cookie(-name=>'username', -value=>'');
	render_page(-cookie=>$my_cookie);
} elsif ($pi =~ /suspend/) { # suspend the user's account.
	my $current_user = cookie('username');
	if (-d "users/$current_user") {
		open(F, "> users/$current_user/status");
		print F "suspended\n";
		close F;
	}
	$my_cookie = cookie(-name=>'username', -value=>'');
	add_content("<p>your account has been suspended.</p>\n");
	render_page(-cookie=>$my_cookie);
} elsif ($pi =~ /recover_pasword/) { # suspend the user's account.
	my $current_user = cookie('username');
	if (-d "users/$current_user") {
		open(F, "> users/$current_user/status");
		print F "suspended\n";
		close F;
	}
	add_content("<p>The password has been sent to your account.</p>\n");
} elsif ($pi =~ /messages/) { # Read and send messages.
	render_messages_page();
} elsif ($pi =~ /get_env/) { # Helper to show the %ENV variable.
	render_env();
} elsif ($pi =~ /get_cookies/) { # Helper to show the current cookies.
	show_cookies(); 
} else { # Catch-all case.
	$pi =~ s/^\///;
	if (-e "$pi") {
		add_content("$pi exists");	
	}
	add_content("<p>UNHANDLED PAGE</p>\n");
	add_content($pi);
	render_page();	
}

exit (0);
#-------------------MAIN--------------------
