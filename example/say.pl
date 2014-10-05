use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Config::Pit;
use WebService::Ello;

my $ello = sub { #prepare
  my $pit = pit_get('ello.co', require => {
      email     => 'your email    on ello.co',
      password  => 'your password on ello.co',
    }
  );

  return WebService::Ello->new(
    %$pit
  );
}->();

my $res = $ello->login();
my $t = <STDIN>;
chomp $t;
$ello->say({ content => $t});
