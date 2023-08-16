#include <fstream>
#include <cstdarg>
#include <iostream>
#include <map>
#include <iterator>
#include <vector>

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
	vector<int> array_limits;
	virtual void print(int blanks) = 0;
};

class statement_astnode : public abstract_astnode
{
public:
	virtual void print(int blanks) = 0;
	;
	;
};

class exp_astnode : public abstract_astnode
{
public:
	int null_ptr = 0;
	virtual void print(int blanks) = 0;
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

	;
};

class assignS_astnode : public statement_astnode
{
private:
	exp_astnode *left_ptr, *right_ptr;

public:
	assignS_astnode(exp_astnode *left_ptr, exp_astnode *right_ptr);
	void print(int blanks);
	;
	;
};

class return_astnode : public statement_astnode
{
private:
	exp_astnode *exp_ptr;

public:
	return_astnode(exp_astnode *exp_ptr);
	void print(int blanks);
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
	string name_str;

public:
	identifier_astnode(string name_str);
	void print(int blanks);
	;
	;
};

class proccall_astnode : public statement_astnode
{
private:
	identifier_astnode *fname;
	vector<exp_astnode *> *seq_exp_ptr;

public:
	proccall_astnode(identifier_astnode *fname);
	// proccall_astnode(identifier_astnode *fname, vector<exp_astnode> *seq_exp_ptr);
	proccall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr);
	void print(int blanks);
	;
	;
};

class arrayref_astnode : public ref_astnode
{
private:
	exp_astnode *array_ptr1, *array_ptr2;

public:
	arrayref_astnode(exp_astnode *array_ptr1, exp_astnode *array_ptr2);
	void print(int blanks);
	;
	;
};

class member_astnode : public ref_astnode
{
private:
	exp_astnode *member_ptr;
	identifier_astnode *id_ptr;

public:
	member_astnode(exp_astnode *member_ptr, identifier_astnode *id_ptr);
	void print(int blanks);
	;
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
	;
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
	;
	;
};

class funcall_astnode : public exp_astnode
{
private:
	identifier_astnode *fname;
	vector<exp_astnode *> *seq_exp_ptr;

public:
	funcall_astnode(identifier_astnode *fname);
	funcall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr);
	void print(int blanks);
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
	;
	;
};

class floatconst_astnode : public exp_astnode
{
private:
	float float_val;

public:
	floatconst_astnode(float float_val);

	void print(int blanks);
	;
	;
};
