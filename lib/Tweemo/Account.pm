package Tweemo::Account;
use strict;
use warnings;

use Carp;
use Net::Twitter::Lite::WithAPIv1_1;
use YAML::Tiny;

use base qw(Exporter);
our @EXPORT = qw(add_account);

sub add_account {
  my $yamlfile = "$ENV{'HOME'}/.tweemo.yml";
  if (-f $yamlfile) {
    add_another_account($yamlfile);
  } else {
    add_first_account($yamlfile);
  }
}

sub add_another_account {
  my ($yamlfile) = @_;
  my $yml = YAML::Tiny->read($yamlfile);
  my $cfg = $yml->[0];
  my $nt = net_twitter_obj($cfg);
  my ($token, $token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => get_pin($nt));
  if (registerp($cfg, $user_id)) {
    print STDERR "'$screen_name' has already registered!\n";
    exit 1;
  }
  print "Welcome, ${screen_name}!\n";
  $cfg->{users}->{$screen_name} = {
    access_token => $token,
    access_secret => $token_secret,
    id => $user_id,
  };
  $yml->write($yamlfile);
}

sub add_first_account {
  my ($yamlfile) = @_;
  my $cfg = {
    consumer_key => 'CONSUMER_KEY',
    consumer_secret => 'CONSUMER_SECRET'
  };
  my $nt = net_twitter_obj($cfg);
  my ($token, $token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => get_pin($nt));
  print "Welcome, ${screen_name}!\n";
  $cfg->{default_user} = $screen_name;
  $cfg->{users}->{$screen_name} = {
    access_token => $token,
    access_secret => $token_secret,
    id => $user_id,
  };
  my $yml = YAML::Tiny->new($cfg);
  $yml->write($yamlfile);
  unless (chmod(0600, $yamlfile)) {
    print STDERR "cannot change permission '$yamlfile'\n";
    exit 1;
  }
}

sub get_pin {
  my ($nt) = @_;
  my $url = $nt->get_authorization_url;
  print "open $url\n";
  open_default_browser($url);
  print 'input PIN Number: ';
  my $pin = <STDIN>;
  chomp $pin;
  $pin;
}

sub open_default_browser {
  my ($url) = @_;
  if ($^O eq 'darwin') {
    system "open '$url'";
  } elsif ($^O eq 'linux') {
    system "xdg-open '$url' 2>/dev/null";
  } elsif ($^O eq 'MSWin32') {
    system "start '$url'";
  } else {
    carp 'cannot locate default browser';
  }
}

sub registerp {
  my ($cfg, $id) = @_;
  for my $user (keys %{$cfg->{users}}) {
    if ($cfg->{users}->{$user}->{id} == $id) {
      return 1;
    }
  }
  0;
}

sub net_twitter_obj {
  my ($cfg) = @_;
  Net::Twitter::Lite::WithAPIv1_1->new(
    consumer_key => $cfg->{consumer_key},
    consumer_secret => $cfg->{consumer_secret},
    ssl => 1,
  );
}

1;
