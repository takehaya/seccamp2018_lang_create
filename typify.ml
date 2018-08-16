open Type
open Syntax
open Error

type tyenv = (string, ty) Hashtbl.t list (* ("x", IntTy); ("y", VarTy("'y")); ... *)
type tysubst = (string * ty) list (* ("'y", IntTy); ("'z", VarTy("'y")); ... *)

let builtin_optypes = [
  ("print",  FunTy(VarTy("'__print"), UnitTy) );
  ("+",  FunTy(IntTy, FunTy(IntTy, IntTy)) );
  ("-",  FunTy(IntTy, FunTy(IntTy, IntTy)) );
  ("__neg",  FunTy(IntTy, IntTy) );
  ("*",  FunTy(IntTy, FunTy(IntTy, IntTy)) );
  ("/",  FunTy(IntTy, FunTy(IntTy, IntTy)) );
  ("==", FunTy(IntTy, FunTy(IntTy, BoolTy)) );
  ("!=", FunTy(IntTy, FunTy(IntTy, BoolTy)) );
  ("<",  FunTy(IntTy, FunTy(IntTy, BoolTy)) );
  (">",  FunTy(IntTy, FunTy(IntTy, BoolTy)) );
  ("<=", FunTy(IntTy, FunTy(IntTy, BoolTy)) );
  (">=", FunTy(IntTy, FunTy(IntTy, BoolTy)) );
]

let builtin_types = [
  ("I32", IntTy);
  ("Bool", BoolTy);
]


let rec string_of_tyenv tyenv =
  match tyenv with
  |typtbl::xs ->
      let s = Hashtbl.fold (fun k t s -> s^k^":"^(string_of_type t)^", ") typtbl  "" in
      s^"\n"^(string_of_tyenv xs)
  |[] -> ""

let type_of_name name =
  match List.assoc_opt name builtin_types with
  |Some(t) -> t
  |None -> raise (MioError ("Undefined type:" ^ name))

let type_of_name_opt name =
  match name with
  |Some(name) -> Some(type_of_name name)
  |_ -> None

(* add var with type into current scope *)
let add_var name ty tyenv =
  match tyenv with
  |tytbl::xs -> begin
    let tytbl = Hashtbl.copy tytbl in
    Hashtbl.add tytbl name ty;
    tytbl::xs
  end
  |[] -> begin
    let tytbl = Hashtbl.create 10 in
    Hashtbl.add tytbl name ty;
    [tytbl]
  end

let lookup_scope name tyenv =
  match Hashtbl.find_opt (List.hd tyenv) name with
  |Some(ty) -> Some(ty)
  |None -> None


let rec lookup name tyenv =
  match tyenv with
  |tytbl::xs -> begin
    match Hashtbl.find_opt tytbl name with
    |Some(ty) -> Some(ty)
    |None -> lookup name xs
  end
  |[] -> None


let rec newtypevar name tyenv =
  match lookup name tyenv with
  |Some(_) -> newtypevar ("'"^name) tyenv
  |None -> VarTy(name)
        
let rec occurs var_name ty =
  if var_name = ty then true
  else
    match ty with
    |FunTy(argt, rett) -> (occurs var_name argt) || (occurs var_name rett)
    |_ -> false

