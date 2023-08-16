#include "ast.hh"
#include <fstream>
#include <cstdarg>
#include <iostream>
#include <map>
#include <iterator>
#include <vector>
#include <string>

using namespace std;

extern void gen_code(string code);
extern void swap(stack<string> &stack);
extern string gen_temp();
extern void del_temp();
extern int get_size(string struct_type);
extern string get_addr(string identifier);
extern Entry *get_entry(string identifier);
extern Entry *get_struct_entry(string struct_name, string identifier);
extern string get_addr2(string struct_type, string member_id, string struct_id);
extern int get_offset2(string struct_type, string member_id, string struct_id);
extern string get_member_offset(string struct_type, string member_id);
extern int num_reg;
extern string gen_label();
extern int nextInstr();
extern void backpatch(vector<int> list, string label);
extern vector<int> merge(vector<int> list1, vector<int> list2);
extern int AR_top;

int param_addr = 0;

int level_increment(int adr_level, int ptr_level, int arr_level, vector<int> array_limit, int base_size)
{
    if (adr_level > 0)
    {
        int res = base_size;
        for (int i = 0; i < array_limit.size(); i++)
        {
            res *= array_limit[i];
        }
        return res;
    }
    if (arr_level + ptr_level == 0)
    {
        return 1;
    }
    else
    {
        int res = base_size;
        for (int i = 1; i < array_limit.size(); i++)
        {
            res *= array_limit[i];
        }
        return res;
    }
}

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

void statement_astnode::generate_code(stack<string> &rstack)
{
}

void exp_astnode::generate_code(stack<string> &rstack, bool boolean)
{
}

void exp_astnode::get_address(stack<string> &rstack)
{
}

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

