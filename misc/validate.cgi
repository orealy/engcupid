#!/usr/bin/perl -w
use CGI qw(:all -debug);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

print header,start_html('Credit Card Stuff');
warningsToBrowser(1);
print h2("Credit Card Validator");
print p("This page checks the structural validity of a [hypothetical] credit
    card number.");
if (defined param("Close")) {
    print "Thank you for using the Validator.";
    print end_html;
    exit 0;
} elsif (defined param("card")) {
    my $card = param("card");
    if (&clean_and_validate($card)) {
        print p("$card is a valid card number");
    } else {
        print "<p style=\"color:red\">";
        print "$card is not valid!\n";
        print "</p>";
    }
} else {
    param("card", "input a card ");
}

print start_form;
print "<p>";
print 'Enter your credit card number (16 digits, any punctuation): ';
print textfield('card');
print "</p>";
print submit(-name=>"Validate");
print reset;
print submit(-name=>"Close");
print end_form;
print end_html;

sub clean_and_validate($) {
    my $cc = $_[0];
    $cc =~ s/\D//g;
    return &validate($cc)
}

sub validate($) {
    my @cc = split '', $_[0];
    return 0 if @cc != 16;
    my $cnt = 0;
    my $sum = 0;
    for my $chr (@cc) {
        $sum += &reduce($chr * (2 ** (++$cnt%2)));
    }
    return ($sum % 10 == 0);
}

sub reduce($) {
    return int($_[0]/10) + $_[0] % 10;
}
