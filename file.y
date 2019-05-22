// Itay Fridman 305360653
// Idan Aharon  305437774
// Noam Bahar   203155650

// TODO:
// add E in left double
// Check if array[exp] need to be expression or identifier
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
#include "definitions.h"
#include "lex.yy.c"

#include "Semantics.c"
#include "tree.c"
#include "SymTable.c"

%}
%union {
    char *value;
    Node *nPtr;
}
%start program

%token NUM DOUBLE SEMICOLON PROC FUNC RETURN NUL IF ELSE WHILE FOR VAR INT
%token CHAR REAL INTP CHARP REALP BOOL STRING LB RB LCB RCB LSB RSB COLON
%token COMMA GREATER GREATEREQUAL LESS LESSEQUAL EQUAL AND DIVIDE ASSIGNMENT
%token LENGTH PLUS MINUS MULT OR REF DEREF NOT DIFF TRUE FALSE IDENTIFIER
%token CHARACTER STR MAIN

%left GREATER GREATEREQUAL LESS LESSEQUAL EQUAL DIFF
%left PLUS MINUS
%left MULT DIVIDE
%left OR
%left AND
%left LB RB
%left NOT REF DEREF
%left ELSE
%left COMMA

%type<nPtr> code proc func arguments body funcbody assign exp statements statement if loop declare retType identifier argumentList parameters main retStatement funcCall funcArgs args retval
%type<value> type bool NUM IDENTIFIER STRING
%%

program:
    process
    {
        reverseChilds(pTree);
        makeParents(pTree, 1);
        initScopes(pTree);
        checkSemantics(pTree, 1);
        errorSummary();
        if(numOfErrors == 0)
            print(pTree);
    }
    ;

process:
    code process{ addChild(pTree, $1); }
    | code      { addChild(pTree, $1); }
    | main      { addChild(pTree, $1); }
    ;

code:
    proc    { $$ = $1; }
    | func  { $$ = $1; }
    ;

proc:
    PROC identifier LB parameters RB body
        {$$ = createNode("PROC", $2, $4, $6, NULL);}
    | PROC identifier LB RB body
        {$$ = createNode("PROC", $2, createNode("ARGS NONE", NULL), $5, NULL);}
    ;

func:
    FUNC identifier LB parameters RB RETURN retType funcbody
        {$$ = createNode("FUNC", $2, $4, $7, $8, NULL);}
    | FUNC identifier LB RB RETURN retType funcbody
        {$$ = createNode("FUNC", $2, createNode("ARGS NONE", NULL), $6, $7, NULL);}
    ;

retType:
    type { $$ = createNode("RET", createNode($1, NULL), NULL); }
    ;

parameters:
    arguments { $$ = createNode("ARGS", $1, NULL); }
    ;

arguments:
    argumentList                        { $$ = createNode("", $1, NULL); }
    | argumentList SEMICOLON arguments  { $$ = createNode("", $1, $3, NULL); }
    ;

argumentList:
    args COLON type {$$ = createNode($3, $1, NULL);}
    ;

args:
    args COMMA identifier   { $$ = createNode("", $1, $3, NULL); }
    | identifier            { $$ = $1; }
    ;

type:
    INT     { $$ = yylval.value; }
    | CHAR  { $$ = yylval.value; }
    | REAL  { $$ = yylval.value; }
    | INTP  { $$ = yylval.value; }
    | CHARP { $$ = yylval.value; }
    | REALP { $$ = yylval.value; }
    | BOOL  { $$ = yylval.value; }
    | STRING LSB NUM RSB
    {
        char *s = (char *)malloc(sizeof(char));
        strcat(s, $1);
        strcat(s, "[");
        strcat(s, $3);
        strcat(s, "]");
        $$ = s;
    }
    ;

body:
    LCB statements RCB  { $$ = createNode("BLOCK", $2, NULL); }
    | LCB RCB           { $$ = createNode("BLOCK", NULL); }
    ;

main:
    PROC MAIN LB RB body { $$ = createNode("MAIN", $5, NULL); }
    ;

funcbody:
        LCB statements RETURN exp SEMICOLON RCB
            {$$ = createNode("BODY", $2, createNode("RETURN", $4, NULL), NULL);}
        | LCB RETURN exp SEMICOLON RCB
            {$$ = createNode("BODY", createNode("RETURN", $3, NULL), NULL);}
        ;

