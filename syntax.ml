open Type

type ty_exp = string

type exp = 
  |Unit
  |Int of int
  |Bool of bool

  |Call of string * exp list
  |Assign of string * ty_exp option * exp
  |Var of string
  |If of exp * exp * exp
  |MultiExpr of exp list
  |Defun of string * (string * ty_exp option) list * ty_exp option * exp

type exp_t =
  |TUnit of ty
  |TInt of int * ty
  |TBool of bool * ty

  |TCall of string * exp_t list * ty
  |TAssign of string * exp_t * ty
  |TVar of string * ty
  |TIf of exp_t * exp_t * exp_t * ty
  |TMultiExpr of exp_t list * ty
  |TDefun of string * string list * exp_t * ty


let typeof exp =
  match exp with
  |TUnit(t) -> t
  |TInt (_, t) -> t
  |TBool(_, t) -> t
  |TCall (_, _, t) -> t
  |TAssign (_, _, t) -> t
  |TVar (_, t) -> t
  |TIf (_, _, _, t) -> t
  |TMultiExpr (_, t) -> t
  |TDefun (_, _, _, t) -> t
  
