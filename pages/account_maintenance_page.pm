package account_maintenance_page;
use base qw (Exporter);
our @EXPORT = qw(render_account_maintenance);
use lib 'packages/';
use cupidWrapper;
use cupidDB;
use CGI qw(:all -debug);
use CGI::Cookie;

sub render_account_maintenance {
	$current_user = cookie('username');
	if (!$current_user) { # Password recovery.
		if (defined param('username_to_send')) {
			my $username = param('username_to_send');
			param('username_to_send', '');
			my $email = cupidDB->db_find_user_attr($username, 'email');
			my $password = cupidDB->db_find_user_attr($username, 'password');
		    # Send password to user
			if (defined $email) {
			    $subject='Engcupid Password Reminder';
			    $to="$email";
			    $from= 'admin@engcupid.xxx';
			     
			    open(MAIL, "|/usr/sbin/sendmail -t");
			    print MAIL "To: $to\n";
			    print MAIL "From: $from\n";
			    print MAIL "Subject: $subject\n\n";
			    print MAIL "Your password is $password\n";
			    close(MAIL);
			}
			add_content("<p>Password was sent to your account</p>\n");
		}

		add_content(h2("Recover your password via email"));
		add_content("\n<br>\n");
		add_content
			(
				start_form,
				"<p>User's username: </p>",
				textfield(-name=>'username_to_send', -maxlength=>"78"), 
				submit(-name=>"action", -value=>'Send Password'),
				end_form
			);
	} else {
		add_content("<h2>Account Maintenance for $current_user</h2>\n");
		add_content("<p>");
		add_content("<a href=\"suspend_account\">Suspend Account</a>");
		add_content("\n<br>\n");
		add_content("<a href=\"activate_user\">Activate Account</a>");
		add_content("\n<br>\n");
		add_content("<a href=\"delete_account\">Delete Account</a>");
		add_content("</p>");
	}
	render_page();
}

return (1);