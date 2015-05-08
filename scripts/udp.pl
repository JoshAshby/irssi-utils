#!/usr/bin/env perl

use strict;
use warnings;

use IO::Socket;
use JSON::PP;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

use Irssi;
use Irssi::Irc;
use vars qw($VERSION %IRSSI);

$VERSION = "0.2";
%IRSSI = (
  authors => "JoshAshby",
  contact => "hax\@joshisa.ninja",
  name => "irssi-notify",
  description => "sends notifys for away messages",
  license => "MIT",
  url => "https://github.com/JoshAshby"
);

my $sock = IO::Socket::INET->new(
  Proto    => 'udp',
  PeerPort => 4161,
  PeerAddr => 'localhost',
  ReuseAddr => 'localhost',
  ReusePort => 4161
) or die "Could not create socket: $!\n";

my $json = JSON::PP->new;

my $ua = LWP::UserAgent->new(
  timeout => 20
);

my $pushbullet_api_base_url = "https://api.pushbullet.com/v2";

Irssi::settings_add_bool('misc', $IRSSI{'name'} . '_debug', 0);
Irssi::settings_add_bool('misc', $IRSSI{'name'} . '_udp', 1);
Irssi::settings_add_bool('misc', $IRSSI{'name'} . '_pushbullet', 1);
Irssi::settings_add_str('misc', $IRSSI{'name'} . '_pushbullet_key', "");

sub debug {
  my ($msg) = @_;

  if (Irssi::settings_get_bool($IRSSI{'name'} . '_debug')) {
    Irssi::print($msg);
  }
}

sub send_udp {
  my ($nick, $channel, $msg) = @_;

  if (Irssi::settings_get_bool($IRSSI{'name'} . '_udp')) {
    my %raw_data = (
      sage => "doge",
      nick => $nick,
      channel => $channel,
      msg => $msg
    );

    my $json_data = $json->encode( \%raw_data );
    $sock->send( $json_data ) or die "Send error: $!\n";
  }
}

sub send_note {
  # curl --header 'Authorization: Bearer <your_access_token_here>'
  #      --header 'Content-Type: application/json'
  #      -X POST https://api.pushbullet.com/v2/pushes
  #      --data-binary '{"type": "note", "title": "Note Title", "body": "Note Body"}'

  my ($nick, $channel, $msg) = @_;

  if (Irssi::settings_get_bool($IRSSI{'name'} . '_pushbullet')) {
    my %raw_data = (
      type => 'note',
      title => "Irssi - $nick in $channel",
      body => $msg
    );

    my $key = Irssi::settings_get_str($IRSSI{'name'} . '_pushbullet_key');

    if ($key != "") {
      my $res = $ua->post( $pushbullet_api_base_url . '/pushes',
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $key",
        Content => encode_json(\%raw_data)
      );

      if (!$res->is_success) {
        my $code = $res->code;
        my $message = $res->message;
        debug( "Can't pushbullet! $code - $message" );
      }
    }
  }
}

sub send_notify {
  my ($nick, $channel, $msg) = @_;

  send_udp($nick, $channel, $msg);
  send_note($nick, $channel, $msg);
}

sub msg_pri {
  my ($server, $msg, $nick, $address) = @_;

  if ($server->{usermode_away}) {
    debug("Got msg from $nick : $msg");
    send_notify($nick, 'private', $msg);
  }
}

sub msg_pub {
  my ($server, $msg, $nick, $address, $channel) = @_;

  if ($server->{usermode_away}) {
    debug("Got msg from $nick in $channel : $msg");
    send_notify($nick, $channel, $msg);
  }
}

Irssi::signal_add_last('message private', 'msg_pri');
Irssi::signal_add_last('message public', 'msg_pub');

debug("notify up and running!");
