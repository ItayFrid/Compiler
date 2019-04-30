// Itay Fridman 305360653
// Idan Aharon  305437774
// Noam Bahar   203155650
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
typedef struct Node Node;
typedef struct Node{
    char *token;
    Node **child;
    int numOfChilds;
} Node;

#include "lex.yy.c"
// #define YYSTYPE Node*
void yyerror(char *s);
int yywrap();
Node * createNode(char *token, ...);
void addChild(Node *father, Node *newChild);
void printTree(Node *node, int level);
void print(Node *root);
void reverseChilds(Node *node);
Node* makeParent(char* token,Node*child);
void fixTree(Node *node,Node* father);
void printer(Node *node);
Node* pTree;
int yydebug=1;
int lastChild = 0;
%}
%union{
  char* value;
  Node* nPtr;
}
%start program

%token NEGNUM NUM DOUBLE SEMICOLON PROC FUNC RETURN NUL IF ELSE WHILE FOR VAR INT
%token CHAR REAL INTP CHARP REALP BOOL STRING LB RB LCB RCB LSB RSB COLON
%token COMMA GREATER GREATEREQUAL LESS LESSEQUAL EQUAL AND DIVIDE ASSIGNMENT
%token LENGTH PLUS MINUS MULT OR REF POWER NOT DIFF ONEPAREN DOUBLEPAREN TRUE
%token FALSE IDENTIFIER CHARACTER STR MAIN

%left PLUS MINUS
%left MULT DIVIDE
%left POWER
%left LB RB
%left AND OR
%left ELSE
%left COMMA

%type <nPtr> code proc func arguments body funcbody assign exp statements statement if loop compare declare retType identifier argumentList parameters main
%type <value> type args retval
%%

program:
    process {reverseChilds(pTree);print(pTree);}
    ;

process:  
    code process {addChild(pTree,$1);}
    | code       {addChild(pTree,$1);}
    | main       {addChild(pTree,$1);}
    ;

code:
    proc            {$$=$1;}
    | func          {$$=$1;}
    | statements    {$$=$1;}
    ;

proc:
    PROC identifier LB parameters RB body
        {$$ = createNode("PROC",$2,$4,$6,NULL);}
    | PROC identifier LB RB body
        {$$ = createNode("PROC",$2,createNode("ARGS NONE", NULL),$5,NULL);}
    ;

func:
    FUNC identifier LB parameters RB RETURN retType funcbody
        {$$ = createNode("FUNC",$2,$4,$7,$8,NULL);}
    | FUNC identifier LB RB RETURN retType funcbody
        {$$ = createNode("FUNC",$2,createNode("ARGS NONE", NULL),$6,$7,NULL);}
    ;

retType:
    type    {
                char *s = (char*)malloc(sizeof(char));
                strcat(s,"RET ");
                strcat(s,$1);
                $$ = createNode(s,NULL);
            }
    ;

parameters:
    arguments   {$$ = createNode("ARGS",$1,NULL);}
    ;

arguments:
    argumentList                        {$$ = createNode("",$1,NULL);}
    | argumentList SEMICOLON arguments  {$$ = createNode("",$1,$3,NULL);}
    |                                   {$$ = createNode(" NONE",NULL);}
    ;

argumentList:
    args COLON type
        {$$ = createNode("",createNode(strcat(strcat($3," "),$1),NULL),NULL);}
    ;

args:
    args COMMA args   {$$ = strcat($1,$3);}
    | identifier      {$$ = strcat($1->token," ");}
    ;

type:
    INT         {$$=yylval.value;}
    | CHAR      {$$=yylval.value;}
    | REAL      {$$=yylval.value;}
    | INTP      {$$=yylval.value;}
    | CHARP     {$$=yylval.value;}
    | REALP     {$$=yylval.value;}
    | BOOL      {$$=yylval.value;}
    | STRING    {$$=yylval.value;}
    ;

body:
    LCB statements RCB  {$$ = createNode("BLOCK",$2,NULL);}
    ;

