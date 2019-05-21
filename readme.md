# mio
フロント側をocamlでバックエンドをLLVMで実装した関数型風味の言語です．(not関数型)

## usage

## install stap
1. `git clone`
2. `opam install omake menhir llvm`
3. `omake`

出力のパターンはデバッグも兼ねて三つ用意しました．とりあえずソースコードを動かしたいときはこのファイルのカレントディレクトリで`sh compile.sh examples/var.mio ./output.native`で表示可能です．

### output to IR
* `./region_mio`
* `write to code`
* `end to EOF(use mac to C-d)`

### output to bitcode
* `./region_mio (filename)`

### output to .mio compile
* `sh compile.sh (soucecodefile) (to outputfile)`

## 何をしたのか
これで構文に関する型の推論規則とそれらの意味論の定義を完全導出したので型システムの健全性を暗黙的に示すことができた
型システムの健全性とは環境Eの元でeを評価すると値vの型付けは必ず型付け規則に基づいてtになるということから関数の参照透明性が示し、副作用がないものを作った
## 謝辞
事前課題をギリギリでこなしハラハラさせてしまい、3日で雑な言語をでっち上げることになったK先生には多大なご迷惑をおかけしました・・・圧倒的感謝です．
