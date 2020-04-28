{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module Harper.Printer where

-- pretty-printer generated by the BNF converter

import Harper.Abs
import Data.Char

-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else ' ':s)

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)


instance Print Ident where
  prt _ (Ident i) = doc (showString ( i))


instance Print UIdent where
  prt _ (UIdent i) = doc (showString ( i))



instance Print (Program a) where
  prt i e = case e of
    Prog _ toplvldecls -> prPrec i 0 (concatD [prt 0 toplvldecls])

instance Print (TopLvlDecl a) where
  prt i e = case e of
    TopLvlFDecl _ fundecl -> prPrec i 0 (concatD [prt 0 fundecl])
    TopLvlTHint _ typehint -> prPrec i 0 (concatD [prt 0 typehint])
    TopLvlTDecl _ typedecl -> prPrec i 0 (concatD [prt 0 typedecl])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print (TypeHint a) where
  prt i e = case e of
    THint _ id typeexpr -> prPrec i 0 (concatD [prt 0 id, doc (showString "::"), prt 0 typeexpr])

instance Print (TypeExpr a) where
  prt i e = case e of
    TVar _ id -> prPrec i 2 (concatD [prt 0 id])
    TCtor _ uident -> prPrec i 2 (concatD [prt 0 uident])
    TPur _ typepurity -> prPrec i 2 (concatD [prt 0 typepurity])
    TUnit _ -> prPrec i 2 (concatD [doc (showString "()")])
    TTup _ tupletype -> prPrec i 2 (concatD [doc (showString "("), prt 0 tupletype, doc (showString ")")])
    TAdHoc _ fieldtypeexprs -> prPrec i 2 (concatD [doc (showString "{"), prt 0 fieldtypeexprs, doc (showString "}")])
    TApp _ uident typeexprs -> prPrec i 1 (concatD [prt 0 uident, prt 2 typeexprs])
    TFun _ typeexpr1 typeexpr2 -> prPrec i 0 (concatD [prt 1 typeexpr1, doc (showString "->"), prt 0 typeexpr2])
  prtList 2 [x] = (concatD [prt 2 x])
  prtList 2 (x:xs) = (concatD [prt 2 x, prt 2 xs])
instance Print (TupleType a) where
  prt i e = case e of
    TTupList _ typeexpr tupletype -> prPrec i 0 (concatD [prt 0 typeexpr, doc (showString ","), prt 0 tupletype])
    TTupTail _ typeexpr1 typeexpr2 -> prPrec i 0 (concatD [prt 0 typeexpr1, doc (showString ","), prt 0 typeexpr2])

instance Print (TypePurity a) where
  prt i e = case e of
    TImpure _ -> prPrec i 0 (concatD [doc (showString "impure")])
    TSideE _ -> prPrec i 0 (concatD [doc (showString "sideeffect")])

instance Print (FieldTypeExpr a) where
  prt i e = case e of
    TFld _ typehint -> prPrec i 0 (concatD [prt 0 typehint])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print (FunDecl a) where
  prt i e = case e of
    FDecl _ id funparams funbody -> prPrec i 0 (concatD [prt 0 id, prt 0 funparams, doc (showString "="), prt 0 funbody])

instance Print (FunParam a) where
  prt i e = case e of
    FParam _ id -> prPrec i 0 (concatD [prt 0 id])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (LambdaParam a) where
  prt i e = case e of
    LamParam _ pattern -> prPrec i 0 (concatD [prt 0 pattern])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (FunBody a) where
  prt i e = case e of
    FExprBody _ expression -> prPrec i 0 (concatD [prt 0 expression])
    FStmtBody _ statement -> prPrec i 0 (concatD [prt 5 statement])

instance Print (BoolLiteral a) where
  prt i e = case e of
    BTrue _ -> prPrec i 0 (concatD [doc (showString "true")])
    BFalse _ -> prPrec i 0 (concatD [doc (showString "false")])

instance Print (Literal a) where
  prt i e = case e of
    UnitLit _ -> prPrec i 0 (concatD [doc (showString "()")])
    IntLit _ n -> prPrec i 0 (concatD [prt 0 n])
    CharLit _ c -> prPrec i 0 (concatD [prt 0 c])
    StrLit _ str -> prPrec i 0 (concatD [prt 0 str])
    BoolLit _ boolliteral -> prPrec i 0 (concatD [prt 0 boolliteral])

instance Print (Qualifier a) where
  prt i e = case e of
    Qual _ id -> prPrec i 1 (concatD [prt 0 id, doc (showString ".")])
    Quals _ qualifier1 qualifier2 -> prPrec i 0 (concatD [prt 0 qualifier1, prt 1 qualifier2])
    ThisQual _ -> prPrec i 0 (concatD [doc (showString "this"), doc (showString ".")])
    DataQual _ -> prPrec i 0 (concatD [doc (showString "this"), doc (showString "."), doc (showString "data"), doc (showString ".")])

