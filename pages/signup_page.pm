package signup_page;
use base qw (Exporter);
our @EXPORT = qw(render_signup);
use CGI qw(:all -debug);
use HTML::Template;
use lib 'packages/';
use cupidWrapper;

my %user_dict = ();
my @users = glob("users/*"); 
for my $user (@users) {
    $user =~ s/^.*\///;
    $user_dict{$user} = "data"; 
}
$my_cookie = cookie(-name=>'username', -value=>'');

sub render_signup {
    &handle_signup();
}

sub valid_username($) {
    if ($_[0] and $_[0] =~ '^\w{3,20}$') {
            if (!exists $user_dict{$_[0]}) {
                return 'True';
            } else {
                return 'User Error';
          }
      } else {
          return 'False';
      }
}

sub valid_password($) {
  return ($_[0] and $_[0] =~ '^.{3,20}$');
}

sub valid_email($) {
  return ($_[0] and $_[0] =~ '^\S+@\S+\.\S+$');
}

sub generate_signup_form (%){
    # Template Variables:
    # USERNAME, ERROR_USERNAME, ERROR_PASSWORD, ERROR_VERIFY, EMAIL, ERROR_EMAIL
    my (%signup_params) = @_;
    my $template = HTML::Template->new(filename=>'tmpl/signup.tmpl');
    $template->param(%signup_params);
    add_content($template->output);
    render_page(-cookie=>"$my_cookie");
}

sub validate_input {
    my ($username, $password, $verify, $email) =
        (param('username'), param('password'), param('verify'), param('email'));
    %error_param = (USERNAME=>"$username", EMAIL=>"$email");
    my $input_error;

    if (&valid_username($username) eq 'User Error') {
        $error_param{ERROR_USERNAME} = "Username already taken";
        $input_error = 'True';
    } elsif (&valid_username($username) eq 'False') {
        $error_param{ERROR_USERNAME} = "Username's are 3 to 20 '\\w' characters";
        $input_error = 'True';
    }

    if (!&valid_password($password)) {
        $error_param{ERROR_PASSWORD} = "Passwords are 3 to 20 characters";
        $input_error = 'True';
    } elsif ($password ne $verify) {
        $error_param{ERROR_VERIFY} = "Passwords need to match =P";
        $input_error = 'True';
    }

    if (!valid_email($email)) {
        $error_param{ERROR_EMAIL} = "Not a valid email";
        $input_error = 'True';
    }

    return $input_error;
}

sub handle_signup {
    if (request_method() eq 'GET') {
        &generate_signup_form();
    } else { # assume POST
        my $input_error = &validate_input();
        if ($input_error eq 'True') {
            &generate_signup_form(%error_param);
        } else {
            setup_newuser();
        }
    }
}

sub setup_newuser {
    my ($new_user) = (param('username') =~ /^(\w{3,20})$/); # Already validated.
    my $new_email = param('email');
    my $new_password = param('password');

    # Setup the users folder and profile.
    mkdir("users/$new_user"); 
    open (F, "> users/$new_user/profile");
    printf F "%-25s%s\n", "username:", "$new_user";
    printf F "%-25s%s\n", "password:", "$new_password";
    printf F "%-25s%s\n", "email:", "$new_email";
    close(F);

    # Send an activation link to the user.
    $to='orealy@gmail.com';
    $from= 'admin@engcupid.xxx';
    $subject='Engcupid Account Activation';
     
    open(MAIL, "|/usr/sbin/sendmail -t");
    print MAIL "To: $to\n";
    print MAIL "From: $from\n";
    print MAIL "Subject: $subject\n\n";
    print MAIL "http://cgi.cse.unsw.edu.au/~cweb382/asst2/engcupid.cgi/activate_user?username=$new_user\n";
    close(MAIL);
    
    # Finish
    print redirect('welcome');
}
return (1);