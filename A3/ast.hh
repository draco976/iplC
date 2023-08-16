#include <fstream>
#include <cstdarg>
#include <iostream>
#include <map>
#include <iterator>
#include <vector>
#include <stack>
#include "symtab.hh"

using namespace std;

void printAst(const char *astname, const char *fmt...); // fmt is a format string that tells about the type of the arguments.

class abstract_astnode
{
private:
	std::string value;

public:
	vector<string> type;
	string type_str;
	string basetype;
	int ptr_level;
	int arr_level;
	int adr_level;
	int lvalue;
	bool is_param;
	bool by_ref;
	vector<int> array_limits;
	virtual void print(int blanks) = 0;

	string addr;
	int Lfn;
	bool leaf;
};

class statement_astnode : public abstract_astnode
{
public:
	vector<int> next;
	virtual void print(int blanks) = 0;
	virtual void generate_code(stack<string> &rstack);
	;
	;
};

class exp_astnode : public abstract_astnode
{
public:
	string name_str;
	int size;
	bool is_lhs = false;

	int null_ptr = 0;
	vector<int> truelist;
	vector<int> falselist;
	virtual void print(int blanks) = 0;
	virtual void generate_code(stack<string> &rstack, bool boolean);
	virtual void get_address(stack<string> &rstack);
	;
	;
};

class stringconst_astnode : public exp_astnode
{
private:
	string string_val;

public:
	stringconst_astnode(string string_val);
	void print(int blanks);
	;
	;
};

class empty_astnode : public statement_astnode
{
public:
	void print(int blanks);
};

class seq_astnode : public statement_astnode
{
private:
public:
	vector<statement_astnode *> *seq_stmt_ptr;
	seq_astnode();
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
};

class assignS_astnode : public statement_astnode
{
private:
	exp_astnode *left_ptr, *right_ptr;

public:
	assignS_astnode(exp_astnode *left_ptr, exp_astnode *right_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class return_astnode : public statement_astnode
{
private:
	exp_astnode *exp_ptr;
	bool main;
	int lst_size;

public:
	return_astnode(exp_astnode *exp_ptr, bool main, int lst_size);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class if_astnode : public statement_astnode
{
private:
	exp_astnode *cond_ptr;
	statement_astnode *then_ptr, *else_ptr;

public:
	if_astnode(exp_astnode *cond_ptr, statement_astnode *then_ptr, statement_astnode *else_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class while_astnode : public statement_astnode
{
private:
	exp_astnode *cond_ptr;
	statement_astnode *stmt_ptr;

public:
	while_astnode(exp_astnode *cond_ptr, statement_astnode *stmt_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class for_astnode : public statement_astnode
{
private:
	exp_astnode *init_ptr, *guard_ptr, *step_ptr;
	statement_astnode *body;

public:
	for_astnode(exp_astnode *init_ptr, exp_astnode *guard_ptr, exp_astnode *step_ptr, statement_astnode *body);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class ref_astnode : public exp_astnode
{
public:
	virtual void print(int blanks) = 0;
	;
	;
};

class identifier_astnode : public ref_astnode
{
private:
public:
	identifier_astnode(string name_str);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	virtual void get_address(stack<string> &rstack);
	;
	;
};

class printcall_astnode : public statement_astnode
{
private:
	identifier_astnode *fname;
	string str_loc;
	vector<exp_astnode *> *seq_exp_ptr;

public:
	printcall_astnode(identifier_astnode *fname, string str_loc);
	printcall_astnode(identifier_astnode *fname, string str_loc, vector<exp_astnode *> *seq_exp_ptr);
	void generate_code(stack<string> &rstack);
	void print(int blanks);
	;
	;
};

class proccall_astnode : public statement_astnode
{
private:
	identifier_astnode *fname;
	vector<exp_astnode *> *seq_exp_ptr;
	string return_type;
	vector<bool> ref;

public:
	proccall_astnode(identifier_astnode *fname);
	// proccall_astnode(identifier_astnode *fname, vector<exp_astnode> *seq_exp_ptr);
	proccall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr, string return_type, vector<bool> ref);
	void print(int blanks);
	void generate_code(stack<string> &rstack);
	;
	;
};

class arrayref_astnode : public ref_astnode
{
private:
	exp_astnode *array_ptr1, *array_ptr2;

public:
	arrayref_astnode(exp_astnode *array_ptr1, exp_astnode *array_ptr2, string name, string basetype);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	void get_address(stack<string> &rstack);
	;
	;
};

class member_astnode : public ref_astnode
{
private:
	exp_astnode *member_ptr;
	identifier_astnode *id_ptr;

public:
	member_astnode(exp_astnode *member_ptr, identifier_astnode *id_ptr, string name);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	void get_address(stack<string> &rstack);
	;
};

class arrow_astnode : public ref_astnode
{
private:
	exp_astnode *arrow_ptr;
	identifier_astnode *id_ptr;

public:
	arrow_astnode(exp_astnode *arrow_ptr, identifier_astnode *id_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	void get_address(stack<string> &rstack);
	;
};

class op_binary_astnode : public exp_astnode
{
private:
	string op_type;
	exp_astnode *left_ptr, *right_ptr;

public:
	op_binary_astnode(std::string op_type, exp_astnode *left_ptr, exp_astnode *right_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	;
	;
};

class op_unary_astnode : public exp_astnode
{
private:
	string op_type;
	exp_astnode *child_ptr;

public:
	op_unary_astnode(std::string op_type, exp_astnode *child_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	void get_address(stack<string> &rstack);
	;
	;
};

class assignE_astnode : public exp_astnode
{
private:
public:
	exp_astnode *left_ptr, *right_ptr;
	assignE_astnode(exp_astnode *left_ptr, exp_astnode *right_ptr);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	;
	;
};

class funcall_astnode : public exp_astnode
{
private:
	identifier_astnode *fname;
	vector<exp_astnode *> *seq_exp_ptr;
	string return_type;
	vector<bool> ref;

public:
	funcall_astnode(identifier_astnode *fname);
	funcall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr, string return_type, vector<bool> ref);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	;
	;
};

class intconst_astnode : public exp_astnode
{
private:
	int int_val;

public:
	intconst_astnode(int int_val);
	void print(int blanks);
	void generate_code(stack<string> &rstack, bool boolean);
	;
	;
};
