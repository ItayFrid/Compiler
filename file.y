%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
typedef struct Node Node;
typedef struct AST AST;
typedef struct Node{
    char *token;
    Node **child;
    int numOfChilds;
} Node;
typedef struct AST{
    Node *root;
} AST;
#define YYSTYPE Node*
#include "lex.yy.c"
void yyerror(char *s);
int yywrap();
void init(AST *tree);
Node * createNode(char *token, ...);
void addChild(Node *father, Node *newChild);
void printTree(Node *node, int level);
void print(Node *root);
void reverseChilds(Node *node);
Node* pTree;
%}
%start s
%token NUM DOUBLE SEMICOLON PROC FUNC RETURN NUL IF ELSE WHILE FOR VAR INT CHAR REAL INTP CHARP REALP BOOL STRING LB RB LCB RCB LSB RSB COLON COMMA GREATER GREATEREQUAL LESS LESSEQUAL EQUAL AND DIVIDE ASSIGNMENT LENGTH PLUS MINUS MULT OR REF POWER NOT DIFF ONEPAREN DOUBLEPAREN TRUE FALSE IDENTIFIER
%left PLUS MINUS
%left MULT DIVIDE
%left POWER
%%
s:    line {reverseChilds(pTree);print(pTree);};
line: exp SEMICOLON {addChild(pTree,$1);}
    | exp SEMICOLON line {addChild(pTree,$1);};
exp:  exp POWER exp {$$ = createNode("^",$1,$3,NULL);}
    | exp DIVIDE exp {$$ = createNode("/",$1,$3,NULL);}
    | exp MULT exp {$$ = createNode("*",$1,$3,NULL);}
    | exp PLUS exp {$$ = createNode("+",$1,$3,NULL);}
    | exp MINUS exp {$$ = createNode("-",$1,$3,NULL);}
    | NUM {$$=createNode(yytext,NULL);};
%%
int main(){
    pTree = createNode("CODE", NULL);
  yyparse();
  return 0;
}
/*Initializing AST*/
void init(AST *tree){
    tree->root = createNode("CODE", 0);
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
    for (i = 1; i < level; i++) {
        printf("\t");
    }
    printf("%s\n", node->token);
    for (i = 0; i < node->numOfChilds; i++) {
        printTree((node->child)[i], level + 1);
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
  fprintf(stderr,"%s\n",s);
}
int yywrap(){
  return 1;
}
