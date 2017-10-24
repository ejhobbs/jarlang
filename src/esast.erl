-module(esast).
-compile(export_all). 
-compile({no_auto_import, [node/0]}).

module(ModuleName, _Contents) ->
    io_lib:format(
"{
    \"type\": \"Program\",
    \"body\": [
        {
            \"type\": \"VariableDeclaration\",
            \"declarations\": [
                {
                    \"type\": \"VariableDeclarator\",
                    \"id\": {
                        \"type\": \"Identifier\",
                        \"name\": \"~s\"
                    },
                    \"init\": {
                        \"type\": \"CallExpression\",
                        \"callee\": {
                            \"type\": \"FunctionExpression\",
                            \"id\": null,
                            \"params\": [],
                            \"body\": {
                                \"type\": \"BlockStatement\",
                                \"body\": [],
                            },
                            \"generator\": false,
                            \"expression\": false,
                        },
                        \"arguments\": []
                    }
                }
            ],
            \"kind\": \"const\"
        }
    ],
    \"sourceType\": \"module\"
}~n", [ModuleName]).

% Generates a plain node, setting only node type
node(Type) ->
    node(Type, []).

% Generates an Identifier Node
identifier(Name) when is_binary(Name) ->
    node("Identifier", [{"name", Name}]).

% Generates a Literal Node
literal(Value) when is_binary(Value) ; Value =:= null ; is_integer(Value) ; is_float(Value) ; is_boolean(Value) -> % Need to add regex definition
    node("Literal", [{"value", Value}]).

