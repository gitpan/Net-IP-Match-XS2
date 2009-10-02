package Net::IP::Match::XS2;

use 5.005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::IP::Match::XS2 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Net::IP::Match::XS2', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::IP::Match::XS2 - Perl extension for match IP address against Net ranges

=head1 SYNOPSIS

  use Net::IP::Match::XS2;

  my $ipr = Net::IP::Match::XS2->new();
  $ipr->add("10.1.1.0", 25);
  ...
  $ipr->add("192.168.2.128", 26);

  $cidr = $ipr->match_ip("192.168.2.131");


=head1 DESCRIPTION

This module is XS implementation of matching IP address against Net ranges.
Using similar method to Net::IP::Match::Regexp in storing Net ranges into
memory. By implementing in XS C-code, more fast setup time than Regexp
module. This module is useful when Net ranges change often. 


=head1 METHODS

=over

=cut

=item new()

Create IP range object and initialize it.

=item $ipr->add( $net, $mask )

Add an IP address ($net) into the object. $mask is 1 .. 32 CIDR mask bit value.

=item $cidr = $ipr->match_ip( $ip )

Searches matching $ip against previously setup networks. Returns matched
Network in CIDR format (xxx.xxx.xxx.xxx/nnn). or undef unless matched.


=back

=head1 SEE ALSO

=head2 L<Net::IP::Match::Regexp>


=head1 AUTHOR

Tomo, E<lt>tomo at c-wind comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tomo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
