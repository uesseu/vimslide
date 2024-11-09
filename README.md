# vimslide
このリポジトリは現時点では絶賛開発初期状態で安定してません。破壊的更新を繰り返しています。
というか現時点ではジョークソフトなので…。


標準入出力と相性の良いvimベースのパワポもどきです。  
現時点ではLinuxでKittyを使う事を想定しています。

# 特徴
- vimでパワポもどきする
- 標準入出力とvimscriptを使える

<details>
<summary> メリットとデメリット </summary>

## メリットあるの？
- プレゼン中にシェルスクリプトを差しこめる
  + CUI関連のプレゼンと相性が圧倒的に良い
  + ブラウザを起動できるのでwebとも相性良い
  + VOICEVOXを差しこむと発表者が発言する必要すらない
- 一部界隈で宴会芸できる
- 意外と使いやすい

## 酷いデメリットあるでしょ？
あるぞ！

- フォントを弄れない
- vimmerじゃないと辛い
- 軽くふざけてるだけなのに、ものすごーくふざけてると思われてしまう！


</details>

# 必要な環境
## 無いと辛いもの
- 標準出力経由で背景を変えられるterminal emulator
- 起動後にフォントのサイズを変えられるterminal emulator
 
具体的にはkitty等。  
動的に背景画像を変えられてファンシー。独自プロトコルだけど、vimでも画像を表示できるぞ。

https://sw.kovidgoyal.net/kitty/

sixel対応のweztermも有力。  

https://wezfurlong.org/wezterm/


## 有ると宴会芸になるもの
VOICEVOX本体。音声合成ソフト。  
https://voicevox.hiroshiba.jp/

shellで動くVOICEVOXクライアント  
ずんだもんが代りに喋ってくれる。
https://github.com/uesseu/ninvoicevox

## 僕の環境
下記は例です。

- arch linux
- kitty
- VOICEVOX engine
- ninvoicevox

# 使いかた
## セパレータの設定
スライドにはセパレータが必要です。絶対に文章中で使わないような文字列をセパレータにしましょう。
ここでは、下キーと上キーを押したら前後の```---```に飛んでいくように設定しています。
また、スクリプトを書く場合に行頭を```.```にするようにしておきます。
さらに、ここでは```***```をもう一つのセパレータにして、左右キーで動けるようにします。
\*はvimの上では正規表現になってしまうので、```\*\*\*```という風にします。

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
```

## コマンド
このプログラムではvim scriptを書く事ができます。
vim scriptでは頭文字が'!'でshellscriptを書けますし、'py3'等を行頭に置くとpythonが書けます。つまり…やりたい放題ですね。

## 画面が更新されない時
redraw!を使って下さい。

```
---
.redraw!

```


## ウェイトモード
スライドのスクリプトをウェイトモードにする事ができます。
これによって、フラグメントや画像の差し替えを実現できます。

```
---
.call slide#wait()
```

## 強調
vimはhilightコマンドとmatchコマンドによってハイライトをします。
下記のようにどのようにハイライトするのかを決めて、
```//```の中の文字列にマッチさせます。

```
---
.highlight Warn1 ctermbg=red ctermfg=white bold
.match Warn1 /vim/
```

## フラグメント
フラグメントを使うためには以下の手順を踏みます。

- slide#put_text関数でスライド中の文字列を消しておく
- slide#wait関数でスライドをウェイトモードにする
- slide#put_text関数でスライド中に文字列を書き加える

```
---
.call slide#put_text(3, '')
.call slide#wait()
.call slide#put_text(3, '- hoge')
```

## 画像
sixel対応ターミナルやkittyで画像を表示できます。細かい挙動は違うかも。
まず、ターミナルの設定をします。ここで、候補はkittyかsixelです。デフォルトはsixel。

```
let g:slide#terminal = 'kitty'
```

あとは、下記です。

```
call slide#image([ファイル名], [x軸], [y軸], [幅], [高さ])
```

スライドを遷移する場合は画像を消す必要があるので、消しましょう。

```
call slide#clear_image([ファイル名], [x軸], [y軸], [幅], [高さ])
```

## kittyで背景画像を動的に変える
kittyの場合は下記のようなシェルスクリプトを作って、それを起動すれば動的に背景画像を変えられます。そんで、起動後に画面の大きさを調整します。


```sh
font_size=40
background_opacity=1.0
kitty \
    -o allow_remote_control=yes\
    -o enabled_layouts=tall\
	-o font_size="$font_size"\
	-o background_opacity=1.0\
	-o background_image="$background_image"\
	-o background_image_layout=cscaled\
        -o cursor_blink_interval=0\
	-o cursor_shape=beam\
	vim slide.txt
```

ここでポイントは下記です。
```
    -o allow_remote_control=yes\
    -o enabled_layouts=tall\
```
これによってkittyがコマンドラインによるリモートコントロールを受けつけるようになります。なので、例えば

```
.call silent! system("kitten @ set-background-image /path/to/image.png")
```

みたいにするとpath/to/image.pngが背景画像になります。
せっかくだからコマンドを作りましょう。

```
command! -nargs=1 BGImage silent! call system("kitten @ set-background-image <args>")
```

これなら難しくないですね！

```vim
.BGImage /path/to/image.png
```



# TODO
- [] neovim対応
- [] windows対応
- [] helpを作る <- 超面倒
- Terminal対応
  - [x] sixel対応
  - [x] kitty対応
