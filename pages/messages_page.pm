package messages_page;
use base qw (Exporter);
our @EXPORT = qw(render_messages_page);
use CGI qw(:all -debug);
use lib 'packages/';
use cupidDB;
use cupidWrapper;

sub render_messages_page {
	my ($current_user) = (cookie('username') =~ /(\w{3,20})/);

	if (cupidDB->db_find_user($current_user)) {
		if (param('clear_messages')) { # Clear the user's messages.
			system('/bin/rm', "users/$current_user/messages");
		}

		my $action = param('action') || '';
		if ($action eq 'Clear') {
			param('message_to_send', '');
		} elsif ($action eq 'Send') {	
			my ($username_to_send) = (param('username_to_send') =~ /(\w{3,20})/);

			if (cupidDB->db_find_user($username_to_send)) { # Send the message.
				open(M, ">> users/$username_to_send/messages");
				my $message = param('message_to_send');
				$message =~ s/\n//g;
				print M $message;
				print M "\nFrom $username_to_send\n\n";
				close(M);

			    # Send an notification email to the user.
				my $email = cupidDB->db_find_user_attr($username_to_send, "email");
				if (defined $email) {
				    $subject='Engcupid Message Notification';
				    $to="$email";
				    $from= 'admin@engcupid.xxx';
				     
				    open(MAIL, "|/usr/sbin/sendmail -t");
				    print MAIL "To: $to\n";
				    print MAIL "From: $from\n";
				    print MAIL "Subject: $subject\n\n";
				    print MAIL "$message\n";
				    close(MAIL);

				}
				add_content("<h2>Message sent successfully to $username_to_send!</h2>\n");
			} else {
				add_content("<h2> No such user: $username_to_send</h2>\n");
			}
			param('username_to_send', '');
			param('message_to_send', '');
		}

		add_content("<p>");
		if (-e "users/$current_user/messages") {
			add_content("You have the following messages:\n");
			open (M, "users/$current_user/messages");
			add_content("<br>");
			while (<M>) {
				add_content("<br>");
				add_content("$_\n");
				if ($_ eq "") {
					add_content("<br>");
				}
			}
			close(M);
			add_content("<br>");
		} else {
			add_content("You have no messages waiting\n");
		}
		add_content("</p>");

		add_content("<form method=\"post\">\n");
		add_content("<input type=submit name=\"clear_messages\" value=\"Clear Messages\">");

		add_content("<br><br>");
		add_content("<p>");
		add_content("Would you like to send a user a message? (78 Characters Max)\n");
		add_content
			(
				start_form, hr,
				"User's username: ", p,
				textfield(-name=>'username_to_send', -maxlength=>"78"), p,
				'Enter a message to send: ', p,
				textarea(-name=>'message_to_send'), p,
				submit(-name=>"action", -value=>'Send'),
				submit(-name=>"action", -value=>'Clear'),
				p, hr, p,
				end_form
			);
		add_content("</p>");
		render_page();
	} else {
		print redirect('welcome');		
	}
}

return (1);