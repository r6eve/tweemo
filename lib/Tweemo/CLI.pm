package Tweemo::CLI;
use strict;
use warnings;
use utf8;

use Carp;
use Encode qw(decode);
use FindBin qw($RealBin $RealScript);
use Getopt::Long;
use Moo;

use Tweemo;
use Tweemo::Account;
use Tweemo::Action;
use Tweemo::Orient;
use Tweemo::Useful qw(any_japanese tategaki);

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

sub run {
  my ($self, @args) = @_;
  my @cmds;
  my $user;
  my $p = Getopt::Long::Parser->new(
    config => ['no_auto_abbrev', 'no_ignore_case', 'pass_through']
  );
  $p->getoptionsfromarray(
    \@args,
    'h|help' => sub { unshift @cmds, 'help' },
    'v|version' => sub { unshift @cmds, 'version' },
    'dry-run' => sub { unshift @cmds, 'dry_run' },
    'user=s' => \$user,
  );
  if ($self->is_screen_name(@args)) {
    $self->show_user_timeline($user, @args);
    0;
  } else {
    push @cmds, @args;
    my $cmd = shift @cmds || 'st';
    unshift @cmds, $user;
    my $code = try {
      my $call = $self->can("cmd_$cmd") or confess "cannot find command '$cmd'\n";
      $self->$call(@cmds);
      return 0;
    } catch {
      carp $@, "\n";
    };
    $code;
  }
}

sub print {
  my ($self, $msg, $type) = @_;
  my $fh = $type && $type >= WARN ? *STDERR : *STDOUT;
  print {$fh} $msg;
}

sub cmd_help {
  my ($self) = @_;
  $self->print(<<HELP);
Usage: $RealScript [options] <command>

Options:
  --help      brief help message
  --version   print version and exits
  --user      set user
  --dry-run   print emotional value, but don't tweet

where <command> is one of:
  @{[ join ', ', $self->commands ]}

Run `tweemo man` for help.
HELP
}

sub commands {
  my ($self) = @_;
  no strict 'refs';
  map { s/^cmd_//; $_ }
    grep { /^cmd_.*/ && $self->can($_) }
    sort keys %{__PACKAGE__."::"};
}

sub cmd_man {
  my ($self) = @_;
  system 'perldoc', $RealBin . '/../lib/Tweemo.pm';
}

sub cmd_version {
  my ($self) = @_;
  $self->print("$RealScript $Tweemo::VERSION\n");
}

sub cmd_add {
  my ($self) = @_;
  Tweemo::Account::add_account;
}

sub cmd_dry_run {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'en|english' => \my $en,
    't|tate' => \my $tate,
  );
  my $msg = shift @args or confess "message is required.\n";
  $msg = decode('UTF-8', $msg);
  my $val = Tweemo::Orient->orient($msg, $en) // 'undef';
  if (defined $tate) {
    if (any_japanese($msg)) {
      $msg = tategaki($msg, '　') . "\n" . '(' . $val . ')';
    } else {
      $msg = tategaki($msg, ' ') . "\n" . '(' . $val . ')';
    }
  } else {
    $msg .= ' (' . $val . ')';
  }
  Tweemo::Action::dry_run($msg);
}

sub cmd_dm {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'n|num=i' => \my $n,
  );
  Tweemo::Action::show_direct_messages($user, $n);
}

sub cmd_lists {
  my ($self, $user) = @_;
  Tweemo::Action::get_lists($user);
}

sub cmd_tl {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'n|num=i' => \my $n,
    'list=s' => \my $list,
    'e|emo' => \my $emo,
  );
  if (defined $list) {
    Tweemo::Action::show_list($user, $list, $n, $emo);
  } else {
    Tweemo::Action::show_home_timeline($user, $n, $emo);
  }
}

sub cmd_rt {
  my ($self, $user, @args) = @_;
  my $id = shift @args or confess "id is required.\n";
  Tweemo::Action::retweet($user, $id);
}

sub cmd_fav {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'n|num=i' => \my $n,
    'list' => \my $list,
    'del=s' => \my $id_del,
  );
  if (defined $list) {
    Tweemo::Action::show_fav_list($user, $n);
  } elsif (defined $id_del) {
    Tweemo::Action::del_favorite($user, $id_del);
  } else {
    my $id = shift @args or confess "id is required.\n";
    Tweemo::Action::favorite($user, $id);
  }
}

sub cmd_del {
  my ($self, $user, @args) = @_;
  my $id = shift @args or confess "id is required.\n";
  Tweemo::Action::destroy($user, $id);
}

sub cmd_search {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'n|num=i' => \my $n,
  );
  my $query = shift @args or confess "query is required.\n";
  $query = decode('UTF-8', $query);
  Tweemo::Action::show_search($user, $n, $query);
}

sub cmd_st {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'say|speech' => \my $say,
    'a|all' => \my $emo,
  );
  Tweemo::Action::user_stream($user, $say, $emo);
}

sub show_user_timeline {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'n|num=i' => \my $n,
    'e|emo' => \my $emo,
  );
  my $screen_name = shift @args or confess "screen name is required.\n";
  Tweemo::Action::show_user_timeline($user, $n, $screen_name, $emo);
}

sub cmd_post {
  my ($self, $user, @args) = @_;
  $self->parse_options(
    \@args,
    'd|dm2=s' => \my $dm2,
    'en|english' => \my $en,
    'id=s' => \my $id,
    'img=s' => \my $img,
    't|tate' => \my $tate,
  );
  if (defined $img) {
    $self->post_with_media($user, $id, $en, $img, @args);
  } elsif (defined $dm2) {
    $self->post_direct_message($user, $dm2, $en, @args);
  } else {
    my $msg = shift @args or confess "message is required.\n";
    $msg = decode('UTF-8', $msg);
    my $val = Tweemo::Orient->orient($msg, $en) // 'undef';
    if (defined $tate) {
      if (any_japanese($msg)) {
        $msg = tategaki($msg, '　') . "\n" . '(' . $val . ')';
      } else {
        $msg = tategaki($msg, ' ') . "\n" . '(' . $val . ')';
      }
    } else {
      $msg .= ' (' . $val . ')';
    }
    Tweemo::Action::post($user, $id, $msg);
  }
}

sub post_direct_message {
  my ($self, $user, $dm2, $en, @args) = @_;
  my $msg = shift @args or confess "message is required.\n";
  $msg = decode('UTF-8', $msg);
  my $val = Tweemo::Orient->orient($msg, $en) // 'undef';
  Tweemo::Action::post_direct_message($user, $dm2, $msg . ' (' . $val . ')');
}

sub post_with_media {
  my ($self, $user, $id, $en, $img, @args) = @_;
  my $msg;
  if (!@args) {
    $msg = '';
  } else {
    $msg = shift @args;
    $msg = decode('UTF-8', $msg);
    my $val = Tweemo::Orient->orient($msg, $en) // 'undef';
    $msg .= ' (' . $val . ')';
  }
  Tweemo::Action::post_with_media($user, $id, $img, $msg);
}

sub is_screen_name {
  my ($self, @xs) = @_;
  for my $x (@xs) {
    if ($x =~ /^\@[a-zA-Z0-9_]+$/) {
      return 1;
    }
  }
  0;
}

sub parse_options {
  my ($self, $args, @spec) = @_;
  my $p = Getopt::Long::Parser->new(
    config => ['no_auto_abbrev', 'no_ignore_case']
  );
  $p->getoptionsfromarray($args, @spec) or exit 1;
}

1;