(* replace t with ty *)
let rec replace_type (t_1: ty) name (t_2: ty): ty =
  match t_1 with
  |VarTy(name') -> if name = name' then t_2 else t_1
  |FunTy(argt, rett) -> FunTy(replace_type argt name t_2, replace_type rett name t_2)
  |_ -> t_1


let apply_substs (t1: ty) (s: tysubst): ty =
  List.fold_right (fun (name, t2) t1 -> replace_type t1 name t2) s t1


let rec unify_one (t1: ty) (t2: ty): tysubst =
  match (t1, t2) with
  |(VarTy(name1), VarTy(name2)) ->
      if name1 = name2 then []
      else [(name2, t1)]
  |(VarTy(name), _) ->
      if occurs t1 t2 then raise (TypeError "not unifiable") 
      else [(name, t2)]
  |(_, VarTy(name)) ->
      if occurs t2 t1 then raise (TypeError "not unifiable")
      else [(name, t1)]
  |(FunTy(argt1, rett1), FunTy(argt2, rett2)) ->
      unify [(argt1, argt2); (rett1, rett2)]
  |(_, _) ->
      if t1 = t2 then []
      else raise (TypeError ("type mismatched:"^(string_of_type t1)^", "^(string_of_type t2)))

and unify tys =
  match tys with
  |(t1, t2)::xs ->
      let substs = unify xs in
      let subst = unify_one (apply_substs t1 substs) (apply_substs t2 substs) in
      subst @ substs (* list concatenation *)
  |[] -> []

let subst_typenv (tyenv:tyenv) (subst:tysubst) :tyenv =
  List.map
    (fun typtbl -> 
      Hashtbl.filter_map_inplace
        (fun name t ->
          let t = (apply_substs t subst) in
          Some(t))
        typtbl;
      typtbl)
    tyenv 

let rec typify_expr exp tyenv =
  match exp with
  |Unit -> (TUnit(UnitTy), tyenv)
  |Int(v) -> (TInt(v, IntTy), tyenv)
  |Bool(v) -> (TBool(v, BoolTy), tyenv)
  |Call(name, args) ->
      let f =
        match List.assoc_opt name builtin_optypes with
        |Some(f') -> f'  (* builtin *)
        |None -> begin
          match lookup name tyenv with
          |Some(f') when is_funty f' -> f' (* user defined *)
          |_ -> begin
            print_string (string_of_tyenv tyenv);
            raise (MioError ("Undefined function: " ^ name))
          end
        end 
      in
      (* unifying argument types and return ret_t *)
      let rec typify_call args f tyenv subst =
        match args with
        |arg::xs ->
            let t = arg_type f in
            let arg_t, typenv = typify_expr arg tyenv in
            let subst = subst @ (unify [(t, typeof arg_t)]) in
            let argts, r_t, tyenv = typify_call xs (ret_type f) tyenv subst in
            (arg_t::argts, apply_substs r_t subst, typenv)
        |[] -> ([], f, tyenv)
      in
      let args =
        match args with
        |[] -> [Unit]
        |_ -> args
      in
      let argts, rett, tyenv = typify_call args f tyenv [] in
      (TCall(name, argts, rett), tyenv)
  |If(cond, then_exp, else_exp) ->
      let cond_t, typenv = typify_expr cond tyenv in
      let tyenv = subst_typenv typenv (unify [(BoolTy, typeof cond_t)]) in
      let then_t, tyenv = typify_expr then_exp tyenv in
      let else_t, tyenv = typify_expr else_exp tyenv in
      let tyenv = subst_typenv tyenv (unify [(typeof then_t, typeof else_t)]) in
      let then_t, tyenv = typify_expr then_exp tyenv in
      (TIf(cond_t, then_t, else_t, typeof then_t), tyenv)
  |Var(name) -> begin
    match lookup name tyenv with
    |Some(t) -> (TVar(name, t), tyenv)
    |None -> raise (MioError ("variable is undefined:"^name))
  end
  |Assign(name, t_specifier, exp) -> begin
    let expt, tyenv = typify_expr exp tyenv in
    let tyenv = 
      match (lookup_scope name tyenv, type_of_name_opt t_specifier) with
      |(Some(t), None) -> (* reassign (should have same type) *)
          subst_typenv tyenv (unify [(t, typeof expt)])
      |(Some(t), Some(t')) when t = t' -> (* reassign (same type) *)
          subst_typenv tyenv (unify [(t, typeof expt)])
      |(None, Some(t)) -> (* new assign with type specifier *)
          let typenv = subst_typenv tyenv (unify [(t, typeof expt)]) in
          add_var name t typenv
      |(None, None) -> (* new assign without type specifier *)
          add_var name (typeof expt) tyenv
      |(Some(t), Some(t_specifier)) -> (* reassign (different type) *)
          raise (MioError ("type of variable "^name^" is "^(string_of_type t)))
    in
    (TAssign(name, expt, typeof expt), tyenv)
  end
  |MultiExpr(exprs) -> begin
    let tyenv = (Hashtbl.create 10)::tyenv in
    let rec typify_exprs exprs tyenv =
      match exprs with
      |e::xs -> begin
        let e_t, tyenv = typify_expr e tyenv in
        match xs with
          |[] -> ([e_t], typeof e_t, tyenv)
          |_ ->
            let e_ts, r_t, typenv = typify_exprs xs tyenv in
            (e_t::e_ts, r_t, typenv)
      end
      |[] -> ([], UnitTy, tyenv)
    in
    let exprs_t, r_t, tyenv = typify_exprs exprs tyenv in
    let tyenv = List.tl tyenv in
    (TMultiExpr(exprs_t, r_t), tyenv)
  end
  |Defun(name, args, rett, body) -> begin
    (* function scope *)
    let scopeenv = (Hashtbl.create 10) in
    let recursible = ref true in
    let argnames = List.map (fun (argname, argtype) -> 
      let _ = 
        match argtype with
        |Some(t) ->
            Hashtbl.add scopeenv argname (type_of_name t)
        |None -> begin
            let tyvar = newtypevar argname tyenv in
            Hashtbl.add scopeenv argname tyvar;
            recursible := false
        end
      in
      argname) args
    in
    let rett, recursible =
      match rett with
      |Some(rett) -> (type_of_name rett), !recursible
      |None -> UnitTy, false
    in

    if recursible then begin
        let argtypes = List.map (fun (_, argtype) ->
          match argtype with
          |Some(argtype) -> (type_of_name argtype)
          |None -> raise (MioError "Program Error")) args
        in
        let funt = make_funty argtypes rett in
        Hashtbl.add scopeenv name funt
    end
    else ();

    let tyenv = scopeenv::tyenv in
    (* evaluate *)
    let bodyt, tyenv = typify_expr body tyenv in

    (* get evaluated types *)
    let argtypes = List.map (fun argname ->
      let argtype, _ = typify_expr (Var(argname)) tyenv in
      typeof argtype) argnames
    in

    (* rollback scope *)
    let tyenv = List.tl tyenv in

    (* build function type *)
    let funct = make_funty argtypes (typeof bodyt) in
    Hashtbl.add (List.hd tyenv) name funct; 
    (TDefun(name, argnames, bodyt, funct), tyenv)
  end

let typify exprs =
  let typed_expr, _ = typify_expr exprs [Hashtbl.create 10] in
  typed_expr