void seq_astnode::generate_code(stack<string> &rstack)
{
    for (auto stmt : *seq_stmt_ptr)
    {
        stmt->generate_code(rstack);
        if (stmt->next.size())
        {
            string label = gen_label();
            backpatch(stmt->next, label);
            ;
        }
    }
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

void assignS_astnode::generate_code(stack<string> &rstack)
{
    right_ptr->generate_code(rstack, 0);
    gen_code("\tmovl\t" + rstack.top() + ", %esi");
    left_ptr->get_address(rstack);
    if (left_ptr->leaf && left_ptr->ptr_level > 0 && left_ptr->is_param)
    {
        param_addr = 1;
        left_ptr->get_address(rstack);
        param_addr = 0;
    }
    gen_code("\tmovl\t%esi, 0(" + rstack.top() + ")");

    // left_ptr->is_lhs = true;
    // if (left_ptr->leaf && rstack.size() > 1)
    // {
    //     right_ptr->generate_code(rstack, 0);
    //     string reg = rstack.top();
    //     rstack.pop();
    //     gen_code("\tmovl\t" + reg + ", " + left_ptr->addr);
    //     rstack.push(reg);
    // }
    // else if (rstack.size() > 1)
    // {
    //     right_ptr->generate_code(rstack, 0);
    //     string reg = rstack.top();
    //     rstack.pop();
    //     left_ptr->generate_code(rstack, 0);
    //     gen_code("\tmovl\t" + reg + ", " + left_ptr->addr);
    //     rstack.push(reg);
    // }
    // else
    // {
    //     right_ptr->generate_code(rstack, 0);
    //     string temp = gen_temp();
    //     gen_code("\tmovl\t" + right_ptr->addr + ", " + temp);
    //     left_ptr->generate_code(rstack, 0);
    //     gen_code("\tmovl\t" + temp + ", " + left_ptr->addr);
    //     del_temp();
    // }
}

void return_astnode::print(int blanks)
{
    printAst(NULL, "a", "return", exp_ptr);
}

return_astnode::return_astnode(exp_astnode *exp_ptr, bool main, int lst_size)
{
    this->exp_ptr = exp_ptr;
    this->main = main;
    this->lst_size = lst_size;
}

void return_astnode::generate_code(stack<string> &rstack)
{
    if (main)
    {
        gen_code("\tmovl\t$0, %eax");
        gen_code("\tleave");
        gen_code("\tret");
        return;
    }
    exp_ptr->generate_code(rstack, 0);
    gen_code("\tmovl\t" + rstack.top() + ", %ebx");
    if (lst_size)
        gen_code("\taddl\t$" + to_string(lst_size) + ", %esp");
    gen_code("\tpopl\t%ebp");
    gen_code("\tret");
    // gen_code("\tmovl\t"+rstack.top()+", "+to_string(ret_offset)+"(%ebp)") ;
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

void if_astnode::generate_code(stack<string> &rstack)
{
    cond_ptr->generate_code(rstack, 1);
    string label1 = gen_label();
    then_ptr->generate_code(rstack);
    int next_instr = nextInstr();
    gen_code("\tjmp\t");
    string label2 = gen_label();
    else_ptr->generate_code(rstack);
    backpatch(cond_ptr->truelist, label1);
    backpatch(cond_ptr->falselist, label2);
    next = merge(then_ptr->next, else_ptr->next);
    next.push_back(next_instr);
};

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

void while_astnode::generate_code(stack<string> &rstack)
{
    string label1 = gen_label();
    cond_ptr->generate_code(rstack, 1);
    string label2 = gen_label();
    stmt_ptr->generate_code(rstack);
    gen_code("\tjmp\t" + label1);
    backpatch(cond_ptr->truelist, label2);
    backpatch(stmt_ptr->next, label1);
    next = cond_ptr->falselist;
};

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

void for_astnode::generate_code(stack<string> &rstack)
{
    init_ptr->generate_code(rstack, 0);
    string label1 = gen_label();
    guard_ptr->generate_code(rstack, 1);
    string label2 = gen_label();
    body->generate_code(rstack);
    string label3 = gen_label();
    step_ptr->generate_code(rstack, 0);
    gen_code("\tjmp\t" + label1);
    backpatch(guard_ptr->truelist, label2);
    next = guard_ptr->falselist;
    backpatch(body->next, label1);
};

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

proccall_astnode::proccall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr, string return_type, vector<bool> ref)
{
    this->fname = fname;
    this->seq_exp_ptr = seq_exp_ptr;
    this->return_type = return_type;
    this->ref = ref;
}

void proccall_astnode::generate_code(stack<string> &rstack)
{
    // if (return_type == "int")
    //     gen_code("\tsubl\t$"+to_string(4)+", esp") ;
    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        // if ((*seq_exp_ptr)[i]->arr_level && !(*seq_exp_ptr)[i]->adr_level) {
        //     (*seq_exp_ptr)[i]->get_address(rstack);
        // }
        // else if (!((*seq_exp_ptr)[i]->leaf))
        (*seq_exp_ptr)[i]->generate_code(rstack, 0);
        gen_code("\tmovl\t" + rstack.top() + ", %eax");
        gen_code("\tpushl\t%eax");
        AR_top -= 4;
    }
    gen_code("\tpushl\t%edi");
    gen_code("\tpushl\t%edx");
    gen_code("\tpushl\t%ecx");

    gen_code("\tcall\t" + fname->name_str);

    gen_code("\tpopl\t%ecx");
    gen_code("\tpopl\t%edx");
    gen_code("\tpopl\t%edi");

    gen_code("\taddl\t$" + to_string(4 * (seq_exp_ptr->size())) + ", %esp");

    // if(return_type =="int")
    //     gen_code("\tpopl\t"+rstack.top()) ;

    if (return_type != "void")
        gen_code("\tmovl\t%ebx, " + rstack.top());

    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        AR_top += 4;
    }
    addr = rstack.top();
    ptr_level = 0;
    adr_level = 0;
    arr_level = 0;
}

printcall_astnode::printcall_astnode(identifier_astnode *fname, string str_loc)
{
    this->fname = fname;
    this->seq_exp_ptr = NULL;
    this->str_loc = str_loc;
}

printcall_astnode::printcall_astnode(identifier_astnode *fname, string str_loc, vector<exp_astnode *> *seq_exp_ptr)
{
    this->fname = fname;
    this->str_loc = str_loc;
    this->seq_exp_ptr = seq_exp_ptr;
}

