%{
  #include "y.tab.h"
%}

%%
[ \t\n]               ;//Ignore whitespaces and tabs
[0-9]+                {return NUM;}
[0-9]+\.+[0-9]+       {return DOUBLE;}
";"                   {return SEMICOLON;}
"proc"                {return PROC;}
"func"                {return FUNC;}
"return"              {return RETURN;}
"null"                {return NUL;}
"if"                  {return IF;}
"else"                {return ELSE;}
"while"               {return WHILE;}
"for"                 {return FOR;}
"var"                 {return VAR;}
"int"                 {return INT;}
"char"                {return CHAR;}
"real"                {return REAL;}
"int*"                {return INTP;}
"char*"               {return CHARP;}
"real*"               {return REALP;}
"bool"                {return BOOL;}
"string"              {return STRING;}
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
"^"                   {return POWER;}
"!"                   {return NOT;}
"!="                  {return DIFF;}
\'                    {return ONEPAREN;}
\"                    {return DOUBLEPAREN;}
"true"                {return TRUE;}
"false"               {return FALSE;}
[a-zA-Z][_a-zA-Z0-0]* {return IDENTIFIER;}
%%