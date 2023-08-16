#include "ast.hh"
#include <fstream>
#include <cstdarg>
#include <iostream>
#include <map>
#include <iterator>
#include <vector>

using namespace std;

void printAst(const char *astname, const char *fmt...) // fmt is a format string that tells about the type of the arguments.
{
    typedef vector<abstract_astnode *> *pv;
    va_list args;
    va_start(args, fmt);
    if ((astname != NULL) && (astname[0] != '\0'))
    {
        cout << "{ ";
        cout << "\"" << astname << "\""
             << ": ";
    }
    cout << "{" << endl;
    while (*fmt != '\0')
    {
        if (*fmt == 'a')
        {
            char *field = va_arg(args, char *);
            abstract_astnode *a = va_arg(args, abstract_astnode *);
            cout << "\"" << field << "\": " << endl;

            a->print(0);
        }
        else if (*fmt == 's')
        {
            char *field = va_arg(args, char *);
            char *str = va_arg(args, char *);
            cout << "\"" << field << "\": ";

            cout << str << endl;
        }
        else if (*fmt == 'i')
        {
            char *field = va_arg(args, char *);
            int i = va_arg(args, int);
            cout << "\"" << field << "\": ";

            cout << i;
        }
        else if (*fmt == 'f')
        {
            char *field = va_arg(args, char *);
            double f = va_arg(args, double);
            cout << "\"" << field << "\": ";
            cout << f;
        }
        else if (*fmt == 'l')
        {
            char *field = va_arg(args, char *);
            pv f = va_arg(args, pv);
            cout << "\"" << field << "\": ";
            cout << "[" << endl;
            for (int i = 0; i < (int)f->size(); ++i)
            {
                (*f)[i]->print(0);
                if (i < (int)f->size() - 1)
                    cout << "," << endl;
                else
                    cout << endl;
            }
            cout << endl;
            cout << "]" << endl;
        }
        ++fmt;
        if (*fmt != '\0')
            cout << "," << endl;
    }
    cout << "}" << endl;
    if ((astname != NULL) && (astname[0] != '\0'))
        cout << "}" << endl;
    va_end(args);
}

// void statement_astnode::print(int blanks)
// {
//     ;
// }

// void exp_astnode::print(int blanks)
// {
//     ;
// }

// void ref_astnode::print(int blanks)
// {
//     ;
// }

void empty_astnode::print(int blanks)
{
    cout << "\"empty\"";
}

void seq_astnode::print(int blanks)
{
    printAst(NULL, "l", "seq", seq_stmt_ptr);
}

seq_astnode::seq_astnode()
{
    this->seq_stmt_ptr = new vector<statement_astnode *>;
}

void assignS_astnode::print(int blanks)
{
    printAst("assignS", "aa",
             "left", left_ptr,
             "right", right_ptr);
}

assignS_astnode::assignS_astnode(exp_astnode *left_ptr, exp_astnode *right_ptr)
{
    this->left_ptr = left_ptr;
    this->right_ptr = right_ptr;
}

void return_astnode::print(int blanks)
{
    printAst(NULL, "a", "return", exp_ptr);
}

return_astnode::return_astnode(exp_astnode *exp_ptr)
{
    this->exp_ptr = exp_ptr;
}

void if_astnode::print(int blanks)
{
    printAst("if", "aaa",
             "cond", cond_ptr,
             "then", then_ptr,
             "else", else_ptr);
}

if_astnode::if_astnode(exp_astnode *cond_ptr, statement_astnode *then_ptr, statement_astnode *else_ptr)
{
    this->cond_ptr = cond_ptr;
    this->then_ptr = then_ptr;
    this->else_ptr = else_ptr;
}

void while_astnode::print(int blanks)
{
    printAst("while", "aa",
             "cond", cond_ptr,
             "stmt", stmt_ptr);
}

while_astnode::while_astnode(exp_astnode *cond_ptr, statement_astnode *stmt_ptr)
{
    this->cond_ptr = cond_ptr;
    this->stmt_ptr = stmt_ptr;
}

void for_astnode::print(int blanks)
{
    printAst("for", "aaaa",
             "init", init_ptr,
             "guard", guard_ptr,
             "step", step_ptr,
             "body", body);
}

