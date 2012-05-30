package cupidWrapper;
use base qw (Exporter);
our @EXPORT = qw(render_page add_content);
use CGI qw(:all -debug);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use HTML::Template;

my $template = HTML::Template->new(filename=>"tmpl/main_page.tmpl");
my @mc; # Items to print as MAIN_CONTENT

open (F, "tmpl/links.tmpl");
@lines = <F>;
$template->param(("LINKS"=>"@lines"));

sub render_page {
	print header(@_); # Print the HTTP header.
	warningsToBrowser(1);
	$template->param(("MAIN_CONTENT"=>"@mc"));
	print $template->output;
}

sub add_content {
	(@content) = @_;
	shift (@content) if ($content[0] eq 'cupidWrapper');
	push(@mc, @content);
}

return (1);