retval:
    NUM                         { $$ = createNode(yylval.value, NULL); }
    | DOUBLE                    { $$ = createNode(yylval.value, NULL); }
    | CHARACTER                 { $$ = createNode(yylval.value, NULL); }
    | STR                       { $$ = createNode(yylval.value, NULL); }
    | identifier                { $$ = $1; }
    | bool                      { $$ = createNode($1, NULL); }
    | NUL                       { $$ = createNode(yylval.value, NULL); }
    | LENGTH identifier LENGTH  {$$ = createNode("LEN", $2, NULL);}
    ;

bool:
    TRUE    { $$ = yylval.value; }
    | FALSE { $$ = yylval.value; }
    ;

statements:
        statements statement    { $$ = createNode("", $1, $2, NULL); }
        | statement             { $$ = $1; }
        ;

statement:
        if                      { $$ = $1; }
        | assign SEMICOLON      { $$ = $1; }
        | loop                  { $$ = $1; }
        | body                  { $$ = $1; }
        | func                  { $$ = $1; }
        | proc                  { $$ = $1; }
        | declare               { $$ = $1; }
        | retStatement          { $$ = $1; }
        | funcCall SEMICOLON    { $$ = $1; }
        ;

funcCall:
    IDENTIFIER LB funcArgs RB
        {$$ = createNode("CALL", createNode($1, createNode("", $3, NULL), NULL), NULL);}
    | IDENTIFIER LB RB {$$ = createNode("CALL", createNode($1, NULL), NULL);}
    ;

funcArgs:
    funcArgs COMMA exp  { $$ = createNode("", $1, $3, NULL); }
    | exp               { $$ = $1; }
    ;

retStatement:
    RETURN exp SEMICOLON {$$ = createNode("RETURN", $2, NULL);}
    ;

if:
    IF LB exp RB statement                  {$$ = createNode("IF", $3, $5, NULL);}
    | IF LB exp RB statement ELSE statement {$$ = createNode("IF-ELSE", $3, $5, $7, NULL);}
  ;

loop:
    WHILE LB exp RB statement
        {$$ = createNode("WHILE", $3, $5, NULL);}
    | FOR LB assign SEMICOLON exp SEMICOLON assign RB statement
        {$$ = createNode("FOR", $3, $5, $7, $9, NULL);}
    ;

declare:
    VAR argumentList SEMICOLON { $$ = createNode("VAR", $2, NULL); }
    ;

assign:
    identifier ASSIGNMENT exp {$$ = createNode("=", $1, $3, NULL);}
    ;

exp:
    exp PLUS exp            { $$ = createNode("+", $1, $3, NULL); }
    | exp MINUS exp         { $$ = createNode("-", $1, $3, NULL); }
    | exp MULT exp          { $$ = createNode("*", $1, $3, NULL); }
    | exp DIVIDE exp        { $$ = createNode("/", $1, $3, NULL); }
    | exp AND exp           { $$ = createNode("&&", $1, $3, NULL); }
    | exp EQUAL exp         { $$ = createNode("==", $1, $3, NULL); }
    | exp GREATER exp       { $$ = createNode(">", $1, $3, NULL); }
    | exp GREATEREQUAL exp  { $$ = createNode(">=", $1, $3, NULL); }
    | exp LESS exp          { $$ = createNode("<", $1, $3, NULL); }
    | exp LESSEQUAL exp     { $$ = createNode("<=", $1, $3, NULL); }
    | exp DIFF exp          { $$ = createNode("!=", $1, $3, NULL); }
    | exp OR exp            { $$ = createNode("||", $1, $3, NULL); }
    | NOT exp               { $$ = createNode("!", $2, NULL); }
    | REF exp               { $$ = createNode("&", $2, NULL); }
    | DEREF exp             { $$ = createNode("^", $2, NULL); }
    | LB exp RB             { $$ = $2; }
    | funcCall              { $$ = $1; }
    | retval                { $$ = $1; }
    ;

identifier:
    IDENTIFIER                  { $$ = createNode(yylval.value, NULL); }
    | IDENTIFIER LSB exp RSB    {$$ = createNode("[]", createNode($1, NULL), $3, NULL);}
    ;

%%

int main(){
    pTree = createNode("CODE", NULL);
    yyparse();
    return 0;
}

//YACC functions
void yyerror(char *s){
    fprintf(stderr, "%s ", s);
    printf("while reading token '%s'\n", yytext);
}

int yywrap(){
    return 1;
}