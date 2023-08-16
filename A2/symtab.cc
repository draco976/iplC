#include "symtab.hh"

using namespace std;

extern SymbTab gst;

void Entry::setSize()
{
    if (pointer_level > 0)
    {
        size = POINTER_SIZE;
    }
    else if (type_str == "int" || type_str == "float")
    {
        size = 4;
    }
    else if (type_str == "void")
    {
        size = 0;
    }
    else
    {
        size = gst.Entries[type_str]->size;
    }
    for (int idx = 0; idx < array_limits.size(); idx++)
    {
        size *= array_limits[idx];
        type.push_back(string("[" + to_string(array_limits[idx]) + "]"));
        type_str += string("[" + to_string(array_limits[idx]) + "]");
    }
}

void SymbTab::print()
{

    cout << "[";
    for (auto entry = Entries.begin(); entry != Entries.end(); entry++)
    {

        cout << "[ \"" << entry->first << "\", \"" << entry->second->varfun << "\", \"" << entry->second->scope << "\", ";
        cout << entry->second->size << ", ";
        if (entry->second->type_str == "-")
            cout << "\"-\""
                 << ", \"" << entry->second->type_str << "\"\n]";
        else
            cout << entry->second->offset << ", \"" << entry->second->type_str << "\"\n]";
        if (next(entry, 1) != Entries.end())
            cout << ",\n";
        else
            cout << "\n";
    }
    cout << "]";
}
