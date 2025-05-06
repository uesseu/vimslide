# vimslide
標準入出力と相性の良いvimベースのパワポもどきです。  
現時点ではLinuxやMACで下記のいずれかを想定しています。
Windowsではsixelとかが苦しいのです。
もし、画像要らないならWindowsでもできます。

- sixel対応のターミナルエミュレータでlibsixelを使う。
- Kittyでkittyの独自プロトコルを使う。

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
動的に背景画像を変えられてファンシー。独自プロトコルだけど、vimでも画像を表示できるぞ！

https://sw.kovidgoyal.net/kitty/

sixel対応のweztermも有力。標準的プロトコルで画像を表示できるぞ！リガチャもできてファンシー。  

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
スライドにはセパレータが必要です。セパレータはデフォルトで```"""```であり、これが長くなるか短かくなるかです。
ここでは、下キーと上キーを押したら前後の```"""""```に飛んでいくように設定しています。
さらに、ここでは```""""""```をもう一つのセパレータにして、左右キーで動けるようにします。

```vim
call slide#set_key('<down>', 0, 5)
call slide#set_key('<up>', 1, 5)
call slide#set_key('<right>', 0, 6)
call slide#set_key('<left>', 1, 6)
```

2回slide#set_keyしてもかまいません。第二引数は上に行くか下に行くかです。第三引数はダブルクォーテーションの数です。ちなみに、上記を毎回書くのだるかったので下記のプリセットが色々してくれます。

```vim
slide#start(3, '<down>', '<up>')
```

これで、こんな感じにしていきます。

```
"""
題名1

- 項目1
- 項目2
- 項目3

"""EOF
call slide#image('img.png', [0, 0, 3, 3])
EOF
題名2

本文1

"""
題名3

本文2

```

vim scriptを埋めこめます。ヒアドキュメント風に書きましょう。僕は題名的に書いています。

ちなみに、本文の長さを気にする必要はありません。

```vim
let g:slide#minimum_lines = 20
```

とすると自動で見せたい所を拡張してくれます。
デフォルトで20です。

## コマンド
このプログラムではvim scriptを書く事ができます。
vim scriptでは頭文字が'!'でshellscriptを書けますし、'py3'等を行頭に置くとpythonが書けます。つまり…やりたい放題ですね。

## 画面が更新されない時
redraw!を使って下さい。redraw!を使っても更新されなければ、vimの背景を透過させて下さい。

```
""" SCRIPT
redraw!
SCRIPT
```


## ウェイトモード
スライドのスクリプトをウェイトモードにする事ができます。
これによって、フラグメントや画像の差し替えを実現できます。

```
""" SCRIPT
call slide#wait()
SCRIPT
```

これを使う場合は必ずvimslideのページ送り機能を使って最後までエフェクトを出して下さい。手動で移動した場合でも、そのスライドのスクリプトを愚直に実行されてしまいます。

## 強調
vimはhilightコマンドとmatchコマンドによってハイライトをします。
下記のようにどのようにハイライトするのかを決めて、
```//```の中の文字列にマッチさせます。

```
""" SCRIPT
highlight Warn1 ctermbg=red ctermfg=white bold
match Warn1 /vim/
SCRIPT
```

## フラグメント
フラグメントを使うためには以下の手順を踏みます。

- slide#put_text関数でスライド中の文字列を消しておく
- slide#wait関数でスライドをウェイトモードにする
- slide#put_text関数でスライド中に文字列を書き加える

```
"""SCRIPT
call slide#put_text(3, '')
call slide#wait()
call slide#put_text(3, '- hoge')
```

## 画像
sixel対応ターミナルやkittyで画像を表示できます。細かい挙動は違うかも。
まず、ターミナルの設定をします。ここで、候補はkittyかsixelです。デフォルトはsixel。
注意点として、特にkittyでですが、vimの背景にkittyプロトコルの画像が焼きついてしまう事があります。必ずvimの背景は透過するようにしましょう。tmux経由でもできなくなります。ここは割と気難しい。

```
let g:slide#terminal = 'kitty'
```

あとは、下記です。

```
call slide#image([ファイル名], [x軸, y軸, 幅, 高さ])
```

スライドを遷移する場合は画像を消える事がほとんどですが、消えない時や動的スライドの途中で消す必要がある場合は下記の通りです。

```
call slide#clear_image()
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
call silent! system("kitten @ set-background-image /path/to/image.png")
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

# vim scriptコンパチ記法
```@```をヒアドキュメント風記法につけて下さい。
そんで、実際にヒアドキュメントを書いて下さい。
そうすると、vim scriptとして矛盾しない記法にできます。
つまり、vimの支援を受けられるわけです。
内容はヒアドキュメントの内容を表示することになります。
あとは適当にスクリプトを書けばいいです。

```
""" @AboutME
call slide#img('img.png', 0, 0, 3, 3)
let AboutMe =<< EOF
内容
[EOF](EOF)
```


# TODO
- [] neovim対応
- [] windows対応
- [] helpを作る <- 超面倒
- Terminal対応
  - [x] sixel対応
  - [x] kitty対応
