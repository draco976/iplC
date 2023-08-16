%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}

%define parse.trace

%code requires{
   namespace IPL {
      class Scanner;
   }
   #include "ast.hh"
   #include "symtab.hh"
   #include "location.hh"

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%printer { std::cerr << $$; }  STRING_LITERAL
%printer { std::cerr << $$; }  OR_OP
%printer { std::cerr << $$; }  AND_OP 
%printer { std::cerr << $$; }  EQ_OP 
%printer { std::cerr << $$; }  NE_OP
%printer { std::cerr << $$; }  LE_OP 
%printer { std::cerr << $$; }  GE_OP
%printer { std::cerr << $$; }  INC_OP
%printer { std::cerr << $$; }  PTR_OP
%printer { std::cerr << $$; }  MAIN
%printer { std::cerr << $$; }  PRINTF
%printer { std::cerr << $$; }  STRUCT
%printer { std::cerr << $$; }  VOID
%printer { std::cerr << $$; }  INT
%printer { std::cerr << $$; }  FLOAT
%printer { std::cerr << $$; }  RETURN
%printer { std::cerr << $$; }  IF
%printer { std::cerr << $$; }  ELSE
%printer { std::cerr << $$; }  FOR
%printer { std::cerr << $$; }  WHILE
%printer { std::cerr << $$; }  INT_CONSTANT
%printer { std::cerr << $$; }  FLOAT_CONSTANT
%printer { std::cerr << $$; }  IDENTIFIER
%printer { std::cerr << $$; }  OTHERS


%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   #include <map>
   #include <stack>

   
   
   #include "scanner.hh"
   int nodeCount = 0;
   Entry *gEntry = new Entry();
   Entry *lEntry ;
   SymbTab *lst = new SymbTab();
   SymbTab gst ;
   std::string basetype, scope, identifier, return_type ;
   int lOffset=0, gOffset=0 ;
   std::map<string, abstract_astnode*> ast;
   std::stack<std::pair<string, Entry*>> entryStack ;
   std::vector<Entry*> param_list ;
   std::string struct_name ;
   std::string func_name ;

   std::vector<string> stringList ;

   extern std::stack<string> rstack ;
   extern void gen_code(string code) ;
   extern int get_size(string struct_type);
   extern string get_addr(string identifier) ;
   extern int get_offset2(string struct_type, string member_id, string struct_id);
   extern string get_addr2(string struct_type, string member_id, string struct_id);
   extern string gen_label() ;
   extern void backpatch(vector<int> list, string label) ;
   extern int AR_top ;


   int LFnCalculate(int Lfn1, int Lfn2) {
        if (Lfn1 == Lfn2) {
             return Lfn1+1;
        }
        else {
             return max(Lfn1, Lfn2) ;
        }
   }

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}


%define api.value.type variant
%define parse.assert

%start program



%token '\n'
%token <std::string> STRING_LITERAL
%token <std::string> OR_OP
%token <std::string> AND_OP 
%token <std::string> EQ_OP 
%token <std::string> NE_OP
%token <std::string> LE_OP 
%token <std::string> GE_OP
%token <std::string> INC_OP
%token <std::string> PTR_OP
%token <std::string> MAIN
%token <std::string> PRINTF
%token <std::string> STRUCT
%token <std::string> VOID
%token <std::string> INT
%token <std::string> FLOAT
%token <std::string> RETURN
%token <std::string> IF
%token <std::string> ELSE
%token <std::string> FOR
%token <std::string> WHILE
%token <std::string> INT_CONSTANT
%token <std::string> FLOAT_CONSTANT
%token <std::string> IDENTIFIER
%token <std::string> OTHERS
%token ';' ',' '(' ')' '{' '}' '[' ']' '<' '>' '!' '&' '*' '+' '-' '/' '=' '.'

