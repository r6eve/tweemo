package Tweemo;
use strict;
use warnings;
use version; our $VERSION = version->declare("v1.0.5");

1;
__END__

=encoding utf8

=head1 NAME

tweemo - CLI-based twitter client calculating emotional value of tweet

=head1 SYNOPSIS

  # add twitter account
  > tweemo add

  # tweet in Japanese in default account
  > tweemo post 今日も一日がんばるぞい！

  # tweet in English
  > tweemo post "Oh god, it's a bikeshed discussion."

  # force tweemo to use English dictionary
  > tweemo post --en "Craving sushi 🍣 辛い"
  # By default, string containing Japanese (漢字，ひらがな，カタカナ) is regarded
  # as Japanese text. So, use --en option to calculate the value in English.

  # tategaki
  > tweemo post --tate '今日も一日
  がんばるぞい！'

  # tweet in registerd multiple account 'mult_acc'
  > tweemo --user mult_acc post もうこんな仕事辞めたいぞい…

  # reply to the tweet http://twitter.com/foo/status/012345678901234567
  > tweemo post '@foo こんばんは' --id 012345678901234567

  # retweet the tweet http://twitter.com/foo/status/012345678901234567
  > tweemo rt 012345678901234567

  # favorite the tweet http://twitter.com/foo/status/012345678901234567
  > tweemo fav 012345678901234567

  # delete my tweet http://twitter.com/my_acc/status/987654321098765432
  > tweemo del 987654321098765432

  # show 20 most recent timeline
  > tweemo tl
  # show 100 timeline (max 200)
  > tweemo tl -n 100
  # calculate all tweet's average emotional value
  > tweemo tl --all

  # User streams (default action)
  > tweemo st
  > tweemo
  # User streams with speech
  > tweemo st --say
  # calculate all tweet's average emotional value
  > tweemo st --all

  # show all lists
  > tweemo lists
  # show timeline of the specified list (include RTs)
  > tweemo tl --list foo
  # append emotional value
  > tweemo tl --list foo --all

  # show 20 most recent @foo's tweets
  > tweemo @foo
  # show 100 tweets (max 200)
  > tweemo @foo -n 100

  # show 15 tweets matching a specified query
  > tweemo search 'twitter lang:ja'
  # show 50 tweets (max 100)
  > tweemo search 'twitter lang:ja' -n 50

  # upload image (jpg, png, gif)
  > tweemo post 昼ご飯 --img image.jpg

  # print emotional value, but don't tweet
  > tweemo --dry-run 美味しい
  美味しい (0.9914)

  # show 20 most recent direct messages sent to or sent by me
  > tweemo dm
  # show 100 direct messages (max 400)
  > tweemo dm -n 100

  # send a direct message to @foo
  > tweemo post 今時間ある？ -d foo

=head1 DESCRIPTION

tweemo is a command line tool to tweet message.
This calculates an emotional value of tweet, using semantic
orientations of words.

=head2 DEPENDENCIES

If you tweet japanese message, install Mecab, and if also tweet english
message, install TreeTagger, too.

=head1 AUTHOR

r6eve

=head1 COPYRIGHT

r6eve 2014-

=head1 LICENSE

L<The MIT License|http://opensource.org/licenses/MIT>

=head1 SEE ALSO

L<tw|https://github.com/shokai/tw>

L<MeCab|https://code.google.com/p/mecab/>

L<TreeTagger|http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/>

=cut
