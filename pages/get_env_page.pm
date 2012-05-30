package get_env_page;
use base qw (Exporter);
our @EXPORT = qw(render_env);
use lib 'packages/';
use cupidWrapper;
use CGI qw(:all -debug);

sub render_env {
	foreach (sort keys %ENV)
	{
		add_content("<b>$_</b>: $ENV{$_}<br>\n");
	}
	render_page();
}

return (1);