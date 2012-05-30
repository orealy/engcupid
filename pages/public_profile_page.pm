package public_profile_page;
use base qw (Exporter);
our @EXPORT = qw(render_public_profile);
use CGI qw(param img redirect h2);
use lib 'packages/';
use cupidWrapper;
use cupidDB;

%private_data = (password=>1, name=>1, DOB=>1, email=>1);

sub render_public_profile {
	$user = param('username');

	if (cupidDB->db_find_user($user)) {
		# Print the user table.
		add_content(h2("$user\'s Public Profile"));
		add_content
			(
				"<table border=\"1\">\n",
				"<tr>\n",
				"<th>Field</th>\n",
				"<th>Value</th>\n",
				"</tr>\n",
			);
		# Single Items
		# username, DOB, email, name, password
		# Looking For vs Me
		# age, gender, editor, engineering_discipline, favourite_star_wars_movie,
		# height, operating_systems, programming_languages, weight
		my %single = (username=>'Username');
		my %paired = (age=>'Age',
					  gender=>'Gender',
					  editor=>'Editor',
					  engineering_discipline=>'Engineering Discipline',
					  favourite_star_wars_movie=>'Favourite Star Wars Movie',
					  height=>'Height',
					  operating_systems=>'Operating Systems',
					  programming_languages=>'Programming Languages',
					  weight=>'Weight');

		for my $field (keys %single) {
			my $data = cupidDB->db_find_user_attr($user, $field);
			add_content
			(
				"<tr>\n",
				"<td> <b>$single{$field}<b> </td>\n",
				"<td> $data </td>\n",
				"</tr>\n",
			);
		}
		for my $field (keys %paired) {
			my $data = cupidDB->db_find_user_attr($user, "$field"."_looking");
			$data =~ s/^\s*{//;
			$data =~ s/}\s*$//;
			if (defined $data) {
				add_content
				(
					"<tr>\n",
					"<td><b> Looking for $paired{$field} <b></td>\n",
					"<td> $data </td>\n",
					"</tr>\n",
				);
			}
			$data = cupidDB->db_find_user_attr($user, "$field"."_me");
			$data =~ s/^\s*{//;
			$data =~ s/}\s*$//;
			if (defined $data) {
				$data =~ s/^\s*{//;
				$data =~ s/}\s*$//;
				add_content
				(
					"<tr>\n",
					"<td><b> My $paired{$field} <b></td>\n",
					"<td> $data </td>\n",
					"</tr>\n",
				);
			}
		}

		add_content("</table>\n");
		add_content("\n<br><br>\n");
		if (-e "users/$user/image.jpg") {
			add_content(img({-src=>"http://cgi.cse.unsw.edu.au/~cweb382/asst2/users/$user/image.jpg",-alt=>"Ugly Mug", -width=>"304",
				-height=>"228", -border=>"0"}));
		} else {
			add_content("<p>This user has no profile picture</p>");
		}
	} else {
		add_content("Invalid user: -$user-\n");
	}
	render_page();
}

return (1);
