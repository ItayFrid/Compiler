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
typedef struct Node Node;
typedef struct Node{
    char *token;
    Node **child;
    Node* parent;
    int numOfChilds;
} Node;

#include "lex.yy.c"
void yyerror(char *s);
int yywrap();
// Creating Tree functions
Node * createNode(char *token, ...);
void addChild(Node *father, Node *newChild);
void printTree(Node *node, int level);
void print(Node *root);
void reverseChilds(Node *node);
Node* makeParent(char* token,Node*child);
void fixTree(Node *node,int level);
void printer(Node *node);

// Semantic functions
void newError(const char *error);
void errorSummary();
void makeParents(Node *node, int level);
void checkSemantics(Node *root, int level);
void checkMain(Node *node);
int getChildIndex(Node *father, Node *child);
void checkProcFuncScope(Node *procNode);
char ** getVarNames(char *var, int *var_size);
int compareVariables(char **list1, int size1, char **list2, int size2);
void checkVarScope(Node *varNode);
void fixEmptyNode(Node *emptyNode);

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

%type <nPtr> code proc func arguments body funcbody assign exp statements statement if loop declare retType identifier argumentList parameters main retStatement funcCall
%type <value> type args retval bool NUM IDENTIFIER
%%

program:
    process
    {
        reverseChilds(pTree);
        makeParents(pTree, 1);
        fixTree(pTree, 1);
        checkSemantics(pTree, 1);
        errorSummary();
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
        {$$ = createNode("",createNode(strcat(strcat($3," "),$1),NULL),NULL);}
    ;

args:
    args COMMA args {$$ = strcat($1,$3);}
    | identifier    {$$ = strcat($1->token," ");}
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
    | DOUBLE        {$$ = yylval.value;}
    | CHARACTER     {$$ = yylval.value;}
    | STR           {$$ = yylval.value;}
    | identifier    {$$ = $1->token;}
    | bool          {$$ = $1;}
    | NUL           {$$ = yylval.value;}
    | LENGTH identifier LENGTH
    {
        char *s=(char*)malloc(sizeof(char));
        strcat(s,"|");strcat(s,$2->token);strcat(s,"|");
        $$=s;
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
    IDENTIFIER LB args RB
    {
        char *s = (char*)malloc(sizeof(char));

        $$=createNode("CALL",createNode($1,createNode($3,NULL),NULL),NULL);
    }
    | IDENTIFIER LB RB
    {
        $$=createNode("CALL",createNode($1,NULL),NULL);
    }
    ;

retStatement:
    RETURN retval SEMICOLON
    {
        char *s = (char*)malloc(sizeof(char));
        strcat(s,"RET ");
        strcat(s,$2);
        $$ = createNode(s,NULL);
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
        {$$ = createNode(strcat($1->token,"="),$3,NULL);}
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
    | funcCall              {$$=$1;}
    | retval                {$$=createNode($1,NULL);}
    ;

identifier:
    IDENTIFIER  {$$=createNode(yylval.value,NULL);}
    | IDENTIFIER LSB NUM RSB
    {
        char *s=(char*)malloc(sizeof(char));
        strcat(s,$1);strcat(s,"[");strcat(s,$3);strcat(s,"]");
        $$=createNode(s,NULL);
    }
    | IDENTIFIER LSB IDENTIFIER RSB
    {
        char *s=(char*)malloc(sizeof(char));
        strcat(s,$1);strcat(s,"[");strcat(s,$3);strcat(s,"]");
        $$=createNode(s,NULL);
    }
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
    // if(strcmp(node->token,"")!=0){
        for (i = 1; i < level; i++) {
            printf("    ");
        }
        if(node->numOfChilds!=0)
            printf("(");    
        printf("%s\n", node->token);
//    }
    // if(strcmp(node->token,"")==0)
    //     level = level-1;
    for (i = 0; i < node->numOfChilds; i++) {
        printTree((node->child)[i], level + 1);
    }
    if(node->numOfChilds!=0){ // && strcmp(node->token,"")!=0){
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

void makeParents(Node *node, int level){
    if(level == 1)
        node->parent = NULL;
  int i;
  for(i=0; i<node->numOfChilds; i++){
      node->child[i]->parent = node;
      makeParents(node->child[i], level+1);
  }
}

void fixTree(Node *node, int level){
    int i;
    for(i=0; i<node->numOfChilds; i++)
        fixTree(node->child[i], level+1);
    if(strcmp(node->token, "") == 0)
        fixEmptyNode(node);
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

//This function returns a childs position in fathers children array
int getChildIndex(Node *father, Node *child){
    int i = 0;
    for(i=0; i<father->numOfChilds; i++){
        if(father->child[i] == child)
            return i;
    }
    return -1;
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

//This function parses a var node token to get variable names
char ** getVarNames(char *var, int *var_size){
    const char delim[2] = " ";
    char *buffer = (char*) malloc (strlen(var) * sizeof(char));
    char **varNames = NULL;
    int i = 0;
    *var_size = 0;
    strcpy(buffer, var);
   /* get the first token */
   buffer = strtok(buffer, delim);
   
   /* walk through other tokens */
   while( buffer != NULL ) {
      buffer = strtok(NULL, delim);
      if(buffer != NULL)
        (*var_size)++;
   }
   buffer = (char*) malloc (strlen(var) * sizeof(char));
   strcpy(buffer, var);
   varNames = (char**) malloc ((*var_size) * sizeof(char*));
   
   /* get the first token */
   buffer = strtok(buffer, delim);
   
   /* walk through other tokens */
   while( buffer != NULL ) {
      buffer = strtok(NULL, delim);
      if(buffer != NULL){
          varNames[i] = buffer;
          i++;
      }
   }
   return varNames;
}

//This function returns the number of similarities between two variable lists
int compareVariables(char **list1, int size1, char **list2, int size2){
    int i, j, sim = 0;
    for(i = 0; i < size1; i++){
        for(j = 0; j < size2; j++){
            if(strcmp(list1[i], list2[j]) == 0)
                sim++;
        }
    }
    return sim;
}

//This function checks that there are no 2 variables with the same name in same scope
void checkVarScope(Node *varNode){
    Node *scopePtr = varNode->parent, *varPtr = varNode->child[0];
    int selfVarSize, size, i, index;
    char **selfVarNames = NULL, **varNames = NULL;
    while(strcmp(varPtr->token, "") == 0)
        varPtr = varPtr->child[0];
    selfVarNames = getVarNames(varPtr->token, &selfVarSize);
    if(compareVariables(selfVarNames, selfVarSize, selfVarNames, selfVarSize) != selfVarSize)
        newError("Repeated variable name for same type");
    index = getChildIndex(scopePtr, varNode);
    while(strcmp(scopePtr->token, "BLOCK") != 0 && strcmp(scopePtr->token, "BODY") != 0)
        scopePtr = scopePtr->parent;
    for(i = 0; i < scopePtr->numOfChilds; i++){
        if(strcmp(scopePtr->child[i]->token, "VAR") == 0){
            Node *search = scopePtr->child[i];
            while(strcmp(search->token, "") == 0)
                search = search->child[0];
            varNames = getVarNames(search->token, &size);
            if(compareVariables(selfVarNames, selfVarSize, varNames, size) != 0)
                newError("Conflicting variable names");
        }
    }
}