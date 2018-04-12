Tweemo
======

`tweemo` is a CLI-based twitter client calculating emotional value of tweet.

## Description

* Verb, noun, adjective, and adverb in tweet are assigned values from -1 to 1
  (if there is a word which doesn't exist in dictionaries, the value is 0).
  Then, calculates an average value, and appends it to tweet.

* Used dictionaries [Semantic Orientations of Words](http://www.lr.pi.titech.ac.jp/~takamura/pndic_en.html)

## Requirement

* [MeCab](https://code.google.com/p/mecab/) (required to tweet in Japanese)
* [TreeTagger](http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/) (required to tweet in English)
* [MPlayer](www.mplayerhq.hu/) (required to User streams with speech)
* Perl modules (AnyEvent::Twitter::Stream, DBD::SQLite, DBI, File::Which, Math::Round, Moo, Net::Twitter::Lite::WithAPIv1_1, Statistics::Lite, YAML::Tiny)

## Usage

```bash
# add twitter account
> tweemo add

# tweet in Japanese in default account
> tweemo post 今日も一日がんばるぞい！

# tweet in English
> tweemo post "Oh god, it's a bikeshed discussion 😞"

# force tweemo to use English dictionary
> tweemo post --en "Craving sushi 🍣 辛い"
# By default, string containing Japanese (漢字，ひらがな，カタカナ) is regarded
# as Japanese text. So, use --en option to calculate an emotional value in English.

# tategaki
> tweemo post --tate '今日も一日
がんばるぞい！'

# tweet in registerd multiple account 'mult_acc'
> tweemo --user mult_acc post 'くまったくまったぞい'

# reply to the tweet http://twitter.com/foo/status/012345678901234567
> tweemo post '@foo こんばんは' --id 012345678901234567

# retweet the tweet http://twitter.com/foo/status/012345678901234567
> tweemo rt 012345678901234567

# favorite the tweet http://twitter.com/foo/status/012345678901234567
> tweemo fav 012345678901234567
# show 20 favorite tweets
> tweemo fav --list
# show 100 favs (max 200)
> tweemo fav --list -n 100
# unfavorite the tweet http://twitter.com/foo/status/012345678901234567
> tweemo fav --del 012345678901234567

# delete my tweet http://twitter.com/my_acc/status/987654321098765432
> tweemo del 987654321098765432

# show 20 most recent timeline
> tweemo tl
# show 100 timeline (max 200)
> tweemo tl -n 100
# calculate average emotional value of each tweets
> tweemo tl --emo

# show all lists
> tweemo lists
# show timeline of the specified list (include RTs)
> tweemo tl --list foo
# append emotional value
> tweemo tl --list foo --emo

# User streams (default action)
> tweemo st
> tweemo
# User streams with speech
> tweemo st --say
# calculate average emotional value of each tweets
> tweemo st --emo

# show 20 most recent @foo's tweets
> tweemo @foo
# show 100 tweets (max 200)
> tweemo @foo -n 100
# calculate average emotional value of each tweets
> tweemo @foo --emo

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
```

## Installation

```bash
# Arch
> yaourt -S mecab mecab-ipadic
# Debian
> sudo apt-get install mecab mecab-ipadic-utf8
# OS X
> brew install mecab mecab-ipadic
# If you use others, install those from package manager or source.

> cpanm AnyEvent::Twitter::Stream DBD::SQLite DBI File::Which Math::Round Moo Net::OAuth Net::Twitter::Lite::WithAPIv1_1 Statistics::Lite YAML::Tiny

> git clone https://github.com/r6eve/tweemo.git
# or, download https://github.com/r6eve/tweemo/archive/master.zip
```

Then, edit `CONSUMER_KEY` and `CONSUMER_SECRET` in lib/Tweemo/Account.pm.

If you want to tweet in English, you should install TreeTagger. Then, add treetagger/{bin,cmd} to PATH.

* `add command` adds twitter account.
  * Go to Twitter authentication page, and sign in. Next, if you enter PIN in terminal, ~/.tweemo.yml is updated.
* Support multiple accounts.
  * Default account is 'default_uesr: my_aco' in ~/.tweemo.yml. You can change default account by editing it.
* --say option speech in Japanese by Google Translate. You should install MPlayer, and add a path of MPlayer to PATH.

## Tips

```bash
# delete my 200 tweets
> tweemo @my_account -n 200 |perl -nle 'print $1 if m@^\[\d\d\/\d\d.+http://twitter\.com/.+/status/(\d+)$@' |xargs -n1 tweemo del

# unfavorite 200 tweets
> tweemo fav --list -n 200 |perl -nle 'print $1 if m@^\[\d\d\/\d\d.+http://twitter\.com/.+/status/(\d+)$@' |xargs -n1 twe fav --del

# get a usage summary of Twitter clients at my TL
> tweemo tl -n 200 |perl -nle 'print $1 if /^(?:: .+)?: (.+ https?:.+)$/' |sort |uniq -c |sort -nr
     73 Twitter for iPhone http://twitter.com/download/iphone
     44 Twitter Web Client http://twitter.com
     16 mikutter http://mikutter.hachune.net/
     15 ｱｶｲﾄﾘ4 http://akaitori.info/
     13 TweetDeck https://about.twitter.com/products/tweetdeck
      8 Twitter for Mac http://itunes.apple.com/us/app/twitter/id409789998?mt=12
      5 Hatena http://www.hatena.ne.jp/guide/twitter
      5 twicca http://twicca.r246.jp/
      4 Twitter for Android http://twitter.com/download/android
      4 Mobile Web (M5) https://mobile.twitter.com
      3 Janetter for Android http://janetter.net/
      2 IFTTT http://ifttt.com
      2 Foursquare http://foursquare.com
      2 Echofon http://www.echofon.com/
      1 twiroboJP http://twirobo.com/
      1 sekicoco http://sekico.co/
      1 iOS http://www.apple.com

# plot (you should install R and ggplot2)
> tweemo tl -n 200 |perl -nle 'print $1 if /^(?:: .+)?: (.+ https?:.+)$/' |sort |uniq -c |sort -nr |Rscript --vanilla tips/plot_cli.R
```
