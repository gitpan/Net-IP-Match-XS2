# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-Match-XS2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Net::IP::Match::XS2') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ipmap = Net::IP::Match::XS2->new();
ok(defined($ipmap), "new");

my $rv = $ipmap->add("10.0.0.0", 18);
ok($rv, "add");
$ipmap->add("10.1.0.0", 16);

my $res = $ipmap->match_ip("10.0.0.1");
ok(defined($res), "match");
