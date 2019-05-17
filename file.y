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
#include "SymTable.c"
// typedef struct Node Node;
// typedef struct Node{
//     char *token;
//     Node **child;
//     Node* parent;
//     int numOfChilds;
// } Node;

#include "lex.yy.c"
void yyerror(char *s);
int yywrap();

// Tree functions
Node * createNode(char *token, ...);
void addChild(Node *father, Node *newChild);
void printTree(Node *node, int level);
void print(Node *root);
void reverseChilds(Node *node);
void makeParents(Node *node, int level);
void printer(Node *node);
int getChildIndex(Node *father, Node *child);

char * appendStrings(char *str1, char *str2);

// Semantic checking functions
void checkSemantics(Node *root, int level);
void checkMain(Node *node);
void checkProcFuncScope(Node *procNode);
void checkVarScope(Node *varNode);
void checkFunctionCall(Node *node);

// Error handling
void newError(const char *error);
void errorSummary();

// Empty node handling
void fixTree(Node *root);
void checkEmpty(Node *node, int level);
void fixEmptyNode(Node *emptyNode);
Node *currentEmptyNode = NULL;

//Symbol table
//SymTable * scopes_head = NULL;
void initScopes(Node *node);
Node * findScopeNode(Node *node);

// Global variables
Node* pTree;

int yydebug=1;
int lastChild = 0;
char **semErrors = NULL;
int numOfErrors = 0;

%}
%union{
  char* value;
  Node* nPtr;
}
%start program

%token NUM DOUBLE SEMICOLON PROC FUNC RETURN NUL IF ELSE WHILE FOR VAR INT
%token CHAR REAL INTP CHARP REALP BOOL STRING LB RB LCB RCB LSB RSB COLON
%token COMMA GREATER GREATEREQUAL LESS LESSEQUAL EQUAL AND DIVIDE ASSIGNMENT
%token LENGTH PLUS MINUS MULT OR REF DEREF NOT DIFF TRUE FALSE IDENTIFIER
%token CHARACTER STR MAIN

%left NOT REF DEREF
%left PLUS MINUS
%left MULT DIVIDE
%left GREATER GREATEREQUAL LESS LESSEQUAL EQUAL DIFF
%left OR
%left AND
%left LB RB
%left ELSE
%left COMMA


%type <nPtr> code proc func arguments body funcbody assign exp statements statement if loop declare retType identifier argumentList parameters main retStatement funcCall funcArgs args retval
%type <value> type bool NUM IDENTIFIER
%%

program:
    process
    {
        reverseChilds(pTree);
        makeParents(pTree, 1);
        // fixTree(pTree);
        // initScopes(pTree);
        // checkSemantics(pTree, 1);
        // errorSummary();
        printScopes();
        //if(numOfErrors == 0)
            print(pTree);
        //printTree(pTree);
    }
    ;

process:  
    code process {addChild(pTree,$1);}
    | code       {addChild(pTree,$1);}
    | main       {addChild(pTree,$1);}
    ;