instance Print (Expression a) where
  prt i e = case e of
    ThisExpr _ -> prPrec i 12 (concatD [doc (showString "this")])
    AdHocExpr _ adhocfielddecls -> prPrec i 11 (concatD [doc (showString "val"), doc (showString "{"), prt 0 adhocfielddecls, doc (showString "}")])
    VCtorExpr _ uident fieldasss -> prPrec i 11 (concatD [doc (showString "val"), prt 0 uident, doc (showString "{"), prt 0 fieldasss, doc (showString "}")])
    TupExpr _ tupleexpression -> prPrec i 11 (concatD [doc (showString "("), prt 0 tupleexpression, doc (showString ")")])
    LitExpr _ literal -> prPrec i 11 (concatD [prt 0 literal])
    ObjExpr _ id -> prPrec i 11 (concatD [prt 0 id])
    CtorExpr _ uident -> prPrec i 11 (concatD [prt 0 uident])
    QObjExpr _ qualifier id -> prPrec i 11 (concatD [prt 0 qualifier, prt 0 id])
    MatchExpr _ expression matchexpressionclauses -> prPrec i 10 (concatD [doc (showString "match"), prt 11 expression, doc (showString "{"), prt 0 matchexpressionclauses, doc (showString "}")])
    AppExpr _ expression1 expression2 -> prPrec i 9 (concatD [prt 9 expression1, prt 11 expression2])
    CompExpr _ expression1 expression2 -> prPrec i 8 (concatD [prt 8 expression1, doc (showString "@"), prt 9 expression2])
    PowExpr _ expression1 expression2 -> prPrec i 7 (concatD [prt 7 expression1, doc (showString "^"), prt 8 expression2])
    MulExpr _ expression1 expression2 -> prPrec i 6 (concatD [prt 6 expression1, doc (showString "*"), prt 7 expression2])
    DivExpr _ expression1 expression2 -> prPrec i 6 (concatD [prt 6 expression1, doc (showString "/"), prt 7 expression2])
    ModExpr _ expression1 expression2 -> prPrec i 6 (concatD [prt 6 expression1, doc (showString "mod"), prt 7 expression2])
    AddExpr _ expression1 expression2 -> prPrec i 5 (concatD [prt 5 expression1, doc (showString "+"), prt 6 expression2])
    SubExpr _ expression1 expression2 -> prPrec i 5 (concatD [prt 5 expression1, doc (showString "-"), prt 6 expression2])
    NotExpr _ expression -> prPrec i 4 (concatD [doc (showString "not"), prt 9 expression])
    NegExpr _ expression -> prPrec i 4 (concatD [doc (showString "-"), prt 9 expression])
    EqExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString "=="), prt 4 expression2])
    NEqExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString "!="), prt 4 expression2])
    LtExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString "<"), prt 4 expression2])
    GtExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString ">"), prt 4 expression2])
    LEqExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString "<="), prt 4 expression2])
    GEqExpr _ expression1 expression2 -> prPrec i 3 (concatD [prt 3 expression1, doc (showString ">="), prt 4 expression2])
    AndExpr _ expression1 expression2 -> prPrec i 2 (concatD [prt 2 expression1, doc (showString "and"), prt 3 expression2])
    OrExpr _ expression1 expression2 -> prPrec i 2 (concatD [prt 2 expression1, doc (showString "or"), prt 3 expression2])
    SeqExpr _ expression1 expression2 -> prPrec i 1 (concatD [prt 2 expression1, doc (showString "|"), prt 1 expression2])
    LamExpr _ lambdaparams funbody -> prPrec i 0 (concatD [doc (showString "\\"), prt 0 lambdaparams, doc (showString "=>"), prt 0 funbody])

instance Print (TupleExpression a) where
  prt i e = case e of
    TupExprList _ expression tupleexpression -> prPrec i 0 (concatD [prt 11 expression, doc (showString ","), prt 0 tupleexpression])
    TupExprTail _ expression1 expression2 -> prPrec i 0 (concatD [prt 11 expression1, doc (showString ","), prt 11 expression2])

