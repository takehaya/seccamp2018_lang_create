%{
   open Syntax
%}

%token EQUAL
%token COMMA COLON
%token PLUS MINUS ASTERISK SLASH
%token LPAREN RPAREN LBRACE RBRACE
%token EQEQ NOTEQ LANGLE RANGLE LANGLE_EQ RANGLE_EQ

%token FUNC
%token EOF
%token IF ELSE
%token TRUE FALSE
%token <int> NUMBER
%token <string> ID

%start toplevel
%type <Syntax.exp> toplevel
%%

toplevel:
  |Expr* EOF { MultiExpr($1) }

Expr:
    |AssignExpr {$1}

AssignExpr:
    |FUNC id=ID EQUAL exp=Arithmetic { Assign(id, None, exp) }
    |FUNC id=ID COLON t=Type EQUAL exp=Arithmetic { Assign(id, Some(t), exp) }
    |Arithmetic{$1}

Arithmetic:
    |Arithmetic PLUS Term {Call ("+", [$1; $3;])}
    |Arithmetic MINUS Term {Call ("-", [$1; $3;])}
    |Term{ $1 }

Term:
    |Term ASTERISK Factor {Call ("*", [$1; $3])}
    |Term SLASH Factor {Call ("/", [$1; $3])}
    |Compare { $1 }

Compare:
    |Compare EQEQ Factor { Call ("==", [$1; $3]) }
    |Compare NOTEQ Factor { Call ("!=", [$1; $3]) }
    |Compare LANGLE Factor { Call ("<", [$1; $3]) }
    |Compare RANGLE Factor { Call (">", [$1; $3]) }
    |Compare LANGLE_EQ Factor { Call ("<=", [$1; $3]) }
    |Compare RANGLE_EQ Factor { Call (">=", [$1; $3]) }
    |Factor { $1 }

Factor:
    |MINUS Factor { Call("__neg", [$2]) }
    |Number { $1 }
    |IFExpr { $1 }
    |fname = ID LPAREN args = separated_list(COMMA, Expr) RPAREN { Call (fname, args)}
    |LBRACE list (Expr) RBRACE { MultiExpr ( $2 ) }
    |DefunExpr { $1 }

DefunExpr:
    |FUNC name = ID LPAREN args =separated_list(COMMA, Arg)
        RPAREN EQUAL body = Expr { Defun(name, args, None, body) }
    |FUNC name = ID LPAREN args = separated_list(COMMA, Arg)
        RPAREN COLON rett = Type EQUAL body = Expr { Defun(name, args, Some(rett), body) }

Arg:
    |name=ID {(name, None)}
    |name=ID COLON t=Type{ (name, Some(t)) }

IFExpr:
  |IF cond = Expr t = Expr ELSE e = Expr { If(cond, t, e) }

Number:
    |ID {Var $1}
    |NUMBER { Int $1 }
    |TRUE { Bool(true) }
    |FALSE { Bool(false) }

Type:
    |ID { $1 }
