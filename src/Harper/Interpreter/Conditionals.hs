module Harper.Interpreter.Conditionals
    ( linearizeCond
    )
where

import           Harper.Abs
import           Harper.Expressions
import           Harper.Interpreter.Core

-- Turns a conditional statement into a linear conditional statement.
-- Linear means a list of if statements where we assume that the first if with a true predicate
-- will be the only one to execute.
linearizeCond :: ConditionalStatement Meta -> [IfStatement Meta]
linearizeCond (IfElifStmts _ _if elifs) = _if : map elifToIf elifs
linearizeCond (IfElifElseStmts _ _if elifs _else) =
    _if : map elifToIf elifs ++ [elseToIf _else]

elifToIf :: ElseIfStatement Meta -> IfStatement Meta
elifToIf (ElifStmt a v s) = IfStmt a v s

elseToIf :: ElseStatement Meta -> IfStatement Meta
elseToIf (ElseStmt a s) = IfStmt a litTrue s
