# emit irssi events via ZeroMQ Pub/Sub only if you are away
use strict;
use vars qw($VERSION %IRSSI);
use ZeroMQ qw/:all/;

use Irssi;
$VERSION = '0.1.0';
%IRSSI = (
  authors     => 'Daniel Schauenberg',
  contact     => 'd@unwiredcouch.com',
  name        => 'zeromq',
  description => 'Distribute irssi events via zeroMQ pub/sub',
  url         => 'https://github.com/mrtazz/irssi-zeromq',
  license     => 'MIT'
);

# Prepare our context and publisher
# Distribute events via ZeroMQ Pub, per default we use a Unix socket but if we
# want events for a remote irssi instance (running in screen for example)
# change this to a TCP socket
my $context = ZeroMQ::Context->new();
my $publisher = $context->socket(ZMQ_PUB);
$publisher->bind('tcp://127.0.0.1:5000');

my $away_status = 0;

# functions, heavily based on the fnotify script
# https://gist.github.com/542141

#--------------------------------------------------------------------
# Function to extract private messages
#--------------------------------------------------------------------
sub priv_msg
{
  my ($server,$msg,$nick,$address,$target) = @_;
  publish($nick." " .$msg );
}

#--------------------------------------------------------------------
# Function to extract hilights
#--------------------------------------------------------------------
sub hilight
{
  my ($dest, $text, $stripped) = @_;
  if ($dest->{level} & MSGLEVEL_HILIGHT) {
    publish($dest->{target}. " " .$stripped );
  }
}

#--------------------------------------------------------------------
# ZeroMQ publish function
#--------------------------------------------------------------------
sub publish
{
  my ($text) = @_;
  # Send message to all subscribers
  if($away_status == 1) {
    $publisher->send('irssi '.$text);
  }
}

sub away {
  my ($req) = @_;
  $away_status = $req->{usermode_away};
}

#--------------------------------------------------------------------
# Bind the IRSSI signals to functions
#--------------------------------------------------------------------
Irssi::signal_add_last('message private', 'priv_msg');
Irssi::signal_add('print text', 'hilight');
Irssi::signal_add('away mode changed', 'away');

#- end
