let () =
  let exprs = Parser.toplevel Lexer.token (Lexing.from_channel stdin) in
  List.iter (fun expr -> Sub.print_expr stdout expr; print_newline ()) exprs;;
(* 
  let print_int_list = List.print Int.print stdout

let main() =
  let ast = Parser.toplevel Lexer.token Lexing.from_channel stdin in
    print_int_list(ast)

let _ = main() *)