% Generates a RegExp Literal
regexLiteral(Pattern, Flags) ->
    updateRecord(literal(null), [{regex, #{pattern => Pattern, flags => Flags}}]).

% Generates a Program Node
program(Statement) ->
    node("Program", [{"body", Statement}]).

% Generates a Function Node
% Note: This doesn't seem to be used directly, but instead via being modified to become 
% a functionDeclaration node or a functionExpression node
function(Identifier, Params, Body) when is_list(Body) ->
    node("function", [{"id", Identifier}, {"params", Params}, {"body", Body}]);
function(Identifier, Params, Body) ->
    function(Identifier, Params, [Body]).

% Generates a generic Statement Node
statement() ->
    node().

% Generates an empty statement node - i.e. an empty semicolon
emptyStatement() ->
    updateRecord(statement(), [{"type", <<"EmptyStatement">>}]).

% Generates an Expression Statement
expressionStatement(Expression) ->
    updateRecord(statement(), [{"type", <<"ExpressionStatement">>}, {"expression", Expression}]).

% Generates a block statement
blockStatement(Body) when is_list(Body) ->
    updateRecord(statement(), [{"type", <<"BlockStatement">>}, {"body", Body}]);
blockStatement(Body) ->
    blockStatement([Body]).

% Generates an if statement
ifStatement(Test, Consequent, Alternate) ->
    updateRecord(statement(), [{"type", <<"IfStatement">>}, {"test", Test}, {"consequent", Consequent}, {"alternate", Alternate}]).

% Generates a Labeled statement (prefixed with break/continue)
labeledStatement(Identifier, Body) ->
    updateRecord(statement(), [{"type", <<"LabeledStatement">>}, {"label", Identifier}, {"body", Body}]).

% Generates a break statement
breakStatement(Identifier) ->
    updateRecord(statement(), [{"type", <<"BreakStatement">>}, {"label", Identifier}]).

% Generates a continue statement
continueStatement(Identifier) ->
    updateRecord(statement(), [{"type", <<"ContinueStatement">>}, {"label", Identifier}]).

% Generates a with statement
withStatement(Expression, Statement) ->
    updateRecord(statement(), [{"type", <<"WithStatement">>}, {"object", Expression}, {"body", Statement}]).

% Generates a switch statement
switchStatement(Expression, Cases, HasLexScope) when is_list(Cases) ->
    updateRecord(statement(), [{"type", <<"SwitchStatement">>}, {"discriminant", Expression}, {"cases", Cases}, {"lexical", HasLexScope}]);
switchStatement(Expression, Cases, HasLexScope) ->
    switchStatement(Expression, [Cases], HasLexScope).

switchCase(Test, Consequent) when is_list(Consequent) ->
   updateRecord(statement(), [{"type", <<"SwitchCase">>}, {"test", Test}, {"consequent", Consequent}]);
switchCase(Test, Consequent) ->
    switchCase(Test, [Consequent]).

% Generates a return statement
returnStatement(Expression) ->
    updateRecord(statement(), [{"type", <<"ReturnStatement">>}, {"argument", Expression}]).

% Generates a throw statement
throwStatement(Expression) ->
    updateRecord(statement(), [{"type", <<"ThrowStatement">>}, {"argument", Expression}]).

% Generates a try statement
tryStatement(BlockStatement, Handler, GuardedHandler, Finalizer) ->
    updateRecord(statement(), [{"type", <<"TryStatement">>}, {"block", BlockStatement}, {"handler", Handler}, {"guardedHandler", GuardedHandler}, {"finalizer", Finalizer}]).

catchClause(Param, Guard, Body) ->
    updateRecord(statement(), [{"type", <<"CatchClause">>}, {"param", Param}, {"guard", Guard}, {"body", Body}]).

% Generates a while statement
whileStatement(Expression, Body) when is_list(Body) ->
    updateRecord(statement(), [{"type", <<"WhileStatement">>}, {"test", Expression}, {"body", Body}]);
whileStatement(Expression, Body) ->
    whileStatement(Expression, [Body]).

% Generates a for statement
forStatement(Init, Update, Expression, Body) ->
    updateRecord(whileStatement(Expression, Body), [{"type", <<"ForStatement">>}, {"init", Init}, {"update", Update}]).

% Generates a forIn statement
forInStatement(Left, Right, Body, Each) when is_list(Body) ->
    updateRecord(statement(), [{"type", <<"ForInStatement">>}, {"left", Left}, {"right", Right}, {"each", Each}, {"body", Body}]);
forInStatement(Left, Right, Body, Each) ->
    forInStatement(Left, Right, [Body], Each).

% Generates a forOf statement
forOfStatement(Left, Right, Body) when is_list(Body) ->
    updateRecord(statement(), [{"type", <<"ForOfStatement">>}, {"left", Left}, {"right", Right}, {"body", Body}]);
forOfStatement(Left, Right, Body) ->
    forOfStatement(Left, Right, [Body]).

% Generates a declaration
declaration() ->
    node().

% Generates a variable declaration
variableDeclaration(Declarations, Kind) when is_list(Declarations)  ->
    updateRecord(declaration(), [{"type", <<"VariableDeclaration">>}, {"declarations", Declarations}, {"kind", Kind}]);
variableDeclaration(Declarations, Kind) ->
    variableDeclaration([Declarations], Kind).

% Generates a variable declarator
variableDeclarator(Identifier, Init) ->
    node("VariableDeclarator", [{"id", Identifier}, {"init", Init}]).

% Generate a function declaration
functionDeclaration(Identifier, Params, Body) when is_list(Params) ->
    updateRecord(declaration(), [{"type", <<"FunctionDeclaration">>}, {"id", Identifier}, {"params", Params}, {"body", Body}]);
functionDeclaration(Identifier, Params, Body) ->
    functionDeclaration(Identifier, [Params], Body).

% Generate an Expression
expression() ->
    node().

% Generate a This expression
thisExpression() ->
    updateRecord(expression(), [{"type", <<"ThisExpression">>}]).

% Generate an Array expression
arrayExpression(Elements) when is_list(Elements) ->
    updateRecord(expression(), [{"type", <<"ArrayExpression">>}, {"elements", Elements}]);
arrayExpression(Elements) ->
    arrayExpression([Elements]).

% Generate an Object expression
objectExpression(Properties) when is_list(Properties) ->
    updateRecord(expression(), [{"type", <<"ObjectExpression">>}, {"properties", Properties}]);
objectExpression(Properties) ->
    objectExpression([Properties]).

% A Literal Property for Object expressions
property(Key, Value) ->
    node("Property", [{"key", Key}, {"value", Value}, {"kind", <<"init">>}]).

% Generate a sequence expression
sequenceExpression(Expressions) when length(Expressions) > 1, is_list(Expressions) ->
    updateRecord(expression(), [{"type", <<"SequenceExpression">>}, {"expressions", Expressions}]).

% Generate a unary operation expression
unaryExpression(Operator, Prefix, Argument) ->
    updateRecord(expression(), [{"type", <<"UnaryExpression">>}, {"operator", Operator}, {"prefix", Prefix}, {"argument", Argument}]).

% Generate a binary operation expression
binaryExpression(Operator, Left, Right) ->
    updateRecord(expression(), [{"type", <<"UpdateExpression">>}, {"operator", Operator}, {"left", Left}, {"right", Right}]).

% Generate an update (increment or decrement) operator expression
updateExpression(Operator, Argument, Prefix) ->
    updateRecord(expression(), [{"type", <<"UpdateExpression">>}, {"operator", Operator}, {"argument", Argument}, {"prefix", Prefix}]).

% Generate a logical operator expression
logicalExpression(Operator, Left, Right) ->
    updateRecord(expression(), [{"type", <<"LogicalExpression">>}, {"operator", Operator}, {"left", Left}, {"right", Right}]).

% Generate a conditional expression
conditionalExpression(Test, Alternate, Consequent) ->
    updateRecord(expression(), [{"type", <<"ConditionalExpression">>}, {"test", Test}, {"alternate", Alternate}, {"consequent", Consequent}]).

% Generate a new expression
newExpression(Callee, Arguments) ->
    updateRecord(expression(), [{"type", <<"NewExpression">>}, {"callee", Callee}, {"arguments", Arguments}]).

% Generate a call expression
callExpression(Callee, Arguments) ->
    updateRecord(expression(), [{"type", <<"CallExpression">>}, {"callee", Callee}, {"arguments", Arguments}]).

% Generate a member expression
memberExpression(Object, Property, Computed) ->
    updateRecord(expression(), [{"type", <<"MemberExpression">>}, {"object", Object}, {"property", Property}, {"computed", Computed}]).

% ------ Intenal ------ %

% Generates a plain node and sets additional fields in the form
% List[{Key, Value}]
node() ->
    #{}.

node(Type, AdditionalFields) ->
    NewNode = #{type => list_to_binary(Type)},
    updateRecord(NewNode, AdditionalFields).


% Helper function which appends new key value pairs into an existing record
updateRecord(Record, [{Key, Value}]) ->
    Record#{Key => Value};
updateRecord(Record, [{Key, Value} | Tail]) ->
    updateRecord(Record#{Key => Value}, Tail).


% Misc Functions
print(Json) ->
    code:add_path("../lib/"),
    io:format(json:serialize(Json)).