void printcall_astnode::generate_code(stack<string> &rstack)
{
    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        if (!((*seq_exp_ptr)[i]->leaf))
            (*seq_exp_ptr)[i]->generate_code(rstack, 0);
        gen_code("\tmovl\t" + (*seq_exp_ptr)[i]->addr + ", %eax");
        gen_code("\tpushl\t%eax");
        AR_top -= 4;
    }
    gen_code("\tpushl\t" + str_loc);
    gen_code("\tcall\tprintf");
    gen_code("\taddl\t$" + to_string(4 * (seq_exp_ptr->size() + 1)) + ", %esp");

    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        AR_top += 4;
    }
}

void printcall_astnode::print(int blanks)
{
}

void identifier_astnode::print(int blanks)
{
    printAst(NULL, "s", "identifier", ("\"" + name_str + "\"").c_str());
}

identifier_astnode::identifier_astnode(string name_str)
{
    this->name_str = name_str;
}

void identifier_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    Entry *entry = get_entry(name_str);

    if (boolean)
    {
        gen_code("\tcmpl\t$0, " + get_addr(name_str));
        truelist.push_back(nextInstr());
        gen_code("\tjne\t");
        falselist.push_back(nextInstr());
        gen_code("\tjmp\t");
    }
    else
    {
        if (entry->array_level > 0)
        {
            gen_code("\tleal\t" + get_addr(name_str) + ", " + rstack.top());
        }
        else
            gen_code("\tmovl\t" + get_addr(name_str) + ", " + rstack.top());
    }
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    addr = rstack.top();
}

void identifier_astnode::get_address(stack<string> &rstack)
{
    Entry *entry = get_entry(name_str);
    if (!param_addr && entry->array_level + entry->pointer_level > 0 && entry->scope == "param")
    {
        // gen_code("HOHOHOH" + name_str + to_string(entry->array_level) + to_string(entry->pointer_level));
        gen_code("\tmovl\t" + get_addr(name_str) + ", " + rstack.top());
    }
    else
    {
        gen_code("\tleal\t" + get_addr(name_str) + ", " + rstack.top());
    }
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    if (entry->scope == "param")
    {
        is_param = 1;
    }
    addr = rstack.top();
}

void arrayref_astnode::print(int blanks)
{
    printAst("arrayref", "aa",
             "array", array_ptr1,
             "index", array_ptr2);
}

arrayref_astnode::arrayref_astnode(exp_astnode *array_ptr1, exp_astnode *array_ptr2, string name, string basetype)
{
    this->array_ptr1 = array_ptr1;
    this->array_ptr2 = array_ptr2;
    this->name_str = name;
    this->basetype = basetype;
}

void arrayref_astnode::generate_code(stack<string> &rstack, bool boolean)
{

    array_ptr2->generate_code(rstack, 0);
    string temp = gen_temp();
    gen_code("\tmovl\t" + rstack.top() + ", " + temp);
    array_ptr1->get_address(rstack);

    if (array_ptr1->adr_level == 1 || array_ptr1->arr_level == 0)
    {
        ptr_level = array_ptr1->ptr_level - 1;
        arr_level = array_ptr1->arr_level;
        array_limits = array_ptr1->array_limits;
    }
    else if (array_ptr1->arr_level > 0)
    {
        ptr_level = array_ptr1->ptr_level;
        arr_level = array_ptr1->arr_level - 1;
        array_limits = array_ptr1->array_limits;
        array_limits.erase(array_limits.begin());
    }
    adr_level = 0;
    int base_size = 4;
    if (basetype != "int" && ptr_level == 0)
    {
        base_size = get_size(basetype);
    }
    int inc = level_increment(array_ptr1->adr_level, array_ptr1->ptr_level, array_ptr1->arr_level, array_ptr1->array_limits, base_size);
    gen_code("\tmovl\t" + temp + ", %eax");
    del_temp();
    gen_code("\timull\t$" + to_string(inc) + ", %eax");
    gen_code("\taddl\t%eax, " + rstack.top());

    if (arr_level == 0 || adr_level)
        gen_code("\tmovl\t0(" + rstack.top() + "), " + rstack.top());

    addr = rstack.top();
}

