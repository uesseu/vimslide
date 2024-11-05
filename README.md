# vimslide
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
https://sw.kovidgoyal.net/kitty/


## 有ると素晴しいもの
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


# 凝った使い方の例

下記のようなスライドを目指します。
これは、ずんだもんが「こんにちは、ずんだもんなのだ」と言いながら、1秒後に表情を変えるものです。
下記のようなテキストファイルをslide.txtとして保存しましょう。
一番上の空白は忘れずに入れて下さい。

```


---
.Zundamon こんにちは、ずんだもんなのだ。
.Image /path/to/image1.png
.sleep 1
.Image /path/to/image2.png
こんにちは、ずんだもんなのだ


---
```

事前に下記のような感じのをstyle.vimというファイルに書いておきます。
これはスライドのデザインや利便性を高めるためのファイルとして使います。ま、スライド自体に全部書いてもいいのですけれどね。


```vim
function StartSlide()
  call SlideStart('<down>', '<up>', '---', '.')
  call SlideStart('<right>', '<left>', '\*\*\*', '.')
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight LineNr ctermbg=none
  highlight Folded ctermbg=none
  highlight EndOfBuffer ctermbg=none
endfunction

command! -nargs=1 Sh silent! call system(<args>)
command! -nargs=1 Zundamon silent! call system("echo <args> | ninvoice -c &")
command! -nargs=1 Image silent! call system("kitten @ set-background-image <args>")
call StartSlide()
```

- StartSlideは2種類のセパレータを設定しつつ、画面を透過させます。
- Shはシェルスクリプトを単純に実行します。
- Zundamonはninvoiceを通してずんだもんがバックグラウンドで喋ってくれます。
- Imageはターミナルエミュレータkittyの背景画像を変えます。


下記のようなシェルスクリプトを作って、それを起動します。そんで、起動後に画面の大きさを調整します。


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
	vim '+source style.vim' slide.txt
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

みたいにするとpath/to/image.pngが背景画像になります。ただし、先程vimのコマンドを作りましたから下記でいいです。

```vim
.Image /path/to/image.png
```

これなら難しくないですね！

```
---
.Image /path/to/image1.png
.sleep 1
.Image /path/to/image2.png
こんにちは


---
```

このようにすると、「こんにちは」と表示した後で1秒後に背景画像を更新します。
同時にVOICEVOXを起動した状態でZundamonコマンドを使って…

```
---
.Zundamon こんにちは、ずんだもんなのだ。
.Image /path/to/image1.png
.sleep 1
.Image /path/to/image2.png
こんにちは、ずんだもんなのだ


---
```

こうすると、ずんだもんが動きながら喋るようになります。

# TODO
- [] neovim対応
- [] windows対応
- [] helpを作る