main:
    PROC MAIN LB RB body    {$$ = createNode("MAIN", $5, NULL);}
    ; 

funcbody:
    LCB statements RETURN retval SEMICOLON RCB
        {
            char *s = (char*)malloc(sizeof(char));
            strcat(s,"RET ");
            strcat(s,$4);
            $$ = createNode("BODY",$2,createNode(s,NULL),NULL);
        }
    | LCB RETURN retval SEMICOLON RCB
        {
            char *s = (char*)malloc(sizeof(char));
            strcat(s,"RET ");
            strcat(s,$3);
            $$ = createNode("BODY",createNode(s,NULL),NULL);   
        }
    ;

retval:
    NUM             {$$ = yylval.value;}
    | CHARACTER     {$$ = yylval.value;}
    | STR           {$$ = yylval.value;}
    | IDENTIFIER    {$$ = yylval.value;}
    | NEGNUM        {$$ = yylval.value;}
    ;

statements:
    statements statement    {$$=createNode("",$1,$2,NULL);}
    | statement             {$$=$1;}
    ;

statement:
    if                  {$$=$1;}
    | assign SEMICOLON  {$$=$1;}
    | loop              {$$=$1;}
    | body              {$$=$1;}
    | func              {$$=$1;}
    | proc              {$$=$1;}
    | declare           {$$=$1;}
    ;

if:
    IF LB compare RB statement
        {$$ = createNode("IF",$3,$5,NULL);}
    | IF LB compare RB statement ELSE statement
        {$$ = createNode("IF-ELSE",$3,$5,$7,NULL);}
    ;

loop:
    WHILE LB compare RB statement
        {$$ = createNode("WHILE",$3,$5,NULL);}
    | FOR LB assign SEMICOLON compare SEMICOLON assign RB statement
        {$$ = createNode("FOR", $3, $5, $7, $9, NULL);}
    ;

compare:
    exp GREATER exp         {$$ = createNode(">",$1,$3,NULL);}
    | exp GREATEREQUAL exp  {$$ = createNode(">=",$1,$3,NULL);}
    | exp LESS exp          {$$ = createNode("<",$1,$3,NULL);}
    | exp LESSEQUAL exp     {$$ = createNode("<=",$1,$3,NULL);}
    | exp EQUAL exp         {$$ = createNode("==",$1,$3,NULL);}
    | exp DIFF exp          {$$ = createNode("!=",$1,$3,NULL);}
    | compare AND compare   {$$ = createNode("&&",$1,$3,NULL);}
    | compare OR compare    {$$ = createNode("||",$1,$3,NULL);}
    ;

declare:
    VAR argumentList SEMICOLON   {$$ = createNode("VAR", $2, NULL);}
    ;

assign:
    identifier ASSIGNMENT exp
        {$$ = createNode(strcat($1->token,"="),$3,NULL);}
    | identifier ASSIGNMENT retval
        {$$ = createNode(strcat($1->token,"="),createNode($3,NULL),NULL);}
    ;

exp:
    exp POWER exp     {$$ = createNode("^",$1,$3,NULL);}
    | exp DIVIDE exp  {$$ = createNode("/",$1,$3,NULL);}
    | exp MULT exp    {$$ = createNode("*",$1,$3,NULL);}
    | exp PLUS exp    {$$ = createNode("+",$1,$3,NULL);}
    | exp MINUS exp   {$$ = createNode("-",$1,$3,NULL);}
    | LB exp RB       {$$ = $2;}
    | NUM             {$$=createNode(yylval.value,NULL);}
    | NEGNUM          {$$=createNode(yylval.value,NULL);}
    | DOUBLE          {$$=createNode(yylval.value,NULL);}
    | IDENTIFIER      {$$=createNode(yylval.value,NULL);}
    ;

identifier:
    IDENTIFIER  {$$=createNode(yylval.value,NULL);}
    ;