void arrayref_astnode::get_address(stack<string> &rstack)
{

    array_ptr2->generate_code(rstack, 0);
    string temp = gen_temp();
    gen_code("\tmovl\t" + rstack.top() + ", " + temp);
    array_ptr1->get_address(rstack);

    if (array_ptr1->adr_level == 1 || array_ptr1->arr_level == 0)
    {
        ptr_level = array_ptr1->ptr_level - 1;
        arr_level = array_ptr1->arr_level;
        array_limits = array_ptr1->array_limits;
    }
    else if (array_ptr1->arr_level > 0)
    {
        ptr_level = array_ptr1->ptr_level;
        arr_level = array_ptr1->arr_level - 1;
        array_limits = array_ptr1->array_limits;
        array_limits.erase(array_limits.begin());
    }
    adr_level = 0;
    int base_size = 4;
    if (basetype != "int" && ptr_level == 0)
    {
        base_size = get_size(basetype);
    }
    int inc = level_increment(array_ptr1->adr_level, array_ptr1->ptr_level, array_ptr1->arr_level, array_ptr1->array_limits, base_size);
    gen_code("\tmovl\t" + temp + ", %eax");
    del_temp();
    gen_code("\timull\t$" + to_string(inc) + ", %eax");
    gen_code("\taddl\t%eax, " + rstack.top());

    addr = rstack.top();
}

void member_astnode::print(int blanks)
{
    printAst("member", "aa",
             "struct", member_ptr,
             "field", id_ptr);
}

member_astnode::member_astnode(exp_astnode *member_ptr, identifier_astnode *id_ptr, string name)
{
    this->member_ptr = member_ptr;
    this->id_ptr = id_ptr;
    this->name_str = name;
}

void member_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    ///gencode for memberptr
    member_ptr->generate_code(rstack, 0);
    if (boolean)
    {
        gen_code("\tcmpl\t$0, " + get_addr2(member_ptr->basetype, id_ptr->name_str, name_str));
        truelist.push_back(nextInstr());
        gen_code("\tjne\t");
        falselist.push_back(nextInstr());
        gen_code("\tjmp\t");
    }
    else
    {
        gen_code("\tmovl\t" + get_addr2(member_ptr->basetype, id_ptr->name_str, name_str) + ", " + rstack.top());
    }

    Entry *entry = get_struct_entry(member_ptr->basetype, id_ptr->name_str);
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    addr = rstack.top();
}

void member_astnode::get_address(stack<string> &rstack)
{
    ///gencode for memberptr
    member_ptr->get_address(rstack);
    // member_ptr->get_address(rstack);
    string temp = gen_temp();
    gen_code("\tmovl\t" + member_ptr->addr + ", " + temp);
    gen_code("\taddl\t$" + to_string(get_offset2(member_ptr->basetype, id_ptr->name_str, name_str)) + ", " + temp);
    gen_code("\tmovl\t" + temp + ", " + rstack.top());
    del_temp();

    Entry *entry = get_struct_entry(member_ptr->basetype, id_ptr->name_str);
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    addr = rstack.top();
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

void arrow_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    ///gencode for arrow_ptr
    arrow_ptr->generate_code(rstack, 0);
    if (boolean)
    {
        gen_code("\tcmpl\t$0, " + get_addr(arrow_ptr->name_str));
        truelist.push_back(nextInstr());
        gen_code("\tjne\t");
        falselist.push_back(nextInstr());
        gen_code("\tjmp\t");
    }
    else
    {
        gen_code("\tmovl\t" + get_addr(arrow_ptr->name_str) + ", " + rstack.top());
        gen_code("\tmovl\t" + get_member_offset(arrow_ptr->basetype, id_ptr->name_str) + "(" + rstack.top() + ")" + ", " + rstack.top());
    }

    Entry *entry = get_struct_entry(arrow_ptr->basetype, id_ptr->name_str);
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    addr = rstack.top();
}