%nterm <abstract_astnode*> program main_definition translation_unit function_definition parameter_declaration parameter_list struct_specifier 
%nterm <exp_astnode*> expression equality_expression relational_expression postfix_expression primary_expression logical_and_expression additive_expression unary_expression multiplicative_expression
%nterm <statement_astnode*> statement assignment_statement selection_statement iteration_statement compound_statement procedure_call
%nterm <printcall_astnode*> printf_call
%nterm <seq_astnode*> statement_list
%nterm <vector<exp_astnode*>*> expression_list 
%nterm <std::string> unary_operator
%nterm <assignE_astnode*> assignment_expression
%nterm <vector<string>> declarator declarator_arr
%nterm <vector<vector<string>>> declarator_list 
%nterm <std::string> type_specifier fun_declarator
%nterm <vector<Entry*>*> declaration declaration_list


%%

program:
     main_definition
          {

          }
     |
     translation_unit main_definition
          {

          }
     ;

main_definition:
     INT MAIN 
          {
               gen_code("\t.text\n\t.globl\tmain\n\t.type\tmain, @function") ;
               gen_code("main:") ;
               gen_code("\tpushl\t%ebp") ;
               gen_code("\tmovl\t%esp, %ebp") ;
               gEntry->ret_offset = -1 ;
               func_name = "main" ;

          }
          '(' ')' compound_statement
          { 
               gen_code("\t.size	main, .-main") ;
               
               gEntry->varfun = "fun" ;
               gEntry->scope = "global" ;
               gEntry->size = 0 ;
               gEntry->offset = 0 ;
               gEntry->type.push_back($1) ;
               gEntry->type_str=$1 ;
               gEntry->basetype = $1 ;
               gEntry->symbtab = lst ;
               gEntry->param_list = param_list ;
               gEntry->pointer_level = 0 ;
               gEntry->array_level = 0 ;
               ast[$2] = $6 ;
               gst.Entries.insert({$2, gEntry}) ;
               lst = new SymbTab() ;
               lOffset = 0;
               param_list.clear();
               gEntry = new Entry() ;
          }
     ;

translation_unit: 
    struct_specifier
          { 
               
          } 
     |
     function_definition
          { 
          } 
     |
     translation_unit struct_specifier
          { 
          } 
     |
     translation_unit function_definition
          { 
              
          } 
     ;
    
struct_specifier: 
     STRUCT IDENTIFIER {
          struct_name = "struct " + $2 ;
          func_name = "" ;
     } '{' declaration_list '}' ';'
          { 
               gEntry->varfun = "struct" ;
               gEntry->scope = "global" ;
               gEntry->size = 0 ;
               for (const auto entry : lst->Entries) {
                    /// change this when the ref implementation changes this to +ve
                    entry.second->offset = - entry.second->size - entry.second->offset;
                    gEntry->size += entry.second->size ;
               }
               gEntry->offset = 0 ;
               gEntry->type.push_back("-") ;
               gEntry->type_str = ("-") ;
               gEntry->symbtab = lst ;
               gst.Entries.insert({"struct "+$2, gEntry}) ;
               lst = new SymbTab() ;
               lOffset = 0;
               gEntry = new Entry() ;
          } 
     ;

function_definition: 
     type_specifier fun_declarator {
          struct_name = "" ;
          return_type = $1 ;
          gen_code("\t.text\n\t.globl\t"+$2+"\n\t.type\t"+$2+", @function") ;
          gen_code($2+":") ;
          gen_code("\tpushl\t%ebp") ;
          gen_code("\tmovl\t%esp, %ebp") ;
     } compound_statement
          { 
               if ($1 == "void") {
                    if (lst->size)
                         gen_code("\taddl\t$"+to_string(lst->size)+", %esp") ;
                    gen_code("\tpopl\t%ebp") ;
                    gen_code("\tret") ;
               }
               gen_code("\t.size	"+$2+", .-"+$2) ;
               gEntry->varfun = "fun" ;
               gEntry->scope = "global" ;
               gEntry->size = 0 ;
               gEntry->offset = 0 ;
               gEntry->type.push_back($1) ;
               gEntry->type_str=$1 ;
               gEntry->basetype = $1 ;
               gEntry->symbtab = lst ;
               gEntry->param_list = param_list ;
               gEntry->pointer_level = 0 ;
               gEntry->array_level = 0 ;
               gEntry->return_type = return_type ;
               ast[$2] = $4 ;
               gst.Entries.insert({$2, gEntry}) ;
               lst = new SymbTab() ;
               lOffset = 0;
               param_list.clear();
               gEntry = new Entry() ;
          } 
     ;

