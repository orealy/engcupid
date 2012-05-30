package welcome_page;
use base qw (Exporter);
our @EXPORT = qw(render_welcome);
use CGI qw(:all -debug);
use lib 'packages/';
use cupidWrapper;
use CGI::Cookie;

my $welcome_message = <<EOF;
Congratz on joining! Check your inbox for an activation link.
Once you've activated your account you can sign in and start browsing!
EOF

my $username = cookie('username');

sub render_welcome() {
	add_content("<p>");
	if (referer =~ /signup/) {
		add_content($welcome_message);
	} elsif ($username) {
		add_content("You are logged in as $username!");
	} else {
		add_content("Log in to start browsing!");
	}
	add_content("</p>\n");
	render_page();
}

return (1);
