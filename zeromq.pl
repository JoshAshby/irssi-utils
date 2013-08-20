# emit irssi events via ZeroMQ Pub/Sub
use strict;
use vars qw($VERSION %IRSSI);
use ZeroMQ qw/:all/;

use Irssi;
$VERSION = '0.1.1';
%IRSSI = (
  authors     => 'Daniel Schauenberg, Joshua Ashby',
  contact     => 'd@unwiredcouch.com, joshuaashby@joshashby.com',
  name        => 'zeromq',
  description => 'Distribute irssi events via zeroMQ pub/sub',
  url         => 'https://github.com/JoshAshby/irssi-utils',
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
  my ($server, $msg, $nick, $address) = @_;
  publish("[private][".$away_status."][me][".$nick."]".$msg);
}

sub pub_talk {
  my ($server, $msg, $nick, $address, $target) = @_;

  publish("[public][".$away_status."][".$target."][".$nick."]".$msg);
}


#--------------------------------------------------------------------
# ZeroMQ publish function
#--------------------------------------------------------------------
sub publish
{
  my ($text) = @_;
  $publisher->send('irssi '.$text);
}

sub away {
  my ($req) = @_;
  $away_status = $req->{usermode_away};
  if($away_status) {
    publish("[away]True");
  } else {
    publish("[away]False");
  }
}

#--------------------------------------------------------------------
# Bind the IRSSI signals to functions
#--------------------------------------------------------------------
Irssi::signal_add_last('message private', 'priv_msg');
Irssi::signal_add('away mode changed', 'away');
Irssi::signal_add('message public', 'pub_talk');

#- end