type_specifier: 
     VOID
          {
               $$ = "void" ;
               basetype = "void" ;
          } 
     | 
     INT
          { 
               $$ = "int" ;
               basetype = "int" ;
          } 
     | 
     STRUCT IDENTIFIER
          { 
               $$ = "struct "+$2 ;
               basetype = "struct "+$2 ;
          } 
     ;

fun_declarator: 
     IDENTIFIER '(' {
          lOffset = 20 ;
     }
     parameter_list ')'
          { 
               gEntry->ret_offset = lOffset ;
               func_name = $1 ;
               lOffset = 0;
               $$ = $1 ;
          }
     |
     IDENTIFIER '(' ')'
          { 
               gEntry->ret_offset = 04 ;
               lOffset = 0;
               func_name = $1 ;
               $$ = $1 ;
          }
     ;

parameter_list: 
     parameter_declaration
          { 
          }
     | 
     parameter_list ',' parameter_declaration
          { 
          }
     ;

parameter_declaration: 
     type_specifier declarator
          { 
               // if($1=="void" && lEntry->pointer_level==0){
               //      error(@$,string("Cannot declare the type of a parameter as \"void\""));
               // }
               // if($1!="int" && $1!="float" && $1!="void" && $1!="string" && gst.Entries.find($1)==gst.Entries.end()){
               //      error(@$,string("\"")+$1+string("\" is not defined"));
               // }
               lEntry->setSize() ;
               lEntry->scope = "param" ;
               lEntry->offset = lOffset ;
               lOffset += lEntry->size ; 
               lst->Entries.insert({identifier, lEntry}) ;
               param_list.push_back(lEntry) ;
          }
     ;

declarator_arr: 
    IDENTIFIER
         { 

               if(lst->Entries.find($1)!=lst->Entries.end()){
                    error(@$,string("\"")+$1+string("\" has a previous declaration"));
               }
               lEntry = new Entry() ;
               lEntry->type.push_back(basetype) ;
               lEntry->type_str = (basetype) ;
               lEntry->basetype = basetype ;
               lEntry->varfun = "var" ;
               lEntry->scope = scope ;
               lEntry->array_level = 0 ;
               lEntry->pointer_level = 0 ;
               identifier = $1 ;
               $$.push_back(basetype);
          }
     | 
     declarator_arr '[' INT_CONSTANT ']'
          { 
               lEntry->array_level += 1 ;
               $$ = $1;
               $$.push_back($3) ;
               lEntry->array_limits.push_back(stoi($3)) ;
               
          }
     ;

declarator: 
     declarator_arr
          { 
               $$ = $1 ;
          }
     | 
     '*' declarator
          {
               lEntry->type.push_back("*");
               lEntry->type_str+="*";
               lEntry->pointer_level += 1 ;
               $$ = $2;
               $$.insert($$.begin()+1,"*");
          }
     ;

compound_statement: 
     '{' '}'
          {
               $$ = new seq_astnode() ;
          }
     | 
     '{' statement_list '}'
          { 
                $$ = $2 ;
                for (auto stmt:*$2->seq_stmt_ptr) {
                    stmt->generate_code(rstack) ;
                    if (stmt->next.size()) {
                         string label = gen_label() ;
                         backpatch(stmt->next, label) ;
                    }
               }
          }
     | '{' declaration_list
          {
               lst->getSize() ;
               gen_code("\tsubl\t$"+to_string(lst->size)+", %esp") ;
               AR_top = -lst->size ;
          } '}'
          { 
                $$ = new seq_astnode() ;
          }
     | '{' declaration_list
          {
               lst->getSize() ;
               gen_code("\tsubl\t$"+to_string(lst->size)+", %esp") ;
               AR_top = -lst->size ;
          }
           statement_list '}'
          {
               $$ = $4 ;
               for (auto stmt:*$4->seq_stmt_ptr) {
                    stmt->generate_code(rstack) ;
                    if (stmt->next.size()) {
                         string label = gen_label() ;
                         backpatch(stmt->next, label) ;
                    }
               }
          }
     ;