void arrow_astnode::get_address(stack<string> &rstack)
{
    arrow_ptr->get_address(rstack);
    gen_code("\tmovl\t" + get_addr(arrow_ptr->name_str) + ", " + rstack.top());
    gen_code("\tleal\t" + get_member_offset(arrow_ptr->basetype, id_ptr->name_str) + "(" + rstack.top() + ")" + ", " + rstack.top());

    Entry *entry = get_struct_entry(arrow_ptr->basetype, id_ptr->name_str);
    ptr_level = entry->pointer_level;
    arr_level = entry->array_level;
    adr_level = 0;
    array_limits = entry->array_limits;
    addr = rstack.top();
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

void op_binary_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    string op;
    string jop;
    if (op_type == "PLUS_INT")
        op = "addl";
    else if (op_type == "MINUS_INT")
        op = "subl";
    else if (op_type == "MULT_INT")
        op = "imull";
    else if (op_type == "LT_OP_INT")
        op = "setl", jop = "jl";
    else if (op_type == "GT_OP_INT")
        op = "setg", jop = "jg";
    else if (op_type == "LE_OP_INT")
        op = "setle", jop = "jle";
    else if (op_type == "GE_OP_INT")
        op = "setge", jop = "jge";
    else if (op_type == "EQ_OP_INT")
        op = "sete", jop = "je";
    else if (op_type == "NE_OP_INT")
        op = "setne", jop = "jne";

    bool arith_op = op_type == "PLUS_INT" || op_type == "MINUS_INT" || op_type == "MULT_INT" || op_type == "DIV_INT";
    bool rel_op = op_type == "LT_OP_INT" || op_type == "GT_OP_INT" || op_type == "LE_OP_INT" || op_type == "GE_OP_INT" || op_type == "EQ_OP_INT" || op_type == "NE_OP_INT";
    bool log_op = op_type == "OR_OP" || op_type == "AND_OP";

    int inc = level_increment(left_ptr->adr_level, left_ptr->ptr_level, left_ptr->arr_level, left_ptr->array_limits, 4);
    ptr_level = 0;
    arr_level = 0;
    adr_level = 0;

    if (boolean && arith_op)
    {
        generate_code(rstack, 0);
        gen_code("\tcmpl\t$0, " + rstack.top());
        truelist.push_back(nextInstr());
        gen_code("\tjne\t");
        falselist.push_back(nextInstr());
        gen_code("\tjmp\t");
    }
    else if (op_type == "DIV_INT")
    {
        right_ptr->generate_code(rstack, 0);
        string temp = gen_temp();
        gen_code("\tmovl\t" + rstack.top() + ", " + temp);
        if (left_ptr->leaf)
        {
            gen_code("\tmovl\t" + left_ptr->addr + ", %eax");
        }
        else
        {
            left_ptr->generate_code(rstack, 0);
            gen_code("\tmovl\t" + rstack.top() + ", %eax");
        }
        gen_code("\tcltd");
        gen_code("\tidivl\t" + temp);
        del_temp();

        gen_code("\tmovl\t%eax, " + rstack.top());
    }
    else if (op_type == "OR_OP")
    {
        if (boolean)
        {
            left_ptr->generate_code(rstack, 1);
            string label1 = gen_label();
            backpatch(left_ptr->falselist, label1);
            right_ptr->generate_code(rstack, 1);
            truelist = merge(left_ptr->truelist, right_ptr->truelist);
            falselist = right_ptr->falselist;
        }
        else
        {
            left_ptr->generate_code(rstack, 1);
            string label1 = gen_label();
            backpatch(left_ptr->falselist, label1);
            right_ptr->generate_code(rstack, 1);
            string label2 = gen_label();
            gen_code("\tmovl\t$1, " + rstack.top());
            int next = nextInstr();
            gen_code("\tjmp\t");
            backpatch(merge(left_ptr->truelist, right_ptr->truelist), label2);
            string label3 = gen_label();
            gen_code("\tmovl\t$0, " + rstack.top());
            backpatch(right_ptr->falselist, label3);
            string label4 = gen_label();
            vector<int> exit;
            exit.push_back(next);
            backpatch(exit, label4);
            addr = rstack.top();
        }
    }

    else if (op_type == "AND_OP")
    {
        if (boolean)
        {
            left_ptr->generate_code(rstack, 1);
            string label1 = gen_label();
            backpatch(left_ptr->truelist, label1);
            right_ptr->generate_code(rstack, 1);
            falselist = merge(left_ptr->falselist, right_ptr->falselist);
            truelist = right_ptr->truelist;
        }
        else
        {
            left_ptr->generate_code(rstack, 1);
            string label1 = gen_label();
            backpatch(left_ptr->truelist, label1);
            right_ptr->generate_code(rstack, 1);
            string label2 = gen_label();
            gen_code("\tmovl\t$0, " + rstack.top());
            int next = nextInstr();
            gen_code("\tjmp\t");
            backpatch(merge(left_ptr->falselist, right_ptr->falselist), label2);
            string label3 = gen_label();
            gen_code("\tmovl\t$1, " + rstack.top());
            backpatch(right_ptr->truelist, label3);
            string label4 = gen_label();
            vector<int> exit;
            exit.push_back(next);
            backpatch(exit, label4);
        }
    }

    // else if (right_ptr->leaf)
    // {
    //     left_ptr->generate_code(rstack, 0);
    //     if (arith_op)
    //     {
    //         gen_code("\t" + op + "\t" + right_ptr->addr + ", " + rstack.top());
    //         ptr_level = left_ptr->ptr_level ;
    //         arr_level = left_ptr->arr_level ;
    //         adr_level = left_ptr->adr_level ;
    //         array_limits = left_ptr->array_limits ;

    //     }
    //     else if (rel_op)
    //     {
    //         gen_code("\tcmpl\t" + right_ptr->addr + ", " + rstack.top());
    //         if (boolean)
    //         {
    //             truelist.push_back(nextInstr());
    //             gen_code("\t" + jop + "\t");
    //             falselist.push_back(nextInstr());
    //             gen_code("\tjmp\t");
    //         }
    //         else
    //         {
    //             gen_code("\t" + op + "\t%al");
    //             gen_code("\tmovzbl\t%al, " + rstack.top());
    //         }
    //         addr = rstack.top() ;
    //     }
    // }
    else if (left_ptr->Lfn < right_ptr->Lfn && left_ptr->Lfn < num_reg)
    {
        swap(rstack);
        right_ptr->generate_code(rstack, 0);
        string reg = rstack.top();
        rstack.pop();
        left_ptr->generate_code(rstack, 0);
        if (arith_op)
        {
            if (inc > 1)
            {
                gen_code("\timull\t$" + to_string(inc) + ", " + reg);
            }
            gen_code("\t" + op + "\t" + reg + ", " + rstack.top());
            ptr_level = left_ptr->ptr_level;
            arr_level = left_ptr->arr_level;
            adr_level = left_ptr->adr_level;
            array_limits = left_ptr->array_limits;
        }
        else if (rel_op)
        {
            gen_code("\tcmpl\t" + reg + ", " + rstack.top());
            if (boolean)
            {
                truelist.push_back(nextInstr());
                gen_code("\t" + jop + "\t");
                falselist.push_back(nextInstr());
                gen_code("\tjmp\t");
            }
            else
            {
                gen_code("\t" + op + "\t%al");
                gen_code("\tmovzbl\t%al, " + rstack.top());
            }
        }
        rstack.push(reg);
        swap(rstack);
    }
    else if (left_ptr->Lfn >= right_ptr->Lfn && right_ptr->Lfn < num_reg)
    {
        left_ptr->generate_code(rstack, 0);
        string reg = rstack.top();
        rstack.pop();
        right_ptr->generate_code(rstack, 0);
        if (arith_op)
        {
            if (inc > 1)
            {
                gen_code("\timull\t$" + to_string(inc) + ", " + rstack.top());
            }
            gen_code("\t" + op + "\t" + rstack.top() + ", " + reg);
            ptr_level = left_ptr->ptr_level;
            arr_level = left_ptr->arr_level;
            adr_level = left_ptr->adr_level;
            array_limits = left_ptr->array_limits;
        }
        else if (rel_op)
        {
            gen_code("\tcmpl\t" + rstack.top() + ", " + reg);
            if (boolean)
            {
                truelist.push_back(nextInstr());
                gen_code("\t" + jop + "\t");
                falselist.push_back(nextInstr());
                gen_code("\tjmp\t");
            }
            else
            {
                gen_code("\t" + op + "\t%al");
                gen_code("\tmovzbl\t%al, " + reg);
            }
        }
        rstack.push(reg);
    }
    else
    {
        right_ptr->generate_code(rstack, 0);
        string temp = gen_temp();
        gen_code("\tmovl\t" + rstack.top() + ", " + temp);
        left_ptr->generate_code(rstack, 0);
        if (arith_op)
        {
            if (inc > 1)
            {
                gen_code("\timull\t$" + to_string(inc) + ", " + temp);
            }
            gen_code("\t" + op + "\t" + temp + ", " + rstack.top());
            ptr_level = left_ptr->ptr_level;
            arr_level = left_ptr->arr_level;
            adr_level = left_ptr->adr_level;
            array_limits = left_ptr->array_limits;
        }
        else if (rel_op)
        {
            gen_code("\tcmpl\t" + temp + ", " + rstack.top());
            if (boolean)
            {
                truelist.push_back(nextInstr());
                gen_code("\t" + jop + "\t");
                falselist.push_back(nextInstr());
                gen_code("\tjmp\t");
            }
            else
            {
                gen_code("\t" + op + "\t%al");
                gen_code("\tmovzbl\t%al, " + rstack.top());
            }
        }
        del_temp();
    }
    addr = rstack.top();
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

void op_unary_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    if (op_type == "UMINUS")
    {
        child_ptr->generate_code(rstack, 0);
        gen_code("\tnegl\t" + rstack.top());
        addr = rstack.top();
        ptr_level = 0;
        arr_level = 0;
        adr_level = 0;
    }
    if (op_type == "NOT")
    {
        if (boolean)
        {
            child_ptr->generate_code(rstack, 1);
            truelist = child_ptr->falselist;
            falselist = child_ptr->truelist;
        }
        else
        {
            child_ptr->generate_code(rstack, 0);
            gen_code("\tcmpl\t$0, " + rstack.top());
            gen_code("\tsete\t%al");
            gen_code("\tmovzbl\t%al, " + rstack.top());
        }
        addr = rstack.top();
        arr_level = 0;
        ptr_level = 0;
        adr_level = 0;
    }
    if (op_type == "INC_OP")
    {

        gen_code("\tmovl\t" + child_ptr->addr + ", " + rstack.top());
        int base_size = 4;
        if (basetype != "int" && ptr_level == 0)
        {
            base_size = get_size(basetype);
        }
        int inc = level_increment(child_ptr->adr_level, child_ptr->ptr_level, child_ptr->arr_level, child_ptr->array_limits, base_size);
        gen_code("\taddl\t$" + to_string(inc) + ", " + child_ptr->addr);
        addr = rstack.top();
        arr_level = child_ptr->arr_level;
        ptr_level = child_ptr->ptr_level;
        adr_level = child_ptr->adr_level;
        array_limits = child_ptr->array_limits;
    }

    if (op_type == "ADDRESS")
    {
        child_ptr->get_address(rstack);
        addr = rstack.top();

        adr_level = 1;
        ptr_level = child_ptr->ptr_level + 1;
        arr_level = child_ptr->arr_level;
        array_limits = child_ptr->array_limits;
    }

    if (op_type == "DEREF")
    {
        child_ptr->generate_code(rstack, 0);

        gen_code("\tmovl\t(" + rstack.top() + "), " + rstack.top());
        addr = rstack.top();

        if (child_ptr->adr_level == 1 || child_ptr->arr_level == 0)
        {
            ptr_level = child_ptr->ptr_level - 1;
            arr_level = child_ptr->arr_level;
            array_limits = child_ptr->array_limits;
        }
        else if (child_ptr->arr_level > 0)
        {
            ptr_level = child_ptr->ptr_level;
            arr_level = child_ptr->arr_level - 1;
            array_limits = child_ptr->array_limits;
            array_limits.erase(array_limits.begin());
        }
        adr_level = 0;
    }
}

