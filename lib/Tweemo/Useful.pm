package Tweemo::Useful;
use strict;
use warnings;
use autodie;
use utf8;

use DBD::SQLite;
use DBI;

use base qw(Exporter);
our @EXPORT = qw(any_japanese tategaki with_db);

sub with_db {
  my ($db, $fn) = @_;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", undef, undef,
                        { AutoCommit => 0, RaiseError => 1,
                          sqlite_unicode => 1 });
  my $ret = $fn->($dbh);
  $dbh->disconnect;
  $ret;
}

sub any_japanese {
  if ($_[0] =~ /\p{Han}|\p{Hiragana}|\p{Katakana}/) {
    1;
  } else {
    0;
  }
}

sub all (&@) {
  my $func = shift;
  for (@_) {
    if (!$func->()) {
      return 0;
    }
  }
  1;
}

sub long_zip {
  my @args = @_;
  my $ret;
  for (;;) {
    my @xs = map { shift @$_ } @args;
    if (all { !defined $_ } @xs) {
      return $ret;
    }
    push @$ret, [@xs];
  }
}

sub tategaki {
  my ($str, $c) = @_;
  my $ret;
  for my $xs (@{&long_zip(map { [split('', $_)] } split("\n", $str))}) {
    my $tmp;
    for my $x (reverse @$xs) {
      if (!defined $x) {
        push @$tmp, $c;
      } else {
        push @$tmp, $x;
      }
    }
    push @$ret, join('', @$tmp);
  }
  join("\n", @$ret);
}

1;