statement_list: 
     statement
          { 
               $$ = new seq_astnode();
               $$->seq_stmt_ptr->push_back($1) ;
          }
     | 
     statement_list statement
          { 
               $$ = $1;
               $$->seq_stmt_ptr->push_back($2) ;
          }
     ;

statement: 
     ';'
          { 
               $$ = new empty_astnode();
          }
     | 
     '{' statement_list '}'
          { 
               $$ = $2;
               // $$->next = (*$2->seq_stmt_ptr)[$2->seq_stmt_ptr->size()-1]->next ;
          }
     | 
     selection_statement
          { 
               $$ = $1;
               $$->next = $1->next ;
          }
     | 
     iteration_statement
          { 
               $$ = $1;
               $$->next = $1->next ;
          }
     | 
     assignment_statement
          { 
               $$ = $1;
               $$->next = $1->next ;
          }
     | 
     procedure_call
          { 
               $$ = $1;
          }
     | 
     printf_call
          {
               $$ = $1;
          }
     |
     RETURN expression ';'
          { 
               ///think if any other case persists, perhaps pointers
               $$ = new return_astnode($2, (func_name == "main"), lst->size) ;
          }
     ;

assignment_expression: 
     unary_expression '=' expression
          { 
               $$ = new assignE_astnode($1,$3);
               $$->basetype = $1->basetype;
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
          }
     ;


assignment_statement: 
     assignment_expression ';'
          { 
               $$ = new assignS_astnode($1->left_ptr, $1->right_ptr);
          }
     ;

procedure_call: 
     IDENTIFIER '(' ')' ';'
          { 
               vector<bool> ref ;
               if ($1 == func_name)
                    $$ = new proccall_astnode(new identifier_astnode($1),new vector<exp_astnode*>,return_type, ref);
               else 
                    $$ = new proccall_astnode(new identifier_astnode($1),new vector<exp_astnode*>,gst.Entries[$1]->return_type, ref);
          }
     | 
     IDENTIFIER '(' expression_list ')' ';'
          { 
               vector<bool> ref ;
               if ($1 == func_name) {
                    for (auto entry:param_list) {
                         if (entry->array_level>0)
                              ref.push_back(true) ;
                         else ref.push_back(false) ;
                    }
                    $$ = new proccall_astnode(new identifier_astnode($1),$3,return_type, ref);
               }
               else {
                    for (auto entry:gst.Entries[$1]->param_list) {
                         if (entry->array_level>0)
                              ref.push_back(true) ;
                         else ref.push_back(false) ;
                    }
                    $$ = new proccall_astnode(new identifier_astnode($1),$3,gst.Entries[$1]->return_type, ref);
               }
          }
     ;

printf_call:
     PRINTF '(' STRING_LITERAL ')' ';' 
          {
               stringList.push_back($3) ; 
               $$ = new printcall_astnode(new identifier_astnode($1),"$.LC"+to_string(stringList.size()-1), new vector<exp_astnode*>);
          }
     |
     PRINTF '(' STRING_LITERAL ',' expression_list ')' ';'
          {
               stringList.push_back($3) ; 
               $$ = new printcall_astnode(new identifier_astnode($1),"$.LC"+to_string(stringList.size()-1),$5);
               
          }
     ;