for_astnode::for_astnode(exp_astnode *init_ptr, exp_astnode *guard_ptr, exp_astnode *step_ptr, statement_astnode *body)
{
    this->init_ptr = init_ptr;
    this->guard_ptr = guard_ptr;
    this->step_ptr = step_ptr;
    this->body = body;
}

void proccall_astnode::print(int blanks)
{
    printAst("proccall", "al",
             "fname", fname,
             "params", seq_exp_ptr);
}

proccall_astnode::proccall_astnode(identifier_astnode *fname)
{
    this->fname = fname;
    this->seq_exp_ptr = NULL;
}

proccall_astnode::proccall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr)
{
    this->fname = fname;
    this->seq_exp_ptr = seq_exp_ptr;
}

void identifier_astnode::print(int blanks)
{
    printAst(NULL, "s", "identifier", ("\"" + name_str + "\"").c_str());
}

identifier_astnode::identifier_astnode(string name_str)
{
    this->name_str = name_str;
}

void arrayref_astnode::print(int blanks)
{
    printAst("arrayref", "aa",
             "array", array_ptr1,
             "index", array_ptr2);
}

arrayref_astnode::arrayref_astnode(exp_astnode *array_ptr1, exp_astnode *array_ptr2)
{
    this->array_ptr1 = array_ptr1;
    this->array_ptr2 = array_ptr2;
}

void member_astnode::print(int blanks)
{
    printAst("member", "aa",
             "struct", member_ptr,
             "field", id_ptr);
}

member_astnode::member_astnode(exp_astnode *member_ptr, identifier_astnode *id_ptr)
{
    this->member_ptr = member_ptr;
    this->id_ptr = id_ptr;
}

void arrow_astnode::print(int blanks)
{
    printAst("arrow", "aa",
             "pointer", arrow_ptr,
             "field", id_ptr);
}

arrow_astnode::arrow_astnode(exp_astnode *arrow_ptr, identifier_astnode *id_ptr)
{
    this->arrow_ptr = arrow_ptr;
    this->id_ptr = id_ptr;
}

void op_binary_astnode::print(int blanks)
{
    printAst("op_binary", "saa",
             "op", ("\"" + op_type + "\"").c_str(),
             "left", left_ptr,
             "right", right_ptr);
}

op_binary_astnode::op_binary_astnode(string op_type, exp_astnode *left_ptr, exp_astnode *right_ptr)
{
    this->op_type = op_type;
    this->left_ptr = left_ptr;
    this->right_ptr = right_ptr;
}

void op_unary_astnode::print(int blanks)
{
    printAst("op_unary", "sa",
             "op", ("\"" + op_type + "\"").c_str(),
             "child", child_ptr);
}

op_unary_astnode::op_unary_astnode(string op_type, exp_astnode *child_ptr)
{
    this->op_type = op_type;
    this->child_ptr = child_ptr;
}

void assignE_astnode::print(int blanks)
{
    printAst("assignE", "aa",
             "left", left_ptr,
             "right", right_ptr);
}

assignE_astnode::assignE_astnode(exp_astnode *left_ptr, exp_astnode *right_ptr)
{
    this->left_ptr = left_ptr;
    this->right_ptr = right_ptr;
}

void funcall_astnode::print(int blanks)
{
    printAst("funcall", "al",
             "fname", fname,
             "params", seq_exp_ptr);
}

funcall_astnode::funcall_astnode(identifier_astnode *fname)
{
    this->fname = fname;
    this->seq_exp_ptr = nullptr;
}

funcall_astnode::funcall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr)
{
    this->fname = fname;
    this->seq_exp_ptr = seq_exp_ptr;
}

void intconst_astnode::print(int blanks)
{
    printAst(NULL, "i", "intconst", int_val);
}

intconst_astnode::intconst_astnode(int int_val)
{
    this->int_val = int_val;
}

void floatconst_astnode::print(int blanks)
{
    printAst(NULL, "f", "floatconst", float_val);
}

floatconst_astnode::floatconst_astnode(float float_val)
{
    this->float_val = float_val;
}

void stringconst_astnode::print(int blanks)
{
    printAst(NULL, "s", "stringconst", string_val.c_str());
}

stringconst_astnode::stringconst_astnode(string string_val)
{
    this->string_val = string_val;
}