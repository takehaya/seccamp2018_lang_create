# mio
フロント側をocamlでバックエンドをLLVMで実装した関数型風味の言語です．(not関数型)

## usage

## install stap
1. `git clone`
2. `opam install omake menhir llvm`
3. `omake`

### output to IR
* `./region_mio`
* `write to code`
* `end to EOF(use mac to C-d)`
### output to bitcode
* `./region_mio (filename)`

## output to .mio compile
* `sh compile.sh (soucecodefile) (to outputfile)`

## 謝辞
事前課題をギリギリでこなしハラハラさせてしまったK先生には多大なご迷惑をおかけしました・・・圧倒的感謝です．

また参考にした資料に圧倒的感謝です．