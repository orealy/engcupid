package edit_profile_page;
use base qw (Exporter);
our @EXPORT = qw(render_edit_profile);
use CGI qw(:all -debug);
use lib 'packages/';
use cupidWrapper;
use cupidDB;

$CGI::POST_MAX = 1024 * 100;  # maximum upload filesize is 100K
# Single Items
# username, DOB, email, name, password, username
# Looking For vs Me
# age, gender, editor, engineering_discipline, favourite_star_wars_movie,
# height, operating_systems, programming_languages, weight
my %single = (username=>'Username', DOB=>'Date of Birth', email=>'Email', name=>'Name',
			  password=>'Password');
my %paired = (age=>'Age',
			  gender=>'Gender',
			  editor=>'Editor',
			  engineering_discipline=>'Engineering Discipline',
			  favourite_star_wars_movie=>'Favourite Star Wars Movie',
			  height=>'Height',
			  operating_systems=>'Operating Systems',
			  programming_languages=>'Programming Languages',
			  weight=>'Weight');

sub render_edit_profile {
	my ($user) = (cookie('username') =~ /(\w{3,20})/);
	if (request_method() eq 'POST') {
		if (defined param('filename')) {
			my $filename = param('filename');
		    my $output_file = "users/$user/image.jpg";
		    my ($bytesread, $buffer);
		    my $numbytes = 1024;

		    open (OUTFILE, ">", "$output_file") 
		        or die "Couldn't open $output_file for writing: $!";
		    while ($bytesread = read($filename, $buffer, $numbytes)) {
		        print OUTFILE $buffer;
		    }
		    close OUTFILE;
	    } else {
	    	my %user_hash = cupidDB->db_all_user_data($user);	
	    	for my $field (keys %user_hash) {
	    		$user_hash{$field} = param($field);	
	    	}
	    	open (F, "> users/$user/profile");
	    	for my $field (keys %single) {
			    printf F "%-25s%s\n", "$field:", "$user_hash{$field}";
	    	}
	    	for my $field (keys %paired) {
	    		my $crap_looking = $user_hash{"$field"."_looking"};
	    		my $crap_me = $user_hash{"$field"."_me"};
	    		if ($crap_looking or $crap_me) {
		    		print F "$field:\n";
		    	}
	    		if ($crap_looking) {
	    			printf F "    %-25s%s\n", "looking_for:", "$crap_looking";
	    		}	
	    		if ($crap_me) {
	    			printf F "    %-25s%s\n", "me:", "$crap_me";
	    		}	
	    	}
	    	close (F);
	    	open (F, "> updated");
	    	close (F);
	    	open (F, "> users/$user/updated");
	    	close (F);
	    }
	    print redirect('edit_profile');
	} else {
		if (cupidDB->db_find_user($user)) {
			add_content(start_form);
				textfield(-name=>'username_to_send', -maxlength=>"78"), p,
			add_content("<table border=\"1\">");
			add_content("<tr><th>Field</th><th>Value</th></tr>");
			for my $field (keys %single) {
				my $value = cupidDB->db_find_user_attr($user, $field) || "";
				add_content("<tr> <td><b> $single{$field} <b></td> <td>", textfield(-name=>"$field", -value=>"$value"), "</td> </tr>\n")
			}	
			for my $field (keys %paired) {
				my $value = cupidDB->db_find_user_attr($user, "$field"."_looking") || "";
				add_content("<tr> <td><b> Looking for $paired{$field} <b></td> <td>", textfield(-name=>"$field"."_looking", -value=>"$value"), "</td> </tr>\n");
				$value = cupidDB->db_find_user_attr($user, "$field"."_me") || "";
				add_content("<tr> <td><b> My $paired{$field} <b></td> <td>", textfield(-name=>"$field"."_me", -value=>"$value"), "</td> </tr>\n")
			}
			add_content("</table>");
			add_content("<br>");
			add_content(submit);
			add_content(end_form);
			add_content("<br>");
		

			if (-e "users/$user/image.jpg") {
				add_content(img({-src=>"http://cgi.cse.unsw.edu.au/~cweb382/asst2/users/$user/image.jpg",-alt=>"Ugly Mug", -width=>"304",
					-height=>"228", -border=>"0"}));
			} else {
				add_content("You don't have an image\n");
			}

			add_content(start_form(-enctype => &CGI::MULTIPART));
			add_content(filefield('filename'));
			add_content(submit(-value => 'Upload File'));
			add_content(end_form);
		} else {
			print redirect('welcome');
		}
		render_page();
	}
}

return (1);