code:
    proc    {$$=$1;}
    | func  {$$=$1;}
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
    type
    {
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
    ;

argumentList:
    args COLON type
        {
            $$ = createNode($3,$1,NULL);
        }
    ;

args:
    args COMMA identifier{$$ = createNode("",$1,$3,NULL);}
    | identifier    {$$ = $1;}
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
    | type LSB NUM RSB
    {
        char *s = (char*)malloc(sizeof(char));
        strcat(s,$1);strcat(s,"[");strcat(s,$3);strcat(s,"]");
        $$=s;
    }
    ;

body:
    LCB statements RCB  {$$ = createNode("BLOCK",$2,NULL);}
    | LCB RCB           {$$ = createNode("BLOCK",NULL);}
    ;

main:
    PROC MAIN LB RB body    {$$ = createNode("MAIN", $5, NULL);}
    ; 

funcbody:
    LCB statements RETURN exp SEMICOLON RCB
        {
            // char *s = (char*)malloc(sizeof(char));
            // strcat(s,"RET ");
            // strcat(s,$4);
            $$ = createNode("BODY",$2,$4,NULL);
        }
    | LCB RETURN exp SEMICOLON RCB
        {
            // char *s = (char*)malloc(sizeof(char));
            // strcat(s,"RET ");
            // strcat(s,$3);
            $$ = createNode("BODY",$3,NULL);   
        }
    ;

retval:
    NUM             {$$ = createNode(yylval.value,NULL);}
    | DOUBLE        {$$ = createNode(yylval.value,NULL);}
    | CHARACTER     {$$ = createNode(yylval.value,NULL);}
    | STR           {$$ = createNode(yylval.value,NULL);}
    | identifier    {$$ = $1;}
    | bool          {$$ = createNode($1,NULL);}
    | NUL           {$$ = createNode(yylval.value,NULL);}
    | LENGTH identifier LENGTH
    {
        char *s=(char*)malloc(sizeof(char));
        strcat(s,"|");strcat(s,$2->token);strcat(s,"|");
        $$=createNode(s,NULL);
    }
    ;

bool:
    TRUE    {$$ = yylval.value;}
    | FALSE {$$ = yylval.value;}
    ;

statements:
    statements statement    {$$=createNode("",$1,$2,NULL);}
    | statement             {$$=$1;}
    ;

statement:
    if                      {$$=$1;}
    | assign SEMICOLON      {$$=$1;}
    | loop                  {$$=$1;}
    | body                  {$$=$1;}
    | func                  {$$=$1;}
    | proc                  {$$=$1;}
    | declare               {$$=$1;}
    | retStatement          {$$=$1;}
    | funcCall SEMICOLON    {$$=$1;}
    ;

funcCall:
    IDENTIFIER LB funcArgs RB
    {
        // char *s = (char*)malloc(sizeof(char));
        // char *t = (char*)malloc(sizeof(char));
        // strcat(t,"ARGS ");strcat(t,$3);
        $$=createNode("CALL",createNode($1,createNode("",$3,NULL),NULL),NULL);
    }
    | IDENTIFIER LB RB
    {
        $$=createNode("CALL",createNode($1,NULL),NULL);
    }
    ;

funcArgs:
    funcArgs COMMA exp {$$ = createNode("",$1,$3,NULL);}
    | exp {$$ = $1;}
    ;

retStatement:
    RETURN exp SEMICOLON
    {
        // char *s = (char*)malloc(sizeof(char));
        // strcat(s,"RET ");
        // strcat(s,$2);
        $$ = createNode("RET",$2,NULL);
    }
    ;
if:
    IF LB exp RB statement
        {$$ = createNode("IF",$3,$5,NULL);}
    | IF LB exp RB statement ELSE statement
        {$$ = createNode("IF-ELSE",$3,$5,$7,NULL);}
    ;

loop:
    WHILE LB exp RB statement
        {$$ = createNode("WHILE",$3,$5,NULL);}
    | FOR LB assign SEMICOLON exp SEMICOLON assign RB statement
        {$$ = createNode("FOR", $3, $5, $7, $9, NULL);}
    ;

declare:
    VAR argumentList SEMICOLON  {$$ = createNode("VAR", $2, NULL);}
    ;

assign:
    identifier ASSIGNMENT exp
        {$$ = createNode("=",$1,$3,NULL);}
    ;

exp:
    exp PLUS exp            {$$ = createNode("+",$1,$3,NULL);}
    | exp MINUS exp         {$$ = createNode("-",$1,$3,NULL);}
    | exp MULT exp          {$$ = createNode("*",$1,$3,NULL);}
    | exp DIVIDE exp        {$$ = createNode("/",$1,$3,NULL);}
    | exp AND exp           {$$ = createNode("&&",$1,$3,NULL);}
    | exp EQUAL exp         {$$ = createNode("==",$1,$3,NULL);}
    | exp GREATER exp       {$$ = createNode(">",$1,$3,NULL);}
    | exp GREATEREQUAL exp  {$$ = createNode(">=",$1,$3,NULL);}
    | exp LESS exp          {$$ = createNode("<",$1,$3,NULL);}
    | exp LESSEQUAL exp     {$$ = createNode("<=",$1,$3,NULL);}
    | exp DIFF exp          {$$ = createNode("!=",$1,$3,NULL);}
    | exp OR exp            {$$ = createNode("||",$1,$3,NULL);}
    | NOT exp               {$$ = createNode("!",$2,NULL);}
    | REF exp               {$$ = createNode("&",$2,NULL);}
    | DEREF exp             {$$ = createNode("^",$2,NULL);}
    | LB exp RB             {$$ = $2;}
    | funcCall              {$$ = $1;}
    | retval                {$$=$1;}
    ;

identifier:
    IDENTIFIER  {$$=createNode(yylval.value,NULL);}
    | IDENTIFIER LSB exp RSB
    {
        // char *s=(char*)malloc(sizeof(char));
        // strcat(s,"[");strcat(s,"]");
        $$=createNode("[]",createNode($1,NULL),$3,NULL);
    }
    ;

%%

int main(){
  pTree = createNode("CODE", NULL);
  yyparse();
  return 0;
}


//YACC functions
void yyerror(char *s){
  fprintf(stderr,"%s ",s);
  printf("while reading token '%s'\n", yytext);
}
int yywrap(){
  return 1;
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

//This function prints out the AST
void printTree(Node *node, int level) {
    int i;
        for (i = 1; i < level; i++) {
            printf("    ");
        }
        if(node->numOfChilds!=0)
            printf("(");    
        printf("%s\n", node->token);

    for (i = 0; i < node->numOfChilds; i++) {
        printTree((node->child)[i], level + 1);
    }
    if(node->numOfChilds!=0 ){
        for (i = 1; i < level; i++) {
            printf("    ");
        }
        printf(")\n"); 
    }
}

//This function prints out the tree without nesting
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
        printf("%s\n", (node->child)[i]->token);
    for (i = 0; i < node->numOfChilds; i++) 
        printer((node->child)[i]);
    }
}

