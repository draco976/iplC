#include <cstring>
#include <cstddef>
#include <istream>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <stack>

#include "scanner.hh"
#include "parser.tab.hh"

extern SymbTab gst;
extern SymbTab *lst;

vector<string> global_code;
int AR_top;

void gen_code(string code)
{
  global_code.push_back(code);
}

int num_reg = 3;

std::stack<string> rstack;

void swap(stack<string> &stack)
{
  string top1 = stack.top();
  stack.pop();
  string top2 = stack.top();
  stack.pop();
  stack.push(top1);
  stack.push(top2);
}

string gen_temp()
{
  gen_code("\tsubl\t$4, %esp");
  AR_top = AR_top - 4;
  string temp = to_string(AR_top) + "(%ebp)";
  return temp;
}

void del_temp()
{
  gen_code("\taddl\t$4, %esp");
  AR_top = AR_top + 4;
}

string get_addr(string identifier)
{
  return to_string(lst->Entries[identifier]->offset) + "(%ebp)";
}

Entry *get_entry(string identifier)
{
  return lst->Entries[identifier];
}

Entry *get_struct_entry(string struct_name, string identifier)
{
  return gst.Entries[struct_name]->symbtab->Entries[identifier];
}

int get_size(string struct_type)
{
  if (struct_type != "int")
  {
    return gst.Entries[struct_type]->size;
  }
  else
  {
    return 4;
  }
}

int get_offset2(string struct_type, string member_id, string struct_id)
{
  return gst.Entries[struct_type]->symbtab->Entries[member_id]->offset;
}

string get_addr2(string struct_type, string member_id, string struct_id)
{
  return to_string(gst.Entries[struct_type]->symbtab->Entries[member_id]->offset + lst->Entries[struct_id]->offset) + "(%ebp)";
}

string get_member_offset(string struct_type, string member_id)
{
  return to_string(gst.Entries[struct_type]->symbtab->Entries[member_id]->offset);
}

int jlabel = 1;
string gen_label()
{
  jlabel += 1;
  gen_code(".L" + to_string(jlabel) + ":");
  return ".L" + to_string(jlabel);
}

int nextInstr()
{
  return global_code.size();
}

void backpatch(vector<int> list, string label)
{
  for (int entry : list)
  {
    global_code[entry] += label;
  }
}

vector<int> merge(vector<int> list1, vector<int> list2)
{
  vector<int> res;
  for (int entry : list1)
  {
    res.push_back(entry);
  }
  for (int entry : list2)
  {
    res.push_back(entry);
  }
  return res;
}

int main(const int argc, const char **argv)
{
  rstack.push("%edi");
  rstack.push("%edx");
  rstack.push("%ecx");

  using namespace std;
  fstream in_file;

  in_file.open(argv[1], ios::in);
  // Generate a scanner
  IPL::Scanner scanner(in_file);
  // Generate a Parser, passing the scanner as an argument.
  // Remember %parse-param { Scanner  &scanner  }
  IPL::Parser parser(scanner);

#ifdef YYDEBUG
  parser.set_debug_level(1);
#endif

  parser.parse();

  SymbTab gstfun, gststruct;
  extern std::map<string, abstract_astnode *> ast;
  extern std::vector<string> stringList;

  cout << "\t.file\t\"" << argv[1] << "\"\n";

  cout << "\t.text\n\t.section\t.rodata\n";
  for (int i = 0; i < stringList.size(); i++)
  {
    cout << ".LC" + to_string(i) << ":\n";
    cout << "\t.string\t" + stringList[i] + "\n";
  }

  for (string code : global_code)
  {
    cout << code << "\n";
  }

  cout << "\t.ident	\"GCC: (Ubuntu 8.1.0-9ubuntu1~16.04.york1) 8.1.0\"\n\t.section	.note.GNU-stack,\"\",@progbits\n";

  for (const auto &entry : gst.Entries)
  {
    if (entry.second->varfun == "fun")
      gstfun.Entries.insert({entry.first, entry.second});
  }
  // create gststruct with struct entries only

  for (const auto &entry : gst.Entries)
  {
    if (entry.second->varfun == "struct")
      gststruct.Entries.insert({entry.first, entry.second});
  }
  // start the JSON printing
  return 0;
  cout << "\n\n\n";

  cout << "{\"globalST\": " << endl;
  gst.print();
  cout << "," << endl;

  cout << "  \"structs\": [" << endl;
  for (auto it = gststruct.Entries.begin(); it != gststruct.Entries.end(); ++it)
  {
    cout << "{" << endl;
    cout << "\"name\": "
         << "\"" << it->first << "\"," << endl;
    cout << "\"localST\": " << endl;
    it->second->symbtab->print();
    cout << "}" << endl;
    if (next(it, 1) != gststruct.Entries.end())
      cout << "," << endl;
  }
  cout << "]," << endl;
  cout << "  \"functions\": [" << endl;

  for (auto it = gstfun.Entries.begin(); it != gstfun.Entries.end(); ++it)

  {
    cout << "{" << endl;
    cout << "\"name\": "
         << "\"" << it->first << "\"," << endl;
    cout << "\"localST\": " << endl;
    it->second->symbtab->print();
    cout << "," << endl;
    cout << "\"ast\": " << endl;
    ast[it->first]->print(0);
    cout << "}" << endl;
    if (next(it, 1) != gstfun.Entries.end())
      cout << "," << endl;
  }
  cout << "]" << endl;
  cout << "}" << endl;

  fclose(stdout);
}
