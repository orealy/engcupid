package browse_users_page;
use base qw (Exporter);
our @EXPORT = qw(render_browse);
use lib 'packages/';
use CGI qw(:all -debug);
use cupidWrapper;
use cupidDB;

sub render_browse {
	if (!defined cookie('username')) {
		print redirect('welcome');
		return;
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

# Arbitrary weights for events.
my ($match_bonus, $partial_bonus, $mismatch_cost) = (10, 5, -5);
my $initial_match = 20;
sub compare_numeric ($$) {
	my ($a1, $a2) = @_;
	if ($a1 and $a2) {
		my ($a1_low, $a1_high) = ($a1 =~ /(\d+)/);
		if ($a1_low and $a1_high and $a2 > $age1_low and $a2 < $a1_high) {
			$match += $match_bonus;
		} elsif ($a1_low and $a1_high) {
			my $range = $a1_high - $a1_low;
			my $mean = ($a1_low + $a1_high)/2;
			my $diff = abs($a2 - $mean);

			return $partial_bonus / ($diff / $range);
		} elsif ($a1_low and $a1_low == $a2) {
			return $match_bonus;
		} else {
			return $mismatch_cost;
		}
	}

	return 0;
}

sub string_data_compare($$) {
	my ($s1, $s2) = @_;
	my $match_bonus = 0;

	#add_content("comparing $s1 to $s2...");
	if (!$s1 or !$s2) {
		return 0;
	}

	# Strip punctuation
	$s1 =~ s/[[:punct:]]/ /g;
	$s2 =~ s/[[:punct:]]/ /g;

	# Split into words
	my @s1_list = split(/ /, $s1);
	my @s2_list = split(/ /, $s2);

	# Hash input words as seen/vs unseen
	%hash_s1 = map { $_ => 1 } @s1_list;	

	# Compare keys. Add points for common words.
	for my $item (@s2_list) {
		$match_bonus += 3 if (exists $hash_s1{$item});
	}

	my $min_items = ($#s1_list < $#s2_list) ? $#s1_list : $#s2_list;
	$match_bonus = $match_bonus / ($min_items + 1);

	return $match_bonus;
}

sub directed_match ($$) {
	my ($user1, $user2) = @_;
	my %u1_hash = cupidDB->db_all_user_data($user1);
	my %u2_hash = cupidDB->db_all_user_data($user2);

	my $match = $initial_match;

	# Looking For vs Me
	# age, gender, editor, engineering_discipline, favourite_star_wars_movie,
	# height, operating_systems, programming_languages, weightr

	# Check Gender
	my ($gender1, $gender2) = ($u1_hash{'gender_looking'}, $u2_hash{'gender_my'});
	if ($gender1 and $gender2 and !(lc($gender1) eq lc ($gender2))) {
		$match = 0;
	}

	# Check numerical results: Age, Weight, Height
	# Check age range
	my ($age1, $age2) = ($u1_hash{'age_looking'}, $u2_hash{'age_me'});	
	$match += compare_numeric($age1, $age2);

	# Check weight range
	my ($weight1, $weight2) = ($u1_hash{'weight_looking'}, $u2_hash{'weight_me'});	
	$match += compare_numeric($weight1, $weight2);

	my ($height1, $height2) = ($u1_hash{'height_looking'}, $u2_hash{'height_me'});	
	$match += compare_numeric($height1, $height2);

	# Check string inputs.
	# Editor, Engineering Discipline, Star Wars Movie, Operating Systems, Programming Languages
	@string_fields = ('editor', 'engineering_discipline', 'favourite_star_wars_movie',
					  'operating_systems', 'programming_languages');
	for my $field (@string_fields) {
		my ($str1, $str2) = ($u1_hash{"$field"."_looking"}, $u2_hash{"$field"."_me"});
		$match += string_data_compare($str1, $str2);	
	}
	return $match;
}

sub match_users ($$) {
	my ($user1, $user2) = @_;
	$match1 = directed_match($user1, $user2);
	$match2 = directed_match($user2, $user1);

	$harmonic_mean = int((2*$match1*$match2)/($match1+$match2+1));

	if ($harmonic_mean < 0) {
		$harmonic_mean = 0;
	}
	if ($harmonic_mean > 100) {
		$harmonic_mean = 100;
	}

	return $harmonic_mean;
}

return (1);
