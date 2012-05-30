package login_page;
use base qw (Exporter);
our @EXPORT = qw(handle_login);
use CGI qw(:all -debug);
use CGI::Cookie;
use lib 'packages/';
use cupidWrapper;

# Template Variables:
# USERNAME, ERROR
my %error_param;

sub handle_login {
	if (cookie('username') =~ /\w{3,20}/) {
		print redirect('welcome');	
	}
	
	# If no cookie, then user must sign in.
	if (request_method eq 'GET') {
		render_login();
	} else { # POST
        if (validate_input() eq 'True') {
        	$username = param('username');
        	my $my_cookie = cookie(-name=>'username', -value=>"$username");
        	print header(-cookie=>$my_cookie, -location=>'welcome');
        } else {
            render_login(%error_param);
        }	
	}
}

# As a side effect this updates the "error_param" hash.
sub validate_input {
    my ($username, $password) =
        (param('username'), param('password'));
    %error_param = (USERNAME=>"$username", ERROR=>'Username or password invalid');

	if (-e "users/$username/profile") {
    	open (PROFILE, "users/$username/profile");	
    	while ($line = <PROFILE>) {
  			if ($line =~ /password:\s*(\S*)/ and $password eq $1) {
  				return 'True';
  			}	
    	}	
    }

    return 'False';
}

sub render_login (%) {
    # Template Variables:
    # USERNAME, ERROR_USERNAME, ERROR_PASSWORD, ERROR_VERIFY, EMAIL, ERROR_EMAIL
    my (%signup_params) = @_;
    my $template = HTML::Template->new(filename=>'tmpl/login.tmpl');
    $template->param(%signup_params);
    add_content($template->output);
    render_page();
}

return (1);