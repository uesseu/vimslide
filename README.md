# vimslide
標準入出力と相性の良いvimベースのパワポもどきです。  
現時点ではLinuxでKittyを使う事を想定しています。

# 特徴
- vimでパワポもどきする
- 標準入出力とvimscriptを使える

# メリットあるの？
- プレゼン中にシェルスクリプトを差しこめる
  + CUI関連のプレゼンと相性が圧倒的に良い
  + ブラウザを起動できるのでwebとも相性良い
  + VOICEVOXを差しこむと発表者が発言する必要すらない
- 一部界隈で宴会芸できる
- 意外と使いやすい

# 酷いデメリットあるでしょ？
あるぞ！

- フォントを弄れない
- vimmerじゃないと辛い
- 気持ち悪いオタクと思われる
  + 実際にそうだから否定はできない

# 無いと辛いもの
- 標準出力経由で背景を変えられるterminal emulator
- 起動後にフォントのサイズを変えられるterminal emulator

# 有ると素晴しいもの
- 音声合成ソフト
  + 自分で喋る必要すらなくなる
  + 時間制限について事前に計画できる

# 僕の環境
- arch linux
- kitty

# 使いかた
## セパレータの設定
スライドにはセパレータが必要です。絶対に文章中で使わないような文字列をセパレータにしましょう。
ここでは、下キーと上キーを押したら前後の'---'に飛んでいくように設定しています。
また、スクリプトを書く場合に行頭を'.'にするようにしておきます。
さらに、ここでは'\*\*\*'をもう一つのセパレータにして、左右キーで動けるようにします。
\*はvimの上では正規表現になってしまうので、'\\\*\\\*\\\*'という風にします。

```vim
call SlideStart('<down>', '<up>', '---', '.')
call SlideStart('<right>', '<left>', '\*\*\*', '.')
```

2回SlideStartしてもかまいません。
これで、こんな感じにしていきます。

```
---
.![声を出すプログラム]
題名1

- 項目1
- 項目2
- 項目3

--- *** 
題名2

本文1

---
題名3

本文2

--- ***

'\*\*\*'で横飛び、'---'で縦飛びです。

---

## コマンド
このプログラムではvim scriptを書く事ができます。
vim scriptでは頭文字が'!'でshellscriptを書けますし、'py3'等を行頭に置くとpythonが書けます。つまり…やりたい放題ですね。

## 一緒に使うと良いものの例
### kitty
高性能で柔軟なターミナルエミュレータ。  
背景を動的に変更できるので、実質的に画像を表示できる。  
https://sw.kovidgoyal.net/kitty/

### VOICEVOX
VOICEVOX本体。音声合成ソフト。  
https://voicevox.hiroshiba.jp/

shellで動くVOICEVOXクライアント  
ずんだもんが代りに喋ってくれる。
https://github.com/uesseu/ninvoicevox

# 例
事前にこんな感じのをvimrcに書いておきます。
```
function StartSlide()
  call SlideStart('<down>', '<up>', '---', '.')
  call SlideStart('<right>', '<left>', '\*\*\*', '.')
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight LineNr ctermbg=none
  highlight Folded ctermbg=none
  highlight EndOfBuffer ctermbg=none
endfunction
```


start.shを作って、それを起動します。そんで、起動後に画面の大きさを調整します。
```sh start.sh
kitty \
    -o allow_remote_control=yes\
    -o enabled_layouts=tall\
	-o font_size="$font_size"\
	-o background_opacity=1.0\
	-o background_image="$background_image"\
	-o background_image_layout=cscaled\
        -o cursor_blink_interval=0\
	-o cursor_shape=beam\
	vim '+call StartSlide()' slide.txt
```

ここでポイントは下記です。
```
    -o allow_remote_control=yes\
    -o enabled_layouts=tall\
```
これによってkittyがコマンドラインによるリモートコントロールを受けつけるようになります。なので、例えば

```
kitten @ set-background-image [/path/to/image.png]
```

みたいにすると良いのです。これをスライド中でどうつかうかというと

```
---
.call system('kitten @ set-background-image [/path/to/image1.png]')
.sleep 1
.call system('kitten @ set-background-image [/path/to/image2.png]')
.sleep 2
こんにちは


---
```

このようにすると、「こんにちは」と表示した後で1秒ごとに背景画像を更新します。
応用すると、VOICEVOXを起動した状態でninvoiceを使って…

```
---
.!echo こんにちは、ずんだもんなのだ。| ninvoice -c&
.call system('kitten @ set-background-image [/path/to/zundamon1.png]')
.sleep 1
.call system('kitten @ set-background-image [/path/to/zundamon2.png]')
.sleep 2
こんにちは、ずんだもんなのだ


---
```

こうすると、ずんだもんが動きながら喋るようになります。

# TODO
- [] neovim対応
