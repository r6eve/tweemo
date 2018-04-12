package Tweemo::Action;
use strict;
use warnings;
use autodie;
use utf8;

use AnyEvent::Twitter::Stream;
use Carp;
use Encode qw(decode encode);
use File::Which;
use List::Util qw(sum0);
use HTML::Entities;
use Net::Twitter::Lite::WithAPIv1_1;
use Scalar::Util qw(blessed);
use Term::ANSIColor qw(colored);
use Time::Piece;
use YAML::Tiny;

use base qw(Exporter);
our @EXPORT = qw();

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

sub dry_run {
  my ($tweet) = @_;
  print $tweet, "\n";
}

sub show_direct_messages {
  my ($user, $count) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $xs;
    if (defined $count) {
      $xs = $nt->direct_messages({ count => $count });
    } else {
      $xs = $nt->direct_messages;
    }
    my $ys;
    if (defined $count) {
      $ys = $nt->sent_direct_messages({ count => $count });
    } else {
      $ys = $nt->sent_direct_messages;
    }
    my @ss = sort { $a->{id} <=> $b->{id} } (@$xs, @$ys);
    $count //= 20;
    for my $s (@ss > $count ? @ss[(@ss - $count) .. $#ss] : @ss) {
      print_tweet($s, 'dm', undef, undef);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub get_lists {
  my ($user) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $ls = $nt->get_lists;
    for my $l (@$ls) {
      print $l->{slug}, "\n";
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub show_list {
  my ($user, $slug, $count, $emo) = @_;
  my $nt = net_twitter_obj($user);
  $user //= default_user();
  eval {
    my $ss = defined $count
      ? $nt->list_statuses({ owner_screen_name => $user, slug => $slug, count => $count, include_rts => 1 })
      : $nt->list_statuses({ owner_screen_name => $user, slug => $slug, include_rts => 1 });
    for my $s (reverse @$ss) {
      print_tweet($s, 'timeline', undef, $emo);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub show_home_timeline {
  my ($user, $count, $emo) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $ss = defined $count
      ? $nt->home_timeline({ count => $count })
      : $nt->home_timeline;
    for my $s (reverse @$ss) {
      print_tweet($s, 'timeline', undef, $emo);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub del_favorite {
  my ($user, $id) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $s = $nt->destroy_favorite($id);
    printf "%s\n\n%s\n%s\n",
      'success: unfavorite following tweet',
      sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
      decode_entities($s->{text});
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub show_fav_list {
  my ($user, $count, $emo) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $ss = defined $count
      ? $nt->favorites({ count => $count })
      : $nt->favorites;
    for my $s (reverse @$ss) {
      print_tweet($s, 'timeline', undef, $emo);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub retweet {
  my ($user, $id) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $s = $nt->retweet($id);
    printf "%s\n\n%s\n%s\n",
      'success: retweeted following tweet',
      sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
      decode_entities($s->{text});
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub favorite {
  my ($user, $id) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $s = $nt->create_favorite($id);
    printf "%s\n\n%s\n%s\n",
      'success: faved following tweet',
      sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
      decode_entities($s->{text});
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub destroy {
  my ($user, $id) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $s = $nt->destroy_status($id);
    printf "%s\n\n%s\n%s\n",
      'success: deleted following tweet',
      sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
      decode_entities($s->{text});
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub show_search {
  my ($user, $count, $query) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my $r = defined $count
      ? $nt->search({ q => $query, count => $count })
      : $nt->search($query);
    for my $s (reverse @{$r->{statuses}}) {
      print_tweet($s, 'timeline', undef, undef);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub user_stream {
  my ($user, $say, $emo) = @_;
  my $yml = YAML::Tiny->read("$ENV{'HOME'}/.tweemo.yml");
  my $cfg = $yml->[0];
  $user //= $cfg->{default_user};
  my $cv = AE::cv;
  my $listener = AnyEvent::Twitter::Stream->new(
    consumer_key => $cfg->{consumer_key},
    consumer_secret => $cfg->{consumer_secret},
    token => $cfg->{users}->{$user}->{access_token},
    token_secret => $cfg->{users}->{$user}->{access_secret},
    method => 'userstream',
    on_tweet => sub {
      my ($s) = @_;
      if (!($s->{text} && $s->{user}{screen_name})) {
        return;
      }
      print_tweet($s, 'userstream', $say, $emo);
    },
    on_error => sub {
      my ($err) = @_;
      $err = decode('UTF-8', $err);
      print STDERR "stream error: $err\n";
      exit 1;
    },
  );
  $cv->recv;
}

sub show_user_timeline {
  my ($user, $count, $user_screen_name, $emo) = @_;
  $user_screen_name =~ s/^@//;
  my $nt = net_twitter_obj($user);
  eval {
    my $ss = defined $count
      ? $nt->user_timeline({ screen_name => $user_screen_name, count => $count })
      : $nt->user_timeline({ screen_name => $user_screen_name });
    for my $s (reverse @$ss) {
      print_tweet($s, 'timeline', undef, $emo);
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub print_tweet {
  my ($tweet, $mode, $say, $emo) = @_;
  if ($mode eq 'dm') {
    _print_header($tweet, $say, $mode);
    _print_body($tweet, $say);
    _print_orient($tweet, $emo);
  } elsif ($mode eq 'timeline') {
    _print_header($tweet, $say, $mode);
    _print_body($tweet, $say);
    _print_orient($tweet, $emo);
    _print_fav_rt($tweet);
    _print_src($tweet);
  } elsif ($mode eq 'userstream') {
    _print_header($tweet, $say, $mode);
    _print_body($tweet, $say);
    _print_orient($tweet, $emo);
    _print_src($tweet);
  }
}

sub _print_header {
  my ($tweet, $say, $mode) = @_;
  my $ca = $tweet->{created_at};
  my $tp = localtime Time::Piece->strptime($ca, "%a %b %d %T %z %Y")->epoch;
  if (defined $say) {
    speech('ja', $tweet->{user}{screen_name});
  }
  if ($mode eq 'dm') {
    printf "%s %s -> %s\n",
      sprintf('%s%s%s', $tp->strftime('[%m/%d '), $tp->wdayname, $tp->strftime(' %T]')),
      sprintf('%s %s', _color_bold_unsco("\@$tweet->{sender}{screen_name}"), colored($tweet->{sender}{name}, 'bold')),
      sprintf('%s %s', _color_bold_unsco("\@$tweet->{recipient}{screen_name}"), colored($tweet->{recipient}{name}, 'bold'));
  } else {
    printf "%s %s %s\n",
      sprintf('%s%s%s', $tp->strftime('[%m/%d '), $tp->wdayname, $tp->strftime(' %T]')),
      sprintf('%s %s', _color_bold_unsco("\@$tweet->{user}{screen_name}"), colored($tweet->{user}{name}, 'bold')),
      sprintf('http://twitter.com/%s/status/%s', $tweet->{user}{screen_name}, $tweet->{id});
  }
}

sub _print_body {
  my ($tweet, $say) = @_;
  my $screenname_rx = qr/^(.*)(@[a-zA-Z0-9_]+)(.*)$/;
  my $hashtag_rx = qr/^(.*)(#[^ ]+)(.*)$/;
  my @ts;
  for my $t (split /\n/, $tweet->{text}) {
    my @ss;
    for my $s (split / /, $t) {
      $s = decode_entities($s);
      speech('ja', $s) if (defined $say);
      if ($s =~ $screenname_rx) {
        push @ss, sprintf('%s%s%s', $1, _color_bold_unsco($2), $3);
      } elsif ($s =~ $hashtag_rx) {
        push @ss, sprintf('%s%s%s', $1, colored($2, 'underscore bright_white'), $3);
      } else {
        push @ss, $s;
      }
    }
    push @ts, join(' ', @ss);
  }
  my $text = join("\n", @ts);
  print $text, "\n";
}

sub _print_orient {
  my ($tweet, $emo) = @_;
  if (!defined $emo) {
    return;
  }
  my $orient = Tweemo::Orient->orient($tweet->{text}) // 'undef';
  printf ': %s ', colored(sprintf("%s %s", $orient, 'Emo'), 'bold');
}

sub _print_fav_rt {
  my ($tweet) = @_;
  my ($fc, $rc);
  if ($tweet->{favorite_count} > 0) {
    $fc = $tweet->{favorite_count};
  }
  if ($tweet->{retweet_count} > 0) {
    $rc = $tweet->{retweet_count};
  }
  if (defined $fc && defined $rc) {
    printf ': %s : %s ',
      colored(sprintf("%d %s", $fc, 'Fav'), 'bold yellow'),
      colored(sprintf("%d %s", $rc, 'RT'), 'bold green');
  } elsif (defined $fc) {
    printf ': %s ', colored(sprintf("%d %s", $fc, 'Fav'), 'bold yellow');
  } elsif (defined $rc) {
    printf ': %s ', colored(sprintf("%d %s", $rc, 'RT'), 'bold green');
  }
}

sub _print_src {
  my ($tweet) = @_;
  my $src = _tweet_src($tweet);
  print ": $src\n";
}

sub _tweet_src {
  my ($tweet) = @_;
  (my $src = $tweet->{source}) =~ s|<a href="(.+)" rel=".+">(.+)</a>|$2 $1|;
  $src;
}

sub speech {
  my ($lang, $text) = @_;
  $text =~ s/s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+//g;
  $text =~ s/\"/\\"/g;
  my $mplayer = which('mplayer');
  if (!defined $mplayer) {
    print STDERR "You should install MPlayer.\n";
    exit 1;
  }
  `$mplayer -user-agent Mozilla "http://translate.google.com/translate_tts?ie=UTF-8&tl=$lang&q=\$(echo "$text" |sed 's/ /\+/g')" >/dev/null 2>&1`;
}

sub _color_bold_unsco {
  my ($s) = @_;
  # my $n = sum0 map { ord } split //, $s;
  my $n = ord(substr($s, 1, 1));
  my @colors = qw(bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan);
  colored($s, sprintf('underscore bold %s', @colors[$n % @colors]));
}

sub post_direct_message {
  my ($user, $dm2, $tweet) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my @ss = $nt->new_direct_message(decode('UTF-8', $tweet), { screen_name => $dm2 });
    for my $s (@ss) {
      printf "%s\n\n%s\n",
        'success: sent the following direct message',
        decode_entities($s->{text});
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub post {
  my ($user, $id, $tweet) = @_;
  my $nt = net_twitter_obj($user);
  eval {
    my @ss = defined $id
      ? $nt->update($tweet, { in_reply_to_status_id => $id })
      : $nt->update($tweet);
    for my $s (@ss) {
      printf "%s\n%s\n",
        sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
        decode_entities($s->{text});
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub post_with_media {
  my ($user, $id, $img, $tweet) = @_;
  if (defined $tweet) {
    $tweet = decode('UTF-8', $tweet);
    utf8::encode($tweet);
  }
  my $nt = net_twitter_obj($user);
  eval {
    my @ss = defined $id
      ? $nt->update_with_media($tweet, [$img], { in_reply_to_status_id => $id })
      : $nt->update_with_media($tweet, [$img]);
    for my $s (@ss) {
      printf "%s\n%s\n",
        sprintf('http://twitter.com/%s/status/%s', $s->{user}{screen_name}, $s->{id}),
        decode_entities($s->{text});
    }
  };
  if ($@) {
    if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
      carp decode('UTF-8', $@->error);
    } else {
      confess decode('UTF-8', $@);
    }
  }
}

sub net_twitter_obj {
  my ($user) = @_;
  my $yml = YAML::Tiny->read("$ENV{'HOME'}/.tweemo.yml");
  my $cfg = $yml->[0];
  $user //= $cfg->{default_user};
  Net::Twitter::Lite::WithAPIv1_1->new(
    consumer_key => $cfg->{consumer_key},
    consumer_secret => $cfg->{consumer_secret},
    access_token => $cfg->{users}->{$user}->{access_token},
    access_token_secret => $cfg->{users}->{$user}->{access_secret},
    ssl => 1,
  );
}

sub default_user {
  my $yml = YAML::Tiny->read("$ENV{'HOME'}/.tweemo.yml");
  $yml->[0]{default_user};
}

1;