//This function reverses the order of a node's children array
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

//This function initializes each node's parent refrence
void makeParents(Node *node, int level){
    if(level == 1)
        node->parent = NULL;
  int i;
  for(i=0; i<node->numOfChilds; i++){
      node->child[i]->parent = node;
      makeParents(node->child[i], level+1);
  }
}

//This function returns a childs position in fathers children array
int getChildIndex(Node *father, Node *child){
    int i = 0;
    for(i=0; i<father->numOfChilds; i++){
        if(father->child[i] == child)
            return i;
    }
    return -1;
}

//This function handles removing empty nodes from the entire tree
void fixTree(Node *root){
    do{
        if(currentEmptyNode != NULL){
            fixEmptyNode(currentEmptyNode);
            currentEmptyNode = NULL;
        }
        checkEmpty(root, 1);
    }while(currentEmptyNode != NULL);
}

//This function checks if there is an empty string node in the tree
void checkEmpty(Node *node, int level){
    int i;
    if(currentEmptyNode == NULL){
        if(strcmp(node->token, "") == 0){
            currentEmptyNode = node;
        }
        else{
            for(i=0;i<node->numOfChilds; i++)
                checkEmpty(node->child[i], level + 1);
        }
    }
}

//This function removes an empty node from the tree
void fixEmptyNode(Node *emptyNode){
    Node *newFather = emptyNode->parent;

    int newSize = emptyNode->numOfChilds + newFather->numOfChilds - 1;

    Node **newChilds = (Node**) malloc ((newSize) * sizeof(Node*));

    int i, j, k, index = getChildIndex(newFather, emptyNode);
    
    for(i = 0; i < emptyNode->numOfChilds; i++)
        emptyNode->child[i]->parent = newFather;
    i = 0;
    k = 0;
    j = 0;
    while(i < newSize){
        if(i >= index && i <= index+emptyNode->numOfChilds){
            newChilds[i] = emptyNode->child[j];
            j++;
        }
        else{
            newChilds[i] = newFather->child[k];
            k++;
        }   
        i++;
    }
    free(newFather->child);
    free(emptyNode);
    newFather->child = newChilds;
    newFather->numOfChilds = newSize;
}

//This function appends str2 to str1
char * appendStrings(char *str1, char *str2){
    char *app = (char*) malloc ((strlen(str1) + strlen(str2) + 1) * sizeof(char));
    strcpy(app, str1);
    strcat(app, str2);
    return app;
}

//This function adds a new error
void newError(const char *error){
    int i;
    
    char *newErr = (char*) malloc (sizeof(char) * strlen(error));
    strcpy(newErr, error);
    char **temp = NULL;
    //For first error
    if(numOfErrors == 0){
        semErrors = (char**) malloc (sizeof(char*));
        semErrors[0] = newErr;
        numOfErrors = 1;
    }
    else{
        for(i = 0; i < numOfErrors; i++){
            if(strcmp(error, semErrors[i]) == 0)
                return;
        }
        temp = (char **) malloc (((numOfErrors) + 1) * (sizeof(char*)));
        for(i = 0; i < numOfErrors; i++)
            temp[i] = semErrors[i];
        temp[numOfErrors] = newErr;
        free(semErrors);
        semErrors = temp;
        numOfErrors++;
    }
}

//This function prints out all errors collected in semantic check
void errorSummary(){
    int i;
    if(numOfErrors == 0)
        printf("No errors\n");
    else{
        for(i=0; i<numOfErrors; i++)
            printf("Error #%d: %s\n", i+1, semErrors[i]);
    }
}

//This function runs all semantic check functions
void checkSemantics(Node *node, int level){
    int i;
    for(i = 0; i < node->numOfChilds; i++)
        checkSemantics(node->child[i], level+1);

    if(strcmp(node->token, "CODE") == 0)
        checkMain(node);
    if(strcmp(node->token, "PROC") == 0 || strcmp(node->token, "FUNC") == 0)
        checkProcFuncScope(node);
    if(strcmp(node->token, "VAR") == 0)
        checkVarScope(node);
    if(strcmp(node->token, "CALL") == 0)
        checkFunctionCall(node);

}

