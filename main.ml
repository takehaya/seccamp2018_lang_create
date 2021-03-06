open Codegen
open Typify
open Syntax
open Type
open Printf
(* main *)
let () =
  (* parse input *)
  let program = Parser.toplevel Lexer.token (Lexing.from_channel stdin) in
  (* type check *)
  let typed_program = Typify.typify program in

  (* codegen *)
  let llvm_module = Codegen.codegen typed_program in

  (* output llvm ir *)
  let _ =
    if Array.length Sys.argv > 1 then 
    begin
      (* assertion *)
      Llvm_analysis.assert_valid_module llvm_module;
      (* output bitcode to file *)
      let oc = open_out Sys.argv.(1) in
      Llvm_bitwriter.output_bitcode oc llvm_module |> ignore;
      close_out oc;
      ()
    end
    else 
      (* output ir to stderr *)
      Llvm.dump_module llvm_module
  in
  ()