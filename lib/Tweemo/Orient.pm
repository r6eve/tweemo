package Tweemo::Orient;
use strict;
use warnings;
use utf8;

use Encode qw(decode);
use File::Which;
use FindBin qw($RealBin);
use Math::Round qw(nearest);
use Memoize;
use Statistics::Lite qw(mean);

use Tweemo::Useful qw(any_japanese with_db);

use base qw(Exporter);
our @EXPORT = qw(orient);

sub orient {
  my ($self, $msg, $en) = @_;
  if (defined $en || !any_japanese($msg)) {
    calculator($msg, \&calc_orient_en);
  } else {
    calculator($msg, \&calc_orient_ja);
  }
}

sub calculator {
  my ($str, $fn) = @_;
  my $os = $fn->($str);
  if (defined $os) {
    nearest(0.0001, mean(@$os));
  } else {
    undef;
  }
}

sub calc_orient_en {
  my ($str) = @_;
  my $cmd = which('tree-tagger-english');
  if (!defined $cmd) {
    print STDERR "You should install TreeTagger\n";
    exit 1;
  }
  $str =~ s/(["`])/\\$1/g;
  memoize('get_orient_en');
  my $ret;
  for my $x (split(/\n/, `echo "$str" |$cmd 2>/dev/null`)) {
    if ($x =~ /^.+\t(.+)\t(.+)$/) {
      my ($p, $l) = ($1, lc $2);
      if (defined ($p = pos_symbol_en($p))) {
        push @$ret, get_orient_en($l, $p);
      }
    }
  }
  $ret;
}

sub calc_orient_ja {
  my ($str) = @_;
  my $cmd = which('mecab');
  if (!defined $cmd) {
    print STDERR "You should install MeCab\n";
    exit 1;
  }
  $str =~ s/(["`])/\\$1/g;
  memoize('get_orient_ja');
  my $ret;
  for my $x (split(/\n/, `echo "$str" |$cmd 2>/dev/null`)) {
    if ($x =~ /^.+\t(.+)$/) {
      my ($p, $w, $r) = (split(/,/, decode('UTF-8', $1)))[0, 6, 7];
      if (defined ($p = pos_symbol_ja($p)) && defined $w && defined $r) {
        push @$ret, get_orient_ja($w, $r, $p);
      }
    }
  }
  $ret;
}

sub pos_symbol_en {
  my ($pos) = @_;
  # Tag Set https://courses.washington.edu/hypertxt/csar-v02/penntable.html
  if ($pos =~ /^(?:V(?:B[DGNPZ]?|V[DGNPZ]?|D[DG]?|H[NPZ]))$/) {
    'v';
  } elsif ($pos =~ /^(?:(?:N(?:NS?|PS?)|PP))$/) {
    'n';
  } elsif ($pos =~ /^(?:JJ[RS]?)$/) {
    'a';
  } elsif ($pos =~ /^(?:RB[RS]?)$/) {
    'r';
  } else {
    undef;
  }
}

sub pos_symbol_ja {
  my ($pos) = @_;
  for (qw(動詞 名詞 形容詞 副詞 助動詞)) {
    if ($pos eq $_) {
      return $pos;
    }
  }
  undef;
}

sub get_orient_en {
  my ($word, $pos) = @_;
  with_db("$RealBin/../db/pn_en.dic.db", sub {
    my ($dbh) = @_;
    my $sth = $dbh->prepare("SELECT orient FROM dictionary WHERE word=? AND pos=?");
    $sth->execute($word, $pos);
    while (my $ar = $sth->fetchrow_arrayref) {
      return $ar->[0] + 0;
    }
    0;
  });
}

sub get_orient_ja {
  my ($word, $reading, $pos) = @_;
  with_db("$RealBin/../db/pn_ja.dic.db", sub {
    my ($dbh) = @_;
    my $sth = $dbh->prepare("SELECT orient FROM dictionary WHERE word=? AND reading=? AND pos=?");
    $sth->execute($word, $reading, $pos);
    while (my $ar = $sth->fetchrow_arrayref) {
      return $ar->[0] + 0;
    }
    0;
  });
}

1;
