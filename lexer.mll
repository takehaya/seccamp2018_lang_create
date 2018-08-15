{
  let reserve = [
    ("func", Parser.FUNC);
    ("if", Parser.IF);
    ("else", Parser.ELSE);

    ("true", Parser.TRUE);
    ("false", Parser.FALSE);
  ]
}
(* 正規表現の略記 *)
let space = [' ' '\t' '\n' '\r']
let digit = ['0'-'9']
let lower = ['a'-'z']
let upper = ['A'-'Z']

rule token = parse
  |[' ' '\n']+ {token lexbuf}(* skip space *)
  |digit+ as num
  { Parser.NUMBER (int_of_string num) }

  |"#" {comment lexbuf}

  |"=" { Parser.EQUAL }
  |"+" { Parser.PLUS }
  |"*" { Parser.ASTERISK }
  |"-" { Parser.MINUS }
  |"/" { Parser.SLASH }

  |"("  { Parser.LPAREN }
  |")"  { Parser.RPAREN }
  |"{"  { Parser.LBRACE }
  |"}"  { Parser.RBRACE }

  |"=="  { Parser.EQEQ }
  |"!="  { Parser.NOTEQ }
  |"<"  { Parser.LANGLE }
  |">"  { Parser.RANGLE }
  |"<="  { Parser.LANGLE_EQ }
  |">="  { Parser.RANGLE_EQ }

  |","  { Parser.COMMA }
  |":"  { Parser.COLON }

  |(lower|digit|lower|upper|'_')+ as id
  {
    try List.assoc id reserve
    with _ -> Parser.ID (id)
  }
  
  |eof {Parser.EOF}

  and comment = parse
  |['\n'] {token lexbuf}
  |_ {comment lexbuf}