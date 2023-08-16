#ifndef SYMTAB_HH
#define SYMTAB_HH

#include <fstream>
#include <cstdarg>
#include <iostream>
#include <map>
#include <iterator>
#include <vector>

#define POINTER_SIZE 4

using namespace std;

struct SymbTab;

struct Entry
{
    string varfun;
    string scope;
    int size;
    int offset;
    vector<string> type;
    string type_str;
    string basetype;
    SymbTab *symbtab;
    int pointer_level;
    int array_level;
    vector<int> array_limits;
    vector<Entry *> param_list;
    string returntype;

    void print();

    void setSize();
};

struct SymbTab
{
    map<string, Entry *> Entries;
    int size;
    void print();
};

#endif