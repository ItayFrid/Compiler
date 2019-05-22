
#include "definitions.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
#ifndef TREE
#define TREE

//Initializing New Node
Node * createNode(char *token, ...){
    int i, j, count = 0;
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
        if(getArg != NULL){
            if(strcmp(getArg->token, "") == 0){
                count += getArg->numOfChilds;
            }
            else
                count++;
        }
            
    }while(getArg != NULL);

    //Assigining children to array
    if(count != 0){
        newNode->numOfChilds = count;
        va_start(listPointer, token);
        newNode->child = (Node**) malloc (count * sizeof(Node *));
        i = 0;
        while(i < count){
            getArg = va_arg(listPointer, Node *);
            if(strcmp(getArg->token, "") == 0){         //If current node is an empty one, add he's children
                for(j = 0; j < getArg->numOfChilds; j++){
                    newNode->child[i] = getArg->child[j];
                    i++;
                }
            }
            else{
                newNode->child[i] = getArg;     //Not emty node
                i++;
            }
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

// This function prints out the AST
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

    if(strcmp(node->token, "") == 0)
        printf("Node: EMPTY NODE\n");
    else
        printf("Node: %s\n", node->token);
    
    if(node->numOfChilds == 0)
        printf("No children\n");
    else{
    printf("Children:\n");
    for (i = 0; i < node->numOfChilds; i++){
        if(strcmp(node->child[i]->token, "") == 0)
            printf("EMPTY NODE\n");
        else
            printf("%s\n", (node->child)[i]->token);
    } 
        
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
#endif