instance Print (MatchExpressionClause a) where
  prt i e = case e of
    MatchExprClause _ pattern expression -> prPrec i 0 (concatD [prt 0 pattern, doc (showString "=>"), prt 0 expression])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print (FieldAss a) where
  prt i e = case e of
    DataAss _ id expression -> prPrec i 0 (concatD [prt 0 id, doc (showString "="), prt 0 expression])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print (Statement a) where
  prt i e = case e of
    EmptyStmt _ -> prPrec i 5 (concatD [doc (showString "{"), doc (showString "}")])
    StmtBlock _ statements -> prPrec i 5 (concatD [doc (showString "{"), prt 0 statements, doc (showString "}")])
    StmtBlockWDecls _ statements localfundecls -> prPrec i 5 (concatD [doc (showString "{"), prt 0 statements, doc (showString "where"), prt 0 localfundecls, doc (showString "}")])
    RetStmt _ -> prPrec i 4 (concatD [doc (showString "return"), doc (showString ";")])
    RetExprStmt _ expression -> prPrec i 4 (concatD [doc (showString "return"), prt 0 expression, doc (showString ";")])
    CntStmt _ -> prPrec i 4 (concatD [doc (showString "continue"), doc (showString ";")])
    BrkStmt _ -> prPrec i 4 (concatD [doc (showString "break"), doc (showString ";")])
    YieldStmt _ expression -> prPrec i 4 (concatD [doc (showString "yield"), prt 0 expression, doc (showString ";")])
    MatchStmt _ expression matchstatementclauses -> prPrec i 3 (concatD [doc (showString "match"), prt 0 expression, doc (showString "{"), prt 0 matchstatementclauses, doc (showString "}")])
    WhileStmt _ expression statement -> prPrec i 3 (concatD [doc (showString "while"), prt 0 expression, prt 5 statement])
    ForInStmt _ pattern expression statement -> prPrec i 3 (concatD [doc (showString "for"), prt 0 pattern, doc (showString "in"), prt 0 expression, prt 5 statement])
    CondStmt _ conditionalstatement -> prPrec i 3 (concatD [prt 0 conditionalstatement])
    DconStmt _ pattern expression -> prPrec i 2 (concatD [prt 0 pattern, doc (showString "="), prt 0 expression, doc (showString ";")])
    DeclStmt _ localobjdecl -> prPrec i 2 (concatD [prt 1 localobjdecl, doc (showString ";")])
    AssStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString ":="), prt 0 expression, doc (showString ";")])
    AddStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "+="), prt 0 expression, doc (showString ";")])
    SubStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "-="), prt 0 expression, doc (showString ";")])
    MulStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "*="), prt 0 expression, doc (showString ";")])
    DivStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "/="), prt 0 expression, doc (showString ";")])
    PowStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "^="), prt 0 expression, doc (showString ";")])
    CompStmt _ id expression -> prPrec i 1 (concatD [prt 0 id, doc (showString "@="), prt 0 expression, doc (showString ";")])
    QAssStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString ":="), prt 0 expression, doc (showString ";")])
    QAddStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "+="), prt 0 expression, doc (showString ";")])
    QSubStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "-="), prt 0 expression, doc (showString ";")])
    QMulStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "*="), prt 0 expression, doc (showString ";")])
    QDivStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "/="), prt 0 expression, doc (showString ";")])
    QPowStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "^="), prt 0 expression, doc (showString ";")])
    QCompStmt _ qualifier id expression -> prPrec i 1 (concatD [prt 0 qualifier, prt 0 id, doc (showString "@="), prt 0 expression, doc (showString ";")])
    EvalStmt _ expression -> prPrec i 0 (concatD [doc (showString "eval"), prt 9 expression, doc (showString ";")])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (MatchStatementClause a) where
  prt i e = case e of
    MatchStmtClause _ pattern statement -> prPrec i 0 (concatD [prt 0 pattern, doc (showString "=>"), prt 4 statement])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (ConditionalStatement a) where
  prt i e = case e of
    IfElifStmts _ ifstatement elseifstatements -> prPrec i 0 (concatD [prt 0 ifstatement, prt 0 elseifstatements])
    IfElifElseStmts _ ifstatement elseifstatements elsestatement -> prPrec i 0 (concatD [prt 0 ifstatement, prt 0 elseifstatements, prt 0 elsestatement])

instance Print (IfStatement a) where
  prt i e = case e of
    IfStmt _ expression statement -> prPrec i 0 (concatD [doc (showString "if"), prt 0 expression, prt 5 statement])

instance Print (ElseIfStatement a) where
  prt i e = case e of
    ElifStmt _ expression statement -> prPrec i 0 (concatD [doc (showString "else"), doc (showString "if"), prt 0 expression, prt 5 statement])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (ElseStatement a) where
  prt i e = case e of
    ElseStmt _ statement -> prPrec i 0 (concatD [doc (showString "else"), prt 5 statement])

