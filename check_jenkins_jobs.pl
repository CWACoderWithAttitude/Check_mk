#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use XML::Twig;
use HTTP::Request;
use Getopt::Long qw(:config no_ignore_case bundling_override);
no warnings 'uninitialized';
################################
# GET COMMAND LINE ARGUMENTS
################################
my ($port, $host) ;

# Parse command line arguments
GetOptions ('host=s'   => \$host, 'port=s' => \$port);

if( (!defined($host)) && (!defined($port))) {
	no_args("Hostname and portnumber must be specified\n");
}
sub main {
	my $protocol = 'http';
	my $api_url = '/api/xml';
	my $job_name;
	my $jenkins_url;
	my $job_url;
	my $count;
	my @jobs;
	my @health;
	my @job_names;

	$jenkins_url = $protocol . "://" . $host . ":" . $port . $api_url ;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	my $response = $ua->get($jenkins_url);
	if ($response->is_success) {
		my $content = $response->decoded_content;  # or whatever
		XML::Twig->new( twig_roots => { 'job/name' => sub { push @jobs, $_->text; } }) ->parseurl( $jenkins_url);
	}
	else {
		print "CRITICAL ~ Url not found \n";
		#exit 0;
	}
	foreach $job_name (@jobs) {
		@health = ();
		@job_names = ();
		#$job_name = 'First_run';
		$job_url = $protocol . "://" . $host . ":" . $port . "/" . "job" . "/" . $job_name . $api_url ;
		my $response2 = $ua->get($job_url);
		if ($response2->is_success) {
			my $new_url = $protocol . "://" . $host . ":" . $port . "/" . "job" . "/" . $job_name . $api_url ;
			XML::Twig->new( twig_roots => { 'freeStyleProject/name' => sub { push @job_names, $_->text}, 'healthReport/score' => sub { push @health, $_->text; }}) ->parseurl( $new_url);
			#print "OK, @job_names has Health score @health\n";
			#print @job_names;
			#print @health;
			my $value = scalar(@health);
			my $job_value = scalar(@job_names);
			my $result;
			if ($value != 0	&& $job_value != 0) {
				#print "Score::$value\n";
				#print "Name::$job_value\n";
				my $itr = 0;
				my $sum = 0;
				while ($itr < @health) {
					$sum = $sum + $health[$itr];
					$itr = $itr + 1;
				}
				$result = $sum/$value;
				#print "$job_name\n";
				#print "$result\n";
			
				if($result < 80 && $result >= 40) {
					print "WARNING ~ @job_names ~ $result\n";
				}
				elsif($result < 40) {
					print "CRITICAL ~ @job_names ~ $result\n";
				}
				else {
					print "OK ~ @job_names ~ $result\n";
				}
			}
			else {
				print "CRITICAL ~ @job_names ~ no score\n";
			}
		}
		#print @job_names, @health;
		else {
			print "CRITICAL ~ Url not found \n";
		}
	}
}

# Explains usage of this script (how to call it effectively)
sub usage
{
	print <<EOU;
	Usage:
	perl $0 -host hostname -port portnumber
	Example:
	perl $0 -host mbiradar2d -port 8080
EOU
}

# Print error message and proper usage instructions: don't run the rest of the script
sub no_args {
        my $error = shift ;
        print "\nERROR: $error" ;
        usage();
        exit 1;
}

# Execution starts here

#############
main();
#############
