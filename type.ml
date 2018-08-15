 open Error

 type ty = 
    |UnitTy
    |IntTy
    |BoolTy
    |VarTy of string
    |FunTy of ty * ty
  
let is_funty t = 
  match t with
  |FunTy(_, _) -> true
  |_ -> raise (TypeError "function type requried")

let arg_type funty = 
  match funty with
  |FunTy(argty, _) -> argty
  |_ -> raise (TypeError "function type requried")
  
let ret_type funty =
  match funty with
  |FunTy(_, rett) -> rett
  |_ -> raise (TypeError "function type requried")

let make_funty argtypes rettype = 
  let rec make_funty' argtypes rettype =
    match argtypes with
    |argt::xs ->
      FunTy(argt, make_funty' xs rettype)
    |[] -> rettype
  in
  match argtypes with
  |[] -> make_funty' [UnitTy] rettype
  | _ -> make_funty' argtypes rettype

let rec string_of_type t =
  match t with
  |UnitTy -> "Unit"
  |IntTy -> "Int"
  |BoolTy -> "Bool"
  |VarTy(name) -> name
  |FunTy(a, r) -> (string_of_type a)^"->"^(string_of_type r)
  