expression: 
     logical_and_expression
          { 
               $$ = $1;
          }
     | 
          expression OR_OP logical_and_expression
          { 
               $$ = new op_binary_astnode("OR_OP",$1,$3);
               $$->Lfn = max($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     ;

logical_and_expression: 
     equality_expression
          { 
               $$ = $1;
          }
     | 
     logical_and_expression AND_OP equality_expression
          { 
               // if($1->basetype=="string" || $3->basetype=="string"){
               //      error(@$,string("Invalid operand of &&, not scalar or pointer"));
               // }
               $$ = new op_binary_astnode("AND_OP",$1,$3);
               $$->Lfn = max($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     ;

equality_expression: 
     relational_expression
          { 
               $$ = $1;
          }
     | 
     equality_expression EQ_OP relational_expression
          { 
               $$ = new op_binary_astnode("EQ_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     | 
     equality_expression NE_OP relational_expression
          { 
               $$ = new op_binary_astnode("NE_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     ;


relational_expression: 
     additive_expression
          { 
               $$ = $1;
          }
     | 
     relational_expression '<' additive_expression
          { 
               $$ = new op_binary_astnode("LT_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     | 
     relational_expression '>' additive_expression
          { 
               $$ = new op_binary_astnode("GT_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     | 
     relational_expression LE_OP additive_expression
          { 
               $$ = new op_binary_astnode("LE_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
          }
     | 
     relational_expression GE_OP additive_expression
          { 
               $$ = new op_binary_astnode("GE_OP_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
               
          }
     ;

additive_expression: 
     multiplicative_expression
          { 
               $$ = $1;
          }
     | 
     additive_expression '+' multiplicative_expression
          { 
               $$ = new op_binary_astnode("PLUS_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    if($1->arr_level+$1->ptr_level==0 && $1->basetype=="int"){
                         $$->basetype = $3->basetype;
                         $$->ptr_level = $3->ptr_level;
                         $$->arr_level = $3->arr_level;
                         $$->adr_level = $3->adr_level;
                         $$->type_str = $3->type_str;
                         $$->type = $3->type;
                         $$->lvalue = 0;
                    }
                    else if($3->arr_level+$3->ptr_level==0 && $3->basetype=="int"){
                         $$->basetype = $1->basetype;
                         $$->ptr_level = $1->ptr_level;
                         $$->arr_level = $1->arr_level;
                         $$->adr_level = $1->adr_level;
                         $$->type_str = $1->type_str;
                         $$->type = $1->type;
                         $$->lvalue = 0;
                    }
               }
               else{
                    $$->basetype = "int";
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;

               }
          }
     | 
     additive_expression '-' multiplicative_expression
          { 
               $$ = new op_binary_astnode("MINUS_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;

               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    int correct_flag = 0;
                    if($3->arr_level+$3->ptr_level==0 && $3->basetype=="int"){
                         $$->basetype = $1->basetype;
                         $$->ptr_level = $1->ptr_level;
                         $$->arr_level = $1->arr_level;
                         $$->adr_level = $1->adr_level;
                         $$->type_str = $1->type_str;
                         $$->type = $1->type;
                         $$->lvalue = 0;
                    }
                    else if($1->type==$3->type){
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type.push_back("int");
                         $$->type_str = "int";
                         $$->lvalue = 0;
                    }
                    else if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level){
                         vector<string> temp1 = $1->type;
                         vector<string> temp2 = $3->type;
                         if ($1->adr_level==0 && $1->arr_level>0) {
                              temp1[$1->ptr_level+1] = "(*)" ;
                              if ($1->arr_level==1) {
                                   temp1[$1->ptr_level+1] = "*" ;
                              }
                         }
                         if ($3->adr_level==0 && $3->arr_level>0) {
                              temp2[$3->ptr_level+1] = "(*)" ;
                              if ($3->arr_level==1) {
                                   temp2[$3->ptr_level+1] = "*" ;
                              }
                         }
                         if(temp1 == temp2){
                              $$->basetype = "int";
                              $$->ptr_level = 0;
                              $$->arr_level = 0;
                              $$->adr_level = 0;
                              $$->type.push_back("int");
                              $$->type_str = "int";
                              $$->lvalue = 0;

                         }
                    }
               }
               else{
                    $$->basetype = "int";
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
          }
     ;

multiplicative_expression: 
     unary_expression
          { 
               $$ = $1;
          }
     | 
     multiplicative_expression '*' unary_expression
          { 
               $$ = new op_binary_astnode("MULT_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
          }
     | 
     multiplicative_expression '/' unary_expression
          { 
               $$ = new op_binary_astnode("DIV_INT",$1,$3);
               $$->Lfn = LFnCalculate($1->Lfn, $3->Lfn) ;
               $$->leaf = false ;
               $$->basetype = "int";
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
          }
     ;

unary_expression: 
     postfix_expression
          { 
               $$ = $1;
          }
     | 
     unary_operator unary_expression
          { 
               
               $$ = new op_unary_astnode($1,$2);
               $$->basetype = $2->basetype;
               
               if($1=="DEREF"){
                    $$->Lfn = max(1, $2->Lfn) ;
                    $$->leaf = false ;
                    $$->type = $2->type;
                    if ($2->adr_level == 1) {
                         $$->ptr_level = $2->ptr_level-1;
                         $$->arr_level = 0;
                         $$->type.erase($$->type.begin()+$2->ptr_level) ;
                    }
                    else {
                         if ($2->arr_level>0) {
                              $$->ptr_level = $2->ptr_level;
                              $$->arr_level = $2->arr_level-1;
                              $$->type.erase($$->type.begin()+$2->ptr_level+1) ;
                         }
                         else {
                              $$->ptr_level = $2->ptr_level-1;
                              $$->arr_level = 0;
                              $$->type.erase($$->type.begin()+$2->ptr_level) ;
                         }
                    }
                    $$->adr_level =0;
                    $$->lvalue = 1;
               }
               else if($1=="UMINUS"){
                    $$->Lfn = max(1, $2->Lfn) ;
                    $$->leaf = false ;
                    $$->type = $2->type;
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->lvalue = 0;
               }
               else if($1=="ADDRESS"){
                    $$->Lfn = max(1, $2->Lfn) ;
                    $$->leaf = false ;
                    $$->by_ref = true;
                    $$->adr_level = 1 ;
                    $$->ptr_level = $2->ptr_level+1;
                    $$->arr_level = $2->arr_level;
                    $$->type = $2->type;
                    if($$->arr_level>0)
                         $$->type.insert($$->type.begin()+$$->ptr_level,"(*)");
                    else{
                         $$->type.push_back("*");
                    }
                    $$->lvalue = 0;
               }
               else if($1=="NOT"){
                    $$->Lfn = max(1, $2->Lfn) ;
                    $$->leaf = false ;
                    $$->basetype = "int";
                    $$->type.push_back("int");
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->lvalue = 0;
               }
          }
     ;

postfix_expression: 
     primary_expression
          { 
               $$ = $1;
          }
     | 
     postfix_expression '[' expression ']'
          { 
               $$ = new arrayref_astnode($1,$3,$1->name_str, $1->basetype);

               $$->Lfn = max($1->Lfn, $3->Lfn);
               $$->leaf = false ;
               $$->basetype = $1->basetype ;
               $$->type = $1->type;
               if ($1->adr_level == 1) {
                    $$->ptr_level = $1->ptr_level-1;
                    $$->arr_level = 0;
                    $$->type.erase($$->type.begin()+$1->ptr_level) ;
               }
               else {
                    if ($1->arr_level>0) {
                         $$->ptr_level = $1->ptr_level;
                         $$->arr_level = $1->arr_level-1;
                         $$->type.erase($$->type.begin()+$1->ptr_level+1) ;
                    }
                    else {
                         $$->ptr_level = $1->ptr_level-1;
                         $$->arr_level = 0;
                         $$->type.erase($$->type.begin()+$1->ptr_level) ;
                    }
               }
               $$->adr_level =0;
               $$->lvalue = 1;

               $$->type_str = "";
               for(auto x:$$->type){
                    $$->type_str+=x;
               } 
          }
     | 
     IDENTIFIER '(' ')'
          { 
               vector<bool> ref ;
               if ($1 == func_name) {
                    $$ = new funcall_astnode(new identifier_astnode($1),new vector<exp_astnode*>, return_type, ref);
                    $$->Lfn = 1 ;
                    $$->basetype = return_type ;
                    $$->type.push_back(return_type) ;
                    $$->type_str = return_type ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
               else {
                    $$ = new funcall_astnode(new identifier_astnode($1),new vector<exp_astnode*>, gst.Entries[$1]->return_type, ref);
                    $$->Lfn = 1 ;
                    $$->basetype = gst.Entries[$1]->basetype ;
                    $$->type = gst.Entries[$1]->type ;
                    $$->type_str = gst.Entries[$1]->type_str ;
                    $$->ptr_level = gst.Entries[$1]->pointer_level ;
                    $$->arr_level = gst.Entries[$1]->array_level ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;   
               }
          }
     | 
     IDENTIFIER '(' expression_list ')'
          { 
               vector<bool> ref ;
               if ($1 == func_name) {
                    for (auto entry:param_list) {
                         if (entry->array_level>0)
                              ref.push_back(true) ;
                         else ref.push_back(false) ;
                    }
                    $$ = new funcall_astnode(new identifier_astnode($1),$3, return_type, ref);
                    $$->Lfn = 1 ;
                    for (auto exp:*$3) {
                         $$->Lfn = max($$->Lfn, exp->Lfn) ;
                    }
                    $$->basetype = return_type ;
                    $$->type.push_back(return_type) ;
                    $$->type_str = return_type ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
               else {
                    for (auto entry:gst.Entries[$1]->param_list) {
                         if (entry->array_level>0)
                              ref.push_back(true) ;
                         else ref.push_back(false) ;
                    }
                    $$ = new funcall_astnode(new identifier_astnode($1),$3, gst.Entries[$1]->return_type, ref);
                    $$->Lfn = 1 ;
                    for (auto exp:*$3) {
                         $$->Lfn = max($$->Lfn, exp->Lfn) ;
                    }
                    $$->basetype = gst.Entries[$1]->basetype ;
                    $$->type = gst.Entries[$1]->type ;
                    $$->type_str = gst.Entries[$1]->type_str ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               
               
               
               
               }
               $$->lvalue = 0;
          }
     | 
     postfix_expression '.' IDENTIFIER
          { 
               ///handle existance,  basetype, ptr and arr levels
               // if ($1->ptr_level == 0 && $1->arr_level == 0 && gst.Entries.count($1->basetype) && gst.Entries[$1->basetype]->varfun == "struct") {
               //      if (gst.Entries[$1->basetype]->symbtab->Entries.count($3)) {
                         $$ = new member_astnode($1,new identifier_astnode($3),$1->name_str);
                         $$->basetype = gst.Entries[$1->basetype]->symbtab->Entries[$3]->basetype;
                         $$->type = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type;
                         $$->type_str = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type_str;
                         $$->ptr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->pointer_level;
                         $$->arr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->array_level;
                         $$->adr_level = 0;
                         $$->lvalue = 1;
                         $$->Lfn = $1->Lfn;
                         $$->leaf = true ;
                         $$->addr = get_addr2($1->basetype,$3,$1->name_str) ;
                         // cout<<$$->addr<<$1->name_str<<$3<<endl;
               //      }
               //      else {
               //           error(@$, string("Struct \"") + $1->basetype + string("\" has no member named \"" + $3 + "\"")) ;
               //      }
               // }
               // else {
               //      error(@$,string("Left operand of \".\" is not a structure"));
               // }
          }
     | 
     postfix_expression PTR_OP IDENTIFIER
          { 
               ///handle existance, basetype, ptr and arr levels
               ///perhaps also something about lval
               // if ($1->ptr_level + $1->arr_level == 1 && gst.Entries.count($1->basetype) && gst.Entries[$1->basetype]->varfun == "struct") {
               //      if (gst.Entries[$1->basetype]->symbtab->Entries.count($3)) {
                         $$ = new arrow_astnode($1,new identifier_astnode($3));
                         $$->basetype = gst.Entries[$1->basetype]->symbtab->Entries[$3]->basetype;
                         $$->type = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type;
                         $$->type_str = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type_str;
                         $$->ptr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->pointer_level;
                         $$->arr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->array_level;
                         $$->adr_level = 0;
                         $$->lvalue = 1;
                         $$->Lfn = $1->Lfn;
                         $$->leaf = false ;
                         $$->addr = get_addr($1->name_str) ;
                         // cout<<$1->name_str<<$$->addr<<endl;

               //      }
               //      else {
               //           error(@$, string("Struct \"") + $1->basetype + string("\" has no member named \"" + $3 + "\"")) ;
               //      }
               // }
               // else {
               //      error(@$,string("Left operand of \"->\" is not a pointer to structure"));
               // }

          }
     | 
     postfix_expression INC_OP
          { 
               $$ = new op_unary_astnode("INC_OP",$1);
               $$->basetype = $1->basetype;
               $$->type = $1->type;
               $$->type_str = $1->type_str;
               $$->ptr_level = $1->ptr_level;
               $$->arr_level = $1->arr_level;
               $$->adr_level = $1->adr_level;
               $$->lvalue = 0;
               $$->Lfn = $1->Lfn ;
          }
     ;

primary_expression: 
     IDENTIFIER
          { 
               $$ = new identifier_astnode($1);
               $$->Lfn = 1 ;
               $$->leaf = true ;
               $$->addr = get_addr($1) ;
               $$->name_str = $1;
               if(lst->Entries.find($1)!=lst->Entries.end()){
                    $$->basetype = lst->Entries[$1]->basetype;
                    $$->type = lst->Entries[$1]->type;
                    $$->type_str = lst->Entries[$1]->type_str;
                    $$->ptr_level = lst->Entries[$1]->pointer_level;
                    $$->arr_level = lst->Entries[$1]->array_level;
                    $$->adr_level = 0;
                    $$->lvalue = 1;
               }
          }
     | 
     INT_CONSTANT
          { 
               $$ = new intconst_astnode(stoi($1));
               $$->basetype = "int";
               $$->type.push_back("int");
               $$->type_str = "int";
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->lvalue = 0;
               if(stoi($1)==0){
                    $$->null_ptr = 1;
               }
               $$->Lfn = 1 ;
               $$->leaf = true ;
               $$->addr = "$"+$1 ;
          }
     | 
     '(' expression ')'
          { 
               $$ = $2 ;
          }
     ;

expression_list: 
     expression
          { 
               $$ = new vector<exp_astnode*>;
               $$->push_back($1);
          }
     | 
     expression_list ',' expression
          { 
               $$ = $1;
               $$->push_back($3);
          }
     ;

unary_operator:
     '-'
          { 
               $$ = "UMINUS";
          }
     | 
     '!'
          { 
               $$ = "NOT";
          }
     | 
     '&'
          { 
               $$ = "ADDRESS";
          }    
     | 
     '*'
          { 
               $$ = "DEREF";
          }
     ;

selection_statement: 
     IF '(' expression ')' statement ELSE statement
          { 
               $$ = new if_astnode($3,$5,$7);

          }
     ;

iteration_statement: 
     WHILE '(' expression ')' statement
          { 
               $$ = new while_astnode($3,$5);

          }
     | 
     FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
          { 
               $$ = new for_astnode($3,$5,$7,$9);
               

               
          }
     ;

declaration_list: 
     declaration
          { 
          }
     | 
     declaration_list declaration
          { 
               ///need to handle repeated declarations
          }
     ;


declaration: 
     type_specifier declarator_list ';'
          { 
               // if($1=="void"){
               //      for(auto x:$2){
               //           if(x.size()==1 || x[1]!="*")
               //                error(@$,string("Cannot declare variable of type \"void\""));
               //      }
               // }
               // // Case of pointer to a struct within the same struct
               // if($1!=struct_name && $1!="int" && $1!="float" && $1!="void" && $1!="string" && gst.Entries.find($1)==gst.Entries.end()){
               //      cout<<"AHAHAHAH"<<endl;
               //      error(@$,string("\"")+$1+string("\" is not defined"));
               // }
          }
     ;


declarator_list: 
     declarator
          {
               
               lEntry->setSize() ;
               lEntry->offset = lOffset-lEntry->size ;
               lEntry->scope = "local" ;
               lOffset -= lEntry->size ;
               // if (lEntry->basetype == struct_name && lEntry->array_level + lEntry->pointer_level == 0) {
               //      error(@$,string("\"")+lEntry->basetype+string("\" is not defined"));
               // }
               lst->Entries.insert({identifier, lEntry}) ;
               $$.push_back($1);
          }
     | 
     declarator_list ',' declarator
          { 
               ///need to handle repeated declarations
               lEntry->setSize() ;
               lEntry->offset = lOffset-lEntry->size ;
               lEntry->scope = "local" ;
               lOffset -= lEntry->size ;
               lst->Entries.insert({identifier, lEntry}) ;
               $$ = $1;
               $$.push_back($3);
          }
     ;








%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cout << "Error at line " << l.begin.line << ": " << err_message  << "\n";
   exit(1);
}


