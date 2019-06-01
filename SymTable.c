#include "definitions.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
#ifndef TABLE
#define TABLE

//Creating new symbol
Symbol * newSymbol(char *id, char *type, char *value, identifierType idType){
    Symbol *newSymbol = (Symbol*) malloc (sizeof(Symbol));
    newSymbol->id = id;
    newSymbol->type = type;
    newSymbol->value = value;
    newSymbol->idType = idType;
    newSymbol->next = NULL;
    return newSymbol;
}

//Adding symbol to symbol table : returns 1 is added, 0 if symbol already exists
int addSymbol(SymTable *table, Symbol *newSym){
    Symbol *lastSym = NULL;
    if(findSymbol(table, newSym->id, newSym->idType) != NULL)
        return 0;
    if(table->symbolListHead == NULL)
        table->symbolListHead = newSym;
    else{
        lastSym = table->symbolListHead;
        while(lastSym->next != NULL)
            lastSym = lastSym->next;
        lastSym->next = newSym;
    }
    return 1;

}

//Finding a symbol in a table : returns NULL if not found
Symbol * findSymbol(SymTable *table, char *id, identifierType idType){
    Symbol *search = table->symbolListHead;
    while(search != NULL){
        if(strcmp(search->id, id) == 0 && search->idType == idType)
            return search;
        search = search->next;
    }
    return search;
}

//Creating new table
SymTable * newSymTable(Node *scopePtr){
    SymTable *newTable = (SymTable*) malloc (sizeof(SymTable));
    newTable->scopePtr = scopePtr;
    newTable->symbolListHead = NULL;
    newTable->next = NULL;
    return newTable;
}

//Adding a scope's table to global list
void addTable(SymTable *newTable){
    if(scopes_head == NULL)
        scopes_head = newTable;
    else{
        newTable->next = scopes_head;
        scopes_head = newTable;
    }
}

//Finding a scope's table
SymTable * findTable(Node *scopePtr){
    SymTable *search = scopes_head;
    while(search != NULL){
        if(search->scopePtr == scopePtr)
            return search;
        search = search->next;
    }
    return search;
}

//Printing out symbol information
void printSymbol(Symbol *symbol){
    if(symbol->value!=NULL)
        printf("Id: %s\tType: %s\tValue: %s\tSymbol type: ", symbol->id,symbol->type, symbol->value);
    else
        printf("Id: %s\tType: %s\tValue: NULL\tSymbol type: ", symbol->id,symbol->type);

    if(symbol->idType == VARIABLE)
        printf("VARIABLE\n");
    else
        printf("FUNCTION\n");
    
    
}

//Printing out table information
void printTable(SymTable *table){
    Symbol *scan = table->symbolListHead;
    printf("Scope: %s\n", table->scopePtr->token);
    while(scan != NULL){
        printSymbol(scan);
        scan = scan->next;
    }
}

//Printing out all the scopes
void printScopes(){
    SymTable *scan = scopes_head;
    while(scan != NULL){
        printTable(scan);
        scan = scan->next;
    }
}

//This function counts symbols in a symbol table
int getTableSize(SymTable *table){
    int count = 0;
    Symbol *scan = table->symbolListHead;
    while(scan != NULL){
        count++;
        scan = scan->next;
    }
    return count;
}

#endif