//This function checks that there is only one main function and it is defined as the last one
void checkMain(Node *node){
    //node argument is a "CODE" node
    int countMains = 0, i;
    for(i=0; i<node->numOfChilds; i++){     //Counting all "MAIN" nodes
        if(strcmp(node->child[i]->token, "MAIN") == 0)
            countMains++;
    }
    if(countMains == 0)
        newError("No main defined");
    if(countMains > 1)
        newError("More than one Main function");
    if(countMains == 1){
        if(strcmp(node->child[node->numOfChilds-1]->token, "MAIN") != 0)
            newError("Main function must be the last one");
    }
}

//This function checks that there are no 2 func/proc with the same name
void checkProcFuncScope(Node *procNode){
    int i;
    Node *ptr = procNode->parent;   //Going up one level
    int index = getChildIndex(ptr, procNode);

    for(i=index; i<ptr->numOfChilds; i++){  //Checking all scope nodes
        if(ptr->child[i] != procNode){  //If the current node is not the one being checked
            if(strcmp(ptr->child[i]->token, "PROC") == 0 || strcmp(ptr->child[i]->token, "FUNC") == 0){     //if the current node is a proc or func
                if(strcmp(procNode->child[0]->token, ptr->child[i]->child[0]->token) == 0)  //Comparing func/proc names
                    newError("Conflicting Proc/Func definition");
            }
        }
    }
}

//This function checks that there are no 2 variables with the same name in same scope
void checkVarScope(Node *varNode){
    Node *scopePtr = findScopeNode(varNode);
    SymTable *table = findTable(scopePtr);
    if(checkTableRepeat(table) == 0)
        newError("Conflicting variable names");
}

void checkFunctionCall(Node *callNode){
  Node * search = callNode->parent, *funcNode = NULL, *prev = callNode;
  int i, found = 0, numArgs;
  char **argNames = NULL;
  
  //Attempting to find func/proc 
  while(!found && search != NULL){
        for(i = 0; i < search->numOfChilds; i++){
            if(strcmp(search->child[i]->token, "PROC") == 0 || strcmp(search->child[i]->token, "FUNC") == 0){   //When finding func or proc definition
                if(strcmp(search->child[i]->child[0]->token, callNode->child[0]->token) == 0){    //If the func/proc matches the call
                    if(getChildIndex(search, prev) > i){
                        funcNode = search->child[i];
                        found = 1;
                    }
                }    
            }
        }
        prev = search;
        search = search->parent;
    }
    if(funcNode == NULL){
        newError("Must define a function/proc before calling it");
        return;
    }
    numArgs = countWords(callNode->child[0]->token);
    argNames = parseString(callNode->child[0]->token, numArgs);
    printf("num args = %d\n", numArgs);


}

//This function returns a node's scope node
Node * findScopeNode(Node *node){
    Node *search = node->parent;
    while(search != NULL){
        if(strcmp(search->token, "PROC") == 0 || strcmp(search->token, "FUNC") == 0 || strcmp(search->token, "BLOCK") == 0)
            return search;
        search = search->parent;
    }
    return search;
}

//This function initializes scopes and their symbol tables
void initScopes(Node *node){
    int i, j, count;
    char **variables = NULL;
    Node *scopePtr = NULL;
    Symbol *newSym = NULL;
    SymTable *table = NULL, *newScope = NULL;
    variableType varType;
    
    if(strcmp(node->token, "PROC") == 0 || strcmp(node->token, "FUNC") == 0 || strcmp(node->token, "BLOCK") == 0 || strcmp(node->token, "BODY") == 0){
        newScope = newSymTable(node);
        addTable(newScope);
    }

    if(strcmp(node->token, "ARGS") == 0 || strcmp(node->token, "VAR") == 0){
        if(strcmp(node->token, "ARGS") == 0)
            varType = ARGUMENT;
        else
            varType = LOCAL;

        scopePtr = findScopeNode(node);

        for(i = 0; i < node->numOfChilds; i++){
            count = countWords(node->child[i]->token);
            
            variables = parseString(node->child[i]->token, count);
            for(j = 1; j < count; j++){
                newSym = newSymbol(variables[j], variables[0], NULL, varType);
                table = findTable(scopePtr);
                addSymbol(table, newSym);
            }
        }
    }
    for(i = 0; i < node->numOfChilds; i++)
        initScopes(node->child[i]);
}