void op_unary_astnode::get_address(stack<string> &rstack)
{
    if (op_type == "DEREF")
    {
        child_ptr->generate_code(rstack, 0);
        // gen_code("\tmovl\t" + child_ptr->addr + ", " + rstack.top());
        // gen_code("\tmovl\t(" + rstack.top() + "), " + rstack.top());
        addr = rstack.top();

        if (child_ptr->adr_level == 1 || child_ptr->arr_level == 0)
        {
            ptr_level -= 1;
            arr_level = child_ptr->arr_level;
            array_limits = child_ptr->array_limits;
        }
        else if (child_ptr->arr_level > 0)
        {
            ptr_level = child_ptr->ptr_level;
            arr_level = child_ptr->arr_level - 1;
            array_limits = child_ptr->array_limits;
            array_limits.erase(array_limits.begin());
        }
        adr_level = 0;
    }
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

void assignE_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    right_ptr->generate_code(rstack, 0);
    gen_code("\tmovl\t" + rstack.top() + ", %esi");
    left_ptr->get_address(rstack);
    if (left_ptr->leaf && left_ptr->ptr_level > 0 && left_ptr->is_param)
    {
        param_addr = 1;
        left_ptr->get_address(rstack);
        param_addr = 0;
    }
    gen_code("\tmovl\t%esi, 0(" + rstack.top() + ")");
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

funcall_astnode::funcall_astnode(identifier_astnode *fname, vector<exp_astnode *> *seq_exp_ptr, string return_type, vector<bool> ref)
{
    this->fname = fname;
    this->seq_exp_ptr = seq_exp_ptr;
    this->return_type = return_type;
    this->ref = ref;
}

void funcall_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    // if (return_type == "int")
    //     gen_code("\tsubl\t$"+to_string(4)+", esp") ;

    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        // if ((*seq_exp_ptr)[i]->arr_level && !(*seq_exp_ptr)[i]->adr_level) {
        //     (*seq_exp_ptr)[i]->get_address(rstack);
        // }
        // else if (!((*seq_exp_ptr)[i]->leaf))
        (*seq_exp_ptr)[i]->generate_code(rstack, 0);
        gen_code("\tmovl\t" + (*seq_exp_ptr)[i]->addr + ", %eax");
        gen_code("\tpushl\t%eax");
        AR_top -= 4;
    }
    gen_code("\tpushl\t%edi");
    gen_code("\tpushl\t%edx");
    gen_code("\tpushl\t%ecx");

    gen_code("\tcall\t" + fname->name_str);

    gen_code("\tpopl\t%ecx");
    gen_code("\tpopl\t%edx");
    gen_code("\tpopl\t%edi");

    gen_code("\taddl\t$" + to_string(4 * (seq_exp_ptr->size())) + ", %esp");

    // if(return_type =="int")
    //     gen_code("\tpopl\t"+rstack.top()) ;

    if (return_type != "void")
        gen_code("\tmovl\t%ebx, " + rstack.top());

    for (int i = seq_exp_ptr->size() - 1; i >= 0; i--)
    {
        AR_top += 4;
    }
    addr = rstack.top();
    ptr_level = 0;
    adr_level = 0;
    arr_level = 0;
}

void intconst_astnode::print(int blanks)
{
    printAst(NULL, "i", "intconst", int_val);
}

intconst_astnode::intconst_astnode(int int_val)
{
    this->int_val = int_val;
}

void intconst_astnode::generate_code(stack<string> &rstack, bool boolean)
{
    if (boolean)
    {
        if (int_val == 0)
        {
            falselist.push_back(nextInstr());
            gen_code("\tjmp\t");
        }
        else
        {
            truelist.push_back(nextInstr());
            gen_code("\tjmp\t");
        }
    }
    else
        gen_code("\tmovl\t$" + to_string(int_val) + ", " + rstack.top());
    addr = rstack.top();
    ptr_level = 0;
    adr_level = 0;
    arr_level = 0;
}

void stringconst_astnode::print(int blanks)
{
    printAst(NULL, "s", "stringconst", string_val.c_str());
}

stringconst_astnode::stringconst_astnode(string string_val)
{
    this->string_val = string_val;
}