instance Print (Pattern a) where
  prt i e = case e of
    PatLit _ literal -> prPrec i 2 (concatD [prt 0 literal])
    PatDecl _ localobjdecl -> prPrec i 1 (concatD [prt 0 localobjdecl])
    PatData _ fieldpatterns -> prPrec i 1 (concatD [doc (showString "val"), doc (showString "{"), prt 0 fieldpatterns, doc (showString "}")])
    PatTup _ tuplepattern -> prPrec i 1 (concatD [doc (showString "("), prt 0 tuplepattern, doc (showString ")")])
    PatDisc _ -> prPrec i 1 (concatD [doc (showString "_")])
    PatCtor _ uident fieldpatterns -> prPrec i 0 (concatD [prt 0 uident, doc (showString "{"), prt 0 fieldpatterns, doc (showString "}")])

instance Print (TuplePattern a) where
  prt i e = case e of
    PatTupList _ pattern tuplepattern -> prPrec i 0 (concatD [prt 0 pattern, doc (showString ","), prt 0 tuplepattern])
    PatTupTail _ pattern1 pattern2 -> prPrec i 0 (concatD [prt 0 pattern1, doc (showString ","), prt 0 pattern2])

instance Print (FieldPattern a) where
  prt i e = case e of
    PatFld _ id pattern -> prPrec i 0 (concatD [prt 0 id, doc (showString ":"), prt 0 pattern])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print (Declaration a) where
  prt i e = case e of
    Decl _ id -> prPrec i 0 (concatD [prt 0 id])
    DeclWHint _ typehint -> prPrec i 0 (concatD [doc (showString "("), prt 0 typehint, doc (showString ")")])

instance Print (AdHocFieldDecl a) where
  prt i e = case e of
    AdHocFld _ declaration expression -> prPrec i 0 (concatD [prt 0 declaration, doc (showString "="), prt 0 expression])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print (LocalFunDecl a) where
  prt i e = case e of
    LocTHint _ typehint -> prPrec i 0 (concatD [prt 0 typehint])
    LocFDecl _ fundecl -> prPrec i 0 (concatD [prt 0 fundecl])
  prtList _ [x] = (concatD [prt 0 x, doc (showString ";")])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print (LocalObjDecl a) where
  prt i e = case e of
    LocVarDecl _ declaration -> prPrec i 1 (concatD [doc (showString "var"), prt 0 declaration])
    LocValDecl _ declaration -> prPrec i 0 (concatD [prt 0 declaration])

instance Print (TypeSignature a) where
  prt i e = case e of
    TSig _ uident typeparameters -> prPrec i 0 (concatD [prt 0 uident, prt 0 typeparameters])

instance Print (TypeDecl a) where
  prt i e = case e of
    ValTDecl _ typesignature typebody -> prPrec i 0 (concatD [doc (showString "value"), prt 0 typesignature, doc (showString "="), doc (showString "{"), prt 0 typebody, doc (showString "}")])
    ValTUDecl _ typesignature typevariantdecls -> prPrec i 0 (concatD [doc (showString "value"), prt 0 typesignature, doc (showString "="), doc (showString "{"), prt 0 typevariantdecls, doc (showString "}")])
    RefTDecl _ typesignature typebody -> prPrec i 0 (concatD [doc (showString "ref"), prt 0 typesignature, doc (showString "="), doc (showString "{"), prt 0 typebody, doc (showString "}")])

instance Print (TypeParameter a) where
  prt i e = case e of
    TParam _ id -> prPrec i 0 (concatD [prt 0 id])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print (TypeVariantDecl a) where
  prt i e = case e of
    TVarDecl _ uident typebody -> prPrec i 0 (concatD [doc (showString "variant"), prt 0 uident, doc (showString "="), doc (showString "{"), prt 0 typebody, doc (showString "}")])
  prtList _ [x] = (concatD [prt 0 x, doc (showString ";")])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print (TypeBody a) where
  prt i e = case e of
    DataTBody _ fielddecls memberdecls -> prPrec i 0 (concatD [doc (showString "data"), doc (showString "="), doc (showString "{"), prt 0 fielddecls, doc (showString "}"), prt 0 memberdecls])
    TBody _ memberdecls -> prPrec i 0 (concatD [prt 0 memberdecls])

instance Print (FieldDecl a) where
  prt i e = case e of
    TFldDecl _ typehint -> prPrec i 0 (concatD [prt 0 typehint])
  prtList _ [x] = (concatD [prt 0 x, doc (showString ";")])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print (MemberDecl a) where
  prt i e = case e of
    TMemTHint _ typehint -> prPrec i 0 (concatD [prt 0 typehint])
    TMemFDecl _ fundecl -> prPrec i 0 (concatD [prt 0 fundecl])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