%%
int main(){
  pTree = createNode("CODE", NULL);
  yyparse();
  return 0;
}

/*Initializing new node*/
Node * createNode(char *token, ...){
    int i, count = 0;
    va_list countPointer, listPointer;
    Node *newNode = (Node *) malloc (sizeof(Node));
    Node *getArg = NULL;

    //Initializing token
    newNode->token = (char *) malloc (strlen(token)*sizeof(char));
    strcpy(newNode->token, token);
    //Counting number of arguments passed
    va_start(countPointer, token);
    do{
        getArg = va_arg(countPointer, Node *);
        if(getArg != NULL)
            count++;
    }while(getArg != NULL);

    //Assigining children to array
    if(count != 0){
        newNode->numOfChilds = count;
        va_start(listPointer, token);
        newNode->child = (Node**) malloc (count * sizeof(Node *));
        for(i = 0; i < count; i++){
            (newNode->child)[i] = va_arg(listPointer, Node *);
        }     
    }
    else{
        newNode->child = NULL;
        newNode->numOfChilds = 0;
    }
    return newNode;
}

//Adding child to childs array
void addChild(Node *father, Node *newChild){
    int i;
    
    Node **temp = NULL;
    //For first child
    if(father->numOfChilds == 0){
        father->child = (Node**) malloc (sizeof(Node*));
        (father->child)[0] = newChild;
        father->numOfChilds = 1;
    }
    else{
        temp = (Node **) malloc (((father->numOfChilds) + 1) * (sizeof(Node*)));
        for(i = 0; i < father->numOfChilds; i++)
            temp[i] = (father->child)[i];
        temp[father->numOfChilds] = newChild;
        free(father->child);
        father->child = temp;
        (father->numOfChilds)++;
    }
}
/*Printing AST*/
void print(Node *root){
    printTree(root, 1);
}
void printTree(Node *node, int level) {
    int i;
    if(strcmp(node->token,"")!=0){
        for (i = 1; i < level; i++) {
            printf("    ");
        }
        if(node->numOfChilds!=0)
            printf("(");    
        printf("%s\n", node->token);
    }
    if(strcmp(node->token,"")==0)
        level = level-1;
    for (i = 0; i < node->numOfChilds; i++) {
        printTree((node->child)[i], level + 1);
    }
    if(node->numOfChilds!=0 && strcmp(node->token,"")!=0){
        for (i = 1; i < level; i++) {
            printf("    ");
        }
        printf(")\n"); 
    }
}

void reverseChilds(Node *node){
    int i = 0, j = (node->numOfChilds) - 1;
    Node **newChilds = (Node**) malloc ((node->numOfChilds) * sizeof(Node *));
    while(j >= 0){
        newChilds[j] = (node->child)[i];
        j--;
        i++;
    }
    free((node->child));
    node->child = newChilds;
}
void yyerror(char *s){
  fprintf(stderr,"%s ",s);
  printf("while reading token '%s'\n", yytext);
}
int yywrap(){
  return 1;
}

Node* makeParent(char* token,Node*child){
  Node*parent = createNode(token,child,NULL);
  return parent;
}
void fixTree(Node *node,Node *father){
    int i;
    if(node->numOfChilds != 0){
        if(strcmp(node->token,"")==0){
            for(i=0;i<node->numOfChilds;i++)
                addChild(father,(node->child)[i]);
            // free(node);
        }
        for(i=0;i<node->numOfChilds;i++)
            fixTree((node->child)[i],node);
    }
}
void printer(Node *node) {
    int i;
    // for (i = 1; i < level; i++) {
    //     printf("\t");
    // }
    printf("Node: %s\n", node->token);
    if(node->numOfChilds == 0)
        printf("No children\n");
    else{
    printf("Children:\n");
    for (i = 0; i < node->numOfChilds; i++) 
        printf("%s ", (node->child)[i]->token);
    for (i = 0; i < node->numOfChilds; i++) 
        printer((node->child)[i]);
    }
}

