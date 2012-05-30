package get_cookies;
use base qw (Exporter);
our @EXPORT = qw(show_cookies);
use lib 'packages/';
use cupidWrapper;
use CGI qw(:all -debug);
use CGI::Cookie;

my %cookies = fetch CGI::Cookie;

sub show_cookies {
	foreach (sort keys %cookies)
	{
		add_content("<b>$_</b>: $cookies{$_}<br>\n");
	}
	render_page();
}

return (1);