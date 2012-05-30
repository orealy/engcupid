package browse_users_page;
use base qw (Exporter);
our @EXPORT = qw(render_browse);
use lib 'packages/';
use CGI qw(:all -debug);
use cupidWrapper;

sub render_browse {
	# Extract all fields from the synthetic data.
	if (!cookie('username')) {
		print redirect('welcome');
	}
	$user_group = param('group');
	if (!defined $user_group or !$user_group =~ /^([a-z]|all)$/i) {
		$user_group = 'all';
	}
	$user_group = lc($user_group);

	my @users;
	if ($user_group eq 'all') {
		@users = glob("users/*");
	} else {
		@users = glob("users/$user_group*");
	}

	my $index = 0;
	while ($index < scalar(@users)) {
		my ($tmp_user) = ($users[$index] =~ /^.*\/(.*)/);	
		if (-e "users/$tmp_user/status") {
			open (F, "users/$tmp_user/status");
			my @lines = <F>;
			close (F);
			if (grep /suspended/, @lines) {
				delete $users[$index];
			}
		}
		$index++;
	}

	my ($search_string) = (param('search') =~ /(\w*)/);
	if (defined $search_string) {
		@users = grep {/$search_string/} @users;
	}

	# Print the search bar.
	add_content(start_form);
	add_content("Search", textfield("search"));
	add_content(hidden(-name=>'group', -value=>"$user_group"));
	add_content(submit);
	add_content(end_form);

	# Print the All A-Z option
	add_content('<tr>', '<td="3"> <br><br>');
	add_content('<a href="browse_users?group=all">All</a>');
	for $letter ("A".."Z") {
		add_content("<a href=\"browse_users?group=$letter\">$letter</a>");
	}
	add_content("</td></tr>\n");

	# Sort by username or by match ranking?
	my $sort_request = param('sort');
	if (!defined $sort_request or !$sort_request eq 'm') {
		$sort_request='u';
	}

	# Store all users in a dict
	my %match_hash;
	for my $user (@users) {
		$user =~ /\/(.*)/;
		$match_hash{$1} = match_users(cookie('username'), $1);
	}

	# Display the users
	add_content(table({-border=>"1", -width=>"40%", -cellpadding=>"2", cellspacing=>"3", class=>"tabulatedInfo"}), "\n");
	add_content("<tr>\n",
					"<th><a href=\"browse_users.cgi?group=$user_group&sort=u\">Username</a></th>",
					"<th><a href=\"browse_users.cgi?group=$user_group&sort=m\">Match (%)</a></th>",
				"</tr>\n");

	my @sorted_keys;
	if ($sort_request eq 'u') {
		@sorted_keys = sort keys %match_hash;
	} elsif ($sort_request eq 'm') {
		@sorted_keys = sort {$match_hash{$b} <=> $match_hash{$a}} keys %match_hash;
	}

	for my $user (@sorted_keys) {
		add_content("<tr>\n",
						"<td><a href=\"public_profile?username=$user\">$user</a></td>\n",
						"<td>$match_hash{$user}</td>\n",
					"</tr>\n",);
	}

	add_content("</table>");
	render_page();
}

sub match_users ($$) {
	my ($user1, $user2) = @_;
	# Check Gender

	# 
	my $match = int(rand(100));
	return $match;
}

return (1);
