  // Itay Fridman 305360653
  // Idan Aharon  305437774
  // Noam Bahar   203155650
%{
  #include "y.tab.h"
%}

%x C_COMMENT
%%

"/%"            { BEGIN(C_COMMENT); }
<C_COMMENT>"%/" { BEGIN(INITIAL); }
<C_COMMENT>.    { }
<C_COMMENT>\n { }
[ \t\n]               ;//Ignore whitespaces and tabs
(0|([1-9]+[0-9]*))|(0[xX][0-9A-F]+) {yylval.value = strdup(yytext);return NUM;}
-(0|([1-9]+[0-9]*))   {yylval.value = strdup(yytext);return NEGNUM;}
[0-9]+\.+[0-9]+       {yylval.value = strdup(yytext);return DOUBLE;}
";"                   {return SEMICOLON;}
"proc"                {return PROC;}
"func"                {return FUNC;}
"return"              {return RETURN;}
"null"                {yylval.value = strdup(yytext); return NUL;}
"if"                  {return IF;}
"else"                {return ELSE;}
"while"               {return WHILE;}
"for"                 {return FOR;}
"var"                 {return VAR;}
"Main"                {return MAIN;}
"int"                 {yylval.value = strdup(yytext);return INT;}
"char"                {yylval.value = strdup(yytext);return CHAR;}
"real"                {yylval.value = strdup(yytext);return REAL;}
"int*"                {yylval.value = strdup(yytext);return INTP;}
"char*"               {yylval.value = strdup(yytext);return CHARP;}
"real*"               {yylval.value = strdup(yytext);return REALP;}
"bool"                {yylval.value = strdup(yytext);return BOOL;}
"string"              {yylval.value = strdup(yytext);return STRING;}
"("                   {return LB;}
")"                   {return RB;}
"{"                   {return LCB;}
"}"                   {return RCB;}
"["                   {return LSB;}
"]"                   {return RSB;}
":"                   {return COLON;}
","                   {return COMMA;}
">"                   {return GREATER;}
">="                  {return GREATEREQUAL;}
"<"                   {return LESS;}
"<="                  {return LESSEQUAL;}
"=="                  {return EQUAL;}
"&&"                  {return AND;}
"/"                   {return DIVIDE;}
"="                   {return ASSIGNMENT;}
"|"                   {return LENGTH;}
"+"                   {return PLUS;}
"-"                   {return MINUS;}
"*"                   {return MULT;}
"||"                  {return OR;}
"&"                   {return REF;}
"^"                   {return DEREF;}
"!"                   {return NOT;}
"!="                  {return DIFF;}
\'                    {return ONEPAREN;}
\"                    {return DOUBLEPAREN;}
"true"                {yylval.value = strdup(yytext); return TRUE;}
"false"               {yylval.value = strdup(yytext); return FALSE;}
\'.\'                 {yylval.value = strdup(yytext); return CHARACTER;}
\"[^"]*\"             {yylval.value = strdup(yytext); return STR;}
[a-zA-Z][_a-zA-Z0-9]* {yylval.value = strdup(yytext); return IDENTIFIER;}

%%