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
   Entry *gEntry, *lEntry ;
   SymbTab *lst = new SymbTab();
   SymbTab gst ;
   std::string basetype, scope, identifier, return_type ;
   int lOffset=0, gOffset=0 ;
   std::map<string, abstract_astnode*> ast;
   std::stack<std::pair<string, Entry*>> entryStack ;
   std::vector<Entry*> param_list ;
   std::string struct_name ;
   std::string func_name ;

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}


%define api.value.type variant
%define parse.assert

%start translation_unit



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

%nterm <abstract_astnode*> translation_unit function_definition parameter_declaration parameter_list struct_specifier 
%nterm <exp_astnode*> expression equality_expression relational_expression postfix_expression primary_expression logical_and_expression additive_expression unary_expression multiplicative_expression
%nterm <statement_astnode*> statement assignment_statement selection_statement iteration_statement compound_statement procedure_call
%nterm <seq_astnode*> statement_list
%nterm <vector<exp_astnode*>*> expression_list 
%nterm <std::string> unary_operator
%nterm <assignE_astnode*> assignment_expression
%nterm <vector<string>> declarator declarator_arr
%nterm <vector<vector<string>>> declarator_list 
%nterm <std::string> type_specifier fun_declarator
%nterm <vector<Entry*>*> declaration declaration_list


%%

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
               // printf("\"functions\": [{") ;
               // $2->print() ;
          } 
     ;
    
struct_specifier: 
     STRUCT IDENTIFIER {
          struct_name = "struct " + $2 ;
          func_name = "" ;
     } '{' declaration_list '}' ';'
          { 
               gEntry = new Entry() ;
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
          } 
     ;

function_definition: 
     type_specifier {
          struct_name = "" ;
          return_type = $1 ;
     }
          fun_declarator compound_statement
          { 
               gEntry = new Entry() ;
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
               ast[$3] = $4 ;
               gst.Entries.insert({$3, gEntry}) ;
               lst = new SymbTab() ;
               lOffset = 0;
               param_list.clear();
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
     FLOAT
          { 
               $$ = "float" ;
               basetype = "float" ;
          } 
     | 
     STRUCT IDENTIFIER
          { 
               $$ = "struct "+$2 ;
               basetype = "struct "+$2 ;
          } 
     ;

fun_declarator: 
     IDENTIFIER '(' parameter_list ')'
          { 
               lOffset = 12 ;
               while(!entryStack.empty()) {
                    pair<string, Entry*> e = entryStack.top() ;
                    param_list.push_back(e.second) ;
                    entryStack.pop() ;
                    e.second->offset  = lOffset ;
                    lOffset += e.second->size ;
                    lst->Entries.insert(e) ;
               }
               func_name = $1 ;
               lOffset = 0;
               $$ = $1 ;
          }
     |
     IDENTIFIER '(' ')'
          { 
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
               if($1=="void" && lEntry->pointer_level==0){
                    error(@$,string("Cannot declare the type of a parameter as \"void\""));
               }
               if($1!="int" && $1!="float" && $1!="void" && $1!="string" && gst.Entries.find($1)==gst.Entries.end()){
                    error(@$,string("\"")+$1+string("\" is not defined"));
               }
               lEntry->setSize() ;
               lEntry->scope = "param" ;
               std::stack<std::pair<string, Entry*>> dupStack = entryStack;
               while(!dupStack.empty()) {
                    pair<string, Entry*> e = dupStack.top() ;
                    if(identifier==e.first){
                         error(@$,string("\"")+identifier+string("\" has a previous declaration"));
                    }
                    dupStack.pop() ;
               }
               entryStack.push({identifier, lEntry}) ;
               // lst->Entries.insert({identifier, lEntry}) ;
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
               $$.push_back($3);
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
          }
     | '{' declaration_list '}'
          { 
                $$ = new seq_astnode() ;
          }
     | '{' declaration_list statement_list '}'
          {
               $$ = $3 ;
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
          }
     | 
     selection_statement
          { 
               $$ = $1;
          }
     | 
     iteration_statement
          { 
               $$ = $1;
          }
     | 
     assignment_statement
          { 
               $$ = $1;
          }
     | 
     procedure_call
          { 
               $$ = $1;
          }
     | 
     RETURN expression ';'
          { 
               ///think if any other case persists, perhaps pointers

               ///return type variable not available. Need to use globals here or something else.
               if($2->type_str!=return_type){
                    if($2->type_str=="int" && return_type=="float"){
                         op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$2);
                         $$ = new return_astnode(to_float);

                    }
                    else if($2->type_str=="float" && return_type=="int"){
                         op_unary_astnode* to_int = new op_unary_astnode("TO_INT",$2);
                         $$ = new return_astnode(to_int);
                         
                    }
                    else{
                         error(@$,string("Incompatible type \"")+$2->type_str+string("\" returned, expected \"")+return_type+string("\""));
                    }
               }
               else{
                    $$ = new return_astnode($2);
               }
          }
     ;

assignment_expression: 
     unary_expression '=' expression
          { 
               if($1->lvalue==1){
                    if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new assignE_astnode($1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_int = new op_unary_astnode("TO_INT",$3);
                              $$ = new assignE_astnode($1,to_int);
                         }
                         else if(($1->basetype==$3->basetype) && ($1->basetype!="string")){
                              $$ = new assignE_astnode($1,$3);
                         }
                         else{
                              error(@$,string("Incompatible  assignment when assigning to type \"")+$1->type_str+string("\" from type \"")+$3->type_str+string("\""));

                         }
                         
                    }
                    else if($1->basetype!="string" && $1->basetype==$3->basetype && (($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level==0 && $3->arr_level==1) || ($1->arr_level==0 && $3->arr_level==0 && $1->ptr_level==$3->ptr_level)))
                    {
                         $$ = new assignE_astnode($1,$3);
                    }
                    else if(($1->basetype=="void" && $1->ptr_level==1 && $1->arr_level==0 && $3->arr_level+$3->ptr_level>0) || ($3->basetype=="void" && $3->ptr_level==1 && $3->arr_level==0 && $1->arr_level==0 && $3->ptr_level>0))
                    {
                         $$ = new assignE_astnode($1,$3);

                    }
                    else if($1->ptr_level>0 && $3->basetype=="int" && $3->ptr_level+$3->arr_level==0 && $3->null_ptr){
                         $$ = new assignE_astnode($1,$3);
                    }
                    else
                    {
                         error(@$,string("Incompatible assignment when assigning to type \"")+$1->type_str+string("\" from type \"")+$3->type_str+string("\""));
                    }
               }
               else{
                    error(@$,string("Left operand of assignment should have an lvalue"));
               }
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
               $$ = new proccall_astnode(new identifier_astnode($1),new vector<exp_astnode*>);
               $$->lvalue = 0;
               if ($1 != "printf" && $1 != "scanf" && $1 != "mod") {
                    if (gst.Entries.count($1) && gst.Entries[$1]->varfun == "fun") {
                         if (gst.Entries[$1]->param_list.size() > 0) {
                              error(@$, string("Procedure \"" + $1 + "\" called with too few arguments")) ;
                         }
                    }
                    else if ($1 == func_name) {
                         if (param_list.size() > 0) {
                              error(@$, string("Procedure \"" + $1 + "\" called with too few arguments")) ;
                         }
                    }
                    else {
                         error(@$, string("Procedure \"" + $1 + "\" not declared")) ;
                    }
               }
          }
     | 
     IDENTIFIER '(' expression_list ')' ';'
          { 
               $$ = new proccall_astnode(new identifier_astnode($1),$3);
               ///handle existance,  basetype, ptr and arr levels

               if ($1 != "printf" && $1 != "scanf" && $1 != "mod") {
                    if ($1 == func_name || (gst.Entries.count($1) && gst.Entries[$1]->varfun == "fun")) {
                         vector<Entry*> params ;
                         if ($1 == func_name) {
                              params = param_list ;
                         }
                         else {
                              params = gst.Entries[$1]->param_list ;
                         }
                         if (params.size() > $3->size()) {
                              error(@$, string("Procedure \"" + $1 + "\" called with too few arguments")) ;
                         }
                         else if (params.size() < $3->size()) {
                              error(@$, string("Procedure \"" + $1 + "\" called with too many arguments")) ;
                         }
                         else {
                              
                              for (int i=0; i<$3->size();i++) {
                                   Entry* param = params[$3->size()-i-1] ;

                                   vector<string> temp1 ;
                                   vector<string> temp2 ;
                                   temp1 = param->type ;
                                   temp2 = (*$3)[i]->type ;
                                   if (param->array_level>0) {
                                        temp1[param->pointer_level+1] = "(*)" ;
                                        if (param->array_level==1) {
                                             temp1[param->pointer_level+1] = "*" ;
                                        }
                                   }
                                   if ((*$3)[i]->adr_level==0 && (*$3)[i]->arr_level>0) {
                                        temp2[(*$3)[i]->ptr_level+1] = "(*)" ;
                                        if ((*$3)[i]->arr_level==1) {
                                             temp2[(*$3)[i]->ptr_level+1] = "*" ;
                                        }
                                   }
                                   if(temp1 == temp2){
                                        ;
                                   }
                                   
                                   else if(param->array_level+param->pointer_level==0 && (*($3))[i]->arr_level+(*($3))[i]->ptr_level==0){
                                        ///new code handling strings
                                        if(param->basetype=="float" && (*($3))[i]->basetype=="int"){
                                             exp_astnode* child_node = (*($3))[i];
                                             op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",child_node);
                                             (*($3))[i] = to_float;

                                        }
                                        else if(param->basetype=="int" && (*($3))[i]->basetype=="float"){
                                             exp_astnode* child_node = (*($3))[i];
                                             op_unary_astnode* to_int = new op_unary_astnode("TO_INT",child_node);
                                             (*($3))[i] = to_int;
                                        }
                                        else if(param->basetype==(*($3))[i]->basetype){
                                             ;
                                        }
                                        else{
                                             error(@$,string("Expected \"")+param->type_str+string("\" but argument is of type \"")+(*($3))[i]->type_str+string("\""));
                                        }
                                        ;
                                        
                                   }
                                   else if(param->basetype!="string" && param->basetype==(*($3))[i]->basetype && ((param->array_level+param->pointer_level==(*($3))[i]->arr_level+(*($3))[i]->ptr_level && param->array_level==0 && (*($3))[i]->arr_level==1) || (param->array_level==0 && (*($3))[i]->arr_level==0 && param->pointer_level==(*($3))[i]->ptr_level)))
                                   {
                                        ;
                                   }
                                   else if((param->basetype=="void" && param->pointer_level==1 && param->array_level==0 && (*($3))[i]->arr_level+(*($3))[i]->ptr_level>0) || ((*($3))[i]->basetype=="void" && (*($3))[i]->ptr_level==1 && (*($3))[i]->arr_level==0 && param->array_level==0 && (*($3))[i]->ptr_level>0))
                                   {
                                        ;
                                   }
                                   else if(param->array_level+param->pointer_level>0 && (*($3))[i]->basetype=="int" && (*($3))[i]->ptr_level+(*($3))[i]->arr_level==0 && (*($3))[i]->null_ptr)
                                   {
                                        ;
                                   }
                                   else
                                   {
                                        error(@$,string("Expected \"")+param->type_str+string("\" but argument is of type \"")+(*($3))[i]->type_str+string("\""));
                                   }

                              }
                         }
                    }
                    else {
                         error(@$, string("Procedure \"" + $1 + "\" not declared")) ;
                    }
               }
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
               if($1->basetype=="string" || $3->basetype=="string"){
                    error(@$,string("Invalid operand of ||, not scalar or pointer"));
               }
               $$ = new op_binary_astnode("OR_OP",$1,$3);
               $$->basetype = "int";
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
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
               if($1->basetype=="string" || $3->basetype=="string"){
                    error(@$,string("Invalid operand of &&, not scalar or pointer"));
               }
               $$ = new op_binary_astnode("AND_OP",$1,$3);
               $$->basetype = "int";
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
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
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){

                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary == , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }

                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("EQ_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("EQ_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("EQ_OP_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary == , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
          }
     | 
     equality_expression NE_OP relational_expression
          { 
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){
                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary != , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("NE_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("NE_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("NE_OP_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary != , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
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
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){

                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary < , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }

                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("LT_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("LT_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("LT_OP_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary < , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
          }
     | 
     relational_expression '>' additive_expression
          { 
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){

                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary > , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }

                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("GT_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("GT_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("GT_OP_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary > , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
          }
     | 
     relational_expression LE_OP additive_expression
          { 
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){
                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary <= , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("LE_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("LE_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("LE_OP_FLOAT",$1,$3);
                         }                    $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary <= , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
          }
     | 
     relational_expression GE_OP additive_expression
          { 
               if($1->arr_level+$1->ptr_level==$3->arr_level+$3->ptr_level && $1->arr_level+$1->ptr_level>0){
                    vector<string> temp1 ;
                    vector<string> temp2 ;
                    temp1 = $1->type ;
                    temp2 = $3->type ;
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
                         $$ = new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->basetype = "int";
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->type_str = $$->basetype;
                         $$->type.push_back($$->basetype);
                         $$->lvalue = 0;
                    }
               }
               else if($1->arr_level+$1->ptr_level==0 && $3->arr_level+$3->ptr_level==0){
                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary >= , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("GE_OP_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("GE_OP_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("GE_OP_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }
               else{
                    error(@$,string("Invalid operand types for binary >= , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
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
               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    if($1->arr_level+$1->ptr_level==0 && $1->basetype=="int"){
                         $$ = new op_binary_astnode("PLUS_INT",$1,$3);
                         $$->basetype = $3->basetype;
                         $$->ptr_level = $3->ptr_level;
                         $$->arr_level = $3->arr_level;
                         $$->adr_level = $3->adr_level;
                         $$->type_str = $3->type_str;
                         $$->type = $3->type;
                         $$->lvalue = 0;
                    }
                    else if($3->arr_level+$3->ptr_level==0 && $3->basetype=="int"){
                         $$ = new op_binary_astnode("PLUS_INT",$1,$3);
                         $$->basetype = $1->basetype;
                         $$->ptr_level = $1->ptr_level;
                         $$->arr_level = $1->arr_level;
                         $$->adr_level = $1->adr_level;
                         $$->type_str = $1->type_str;
                         $$->type = $1->type;
                         $$->lvalue = 0;
                    }
                    else{
                         error(@$,string("Invalid operand types for binary + , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
               }
               else{
                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary + , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
                    if($1->basetype=="float" || $3->basetype=="float"){
                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("PLUS_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("PLUS_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("PLUS_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("PLUS_INT",$1,$3);
                         $$->basetype = "int";
                    }
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
               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    int correct_flag = 0;
                    if($3->arr_level+$3->ptr_level==0 && $3->basetype=="int"){
                         $$ = new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->basetype = $1->basetype;
                         $$->ptr_level = $1->ptr_level;
                         $$->arr_level = $1->arr_level;
                         $$->adr_level = $1->adr_level;
                         $$->type_str = $1->type_str;
                         $$->type = $1->type;
                         $$->lvalue = 0;
                    }
                    else if($1->type==$3->type){
                         $$ = new op_binary_astnode("MINUS_INT",$1,$3);
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
                              $$ = new op_binary_astnode("MINUS_INT",$1,$3);
                              $$->basetype = "int";
                              $$->ptr_level = 0;
                              $$->arr_level = 0;
                              $$->adr_level = 0;
                              $$->type.push_back("int");
                              $$->type_str = "int";
                              $$->lvalue = 0;

                         }
                         else{
                              error(@$,string("Invalid operand types for binary - , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                         }
                    }
                    else{
                         error(@$,string("Invalid operand types for binary - , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
               }
               else{

                    if($1->basetype=="string" || $3->basetype=="string"){
                         error(@$,string("Invalid operand types for binary - , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
                    }
                    if($1->basetype=="float" || $3->basetype=="float"){

                         if($1->basetype=="float" && $3->basetype=="int"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                              $$ = new op_binary_astnode("MINUS_FLOAT",$1,to_float);
                         }
                         else if($1->basetype=="int" && $3->basetype=="float"){
                              op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                              $$ = new op_binary_astnode("MINUS_FLOAT",to_float,$3);
                         }
                         else{
                              $$ = new op_binary_astnode("MINUS_FLOAT",$1,$3);
                         }
                         $$->basetype = "float";
                    }
                    else{
                         $$ = new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->basetype = "int";
                    }
                    $$->ptr_level = 0;
                    $$->arr_level = 0;
                    $$->adr_level = 0;
                    $$->type_str = $$->basetype;
                    $$->type.push_back($$->basetype);
                    $$->lvalue = 0;
               }

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
                    if($2->ptr_level+$2->arr_level==0 || ($2->ptr_level+$2->arr_level==1 && $2->basetype=="void")){
                         error(@$,string("Invalid operand type \"")+$2->type_str+string("\" of unary *"));
                    }
               
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
                    if(($2->basetype=="int" || $2->basetype=="float") && $2->arr_level==0 && $2->ptr_level==0){
                         $$->type = $2->type;
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->lvalue = 0;
                    }
                    else{
                         error(@$,string("Operand of unary - should be an int or float"));
                    }

               }
               else if($1=="ADDRESS"){
                    if($2->lvalue==1){
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
                    else{
                         error(@$,string("Operand of & should have lvalue"));
                    }

               }
               else if($1=="NOT"){
                    if($2->basetype=="int" || $2->basetype=="float")
                    {
                         $$->basetype = "int";
                         $$->type.push_back("int");
                         $$->ptr_level = 0;
                         $$->arr_level = 0;
                         $$->adr_level = 0;
                         $$->lvalue = 0;
                    }
                    else{
                         error(@$,string("Operand of NOT should be an int or float or pointer"));
                    }
               }

               $$->type_str = "";
               for(auto x:$$->type){
                    $$->type_str+=x;
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
               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    error(@$,string("Invalid operand types for binary * , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
               }
               if($1->basetype=="float" || $3->basetype=="float"){
                    if($1->basetype=="float" && $3->basetype=="int"){
                         op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                         $$ = new op_binary_astnode("MULT_FLOAT",$1,to_float);

                    }
                    else if($1->basetype=="int" && $3->basetype=="float"){
                         op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                         $$ = new op_binary_astnode("MULT_FLOAT",to_float,$3);
                    }
                    else if($1->basetype=="float" && $3->basetype=="float"){
                         $$ = new op_binary_astnode("MULT_FLOAT",$1,$3);
                    }
                    else{
                         error(@$,string("Invalid operand types for binary * , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

                    }
                    $$->basetype = "float";
               }
               else if($1->basetype=="int" && $3->basetype=="int"){
                    $$ = new op_binary_astnode("MULT_INT",$1,$3);
                    $$->basetype = "int";
               }
               else{
                    error(@$,string("Invalid operand types for binary * , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
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
               if($1->arr_level+$1->ptr_level!=0 || $3->arr_level+$3->ptr_level!=0){
                    error(@$,string("Invalid operand types for binary / , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));
               }
               if($1->basetype=="float" || $3->basetype=="float"){
                    if($1->basetype=="float" && $3->basetype=="int"){
                         op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$3);
                         $$ = new op_binary_astnode("DIV_FLOAT",$1,to_float);
                    }
                    else if($1->basetype=="int" && $3->basetype=="float"){
                         op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",$1);
                         $$ = new op_binary_astnode("DIV_FLOAT",to_float,$3);
                    }
                    else if($1->basetype=="float" && $3->basetype=="float"){
                         $$ = new op_binary_astnode("DIV_FLOAT",$1,$3);
                    }
                    else{
                         error(@$,string("Invalid operand types for binary / , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

                    }
                    $$->basetype = "float";
               }
               else if($1->basetype=="int" && $3->basetype=="int"){
                    $$ = new op_binary_astnode("DIV_INT",$1,$3);
                    $$->basetype = "int";
               }
               else{
                    error(@$,string("Invalid operand types for binary / , \"")+$1->type_str+string("\" and \"")+$3->type_str+string("\""));

               }
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->type_str = $$->basetype;
               $$->type.push_back($$->basetype);
               $$->lvalue = 0;
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
               if($3->basetype!="int" || $3->arr_level!=0 || $3->ptr_level!=0){
                    error(@$,string("Array subscript is not an integer"));
               }
               else if($1->basetype == "void" and $1->arr_level + $1->ptr_level == 1) {    
                    error(@$,string("Dereferencing void* pointer"));
               }
               $$ = new arrayref_astnode($1,$3);

               if($1->ptr_level+$1->arr_level==0){
                    error(@$,string("Subscripted value is neither array nor pointer"));
               }

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
               $$ = new funcall_astnode(new identifier_astnode($1),new vector<exp_astnode*>);
               $$->lvalue = 0;
               if ($1 != "printf" && $1 != "scanf" && $1 != "mod") {
                    if (gst.Entries.count($1) && gst.Entries[$1]->varfun == "fun") {
                         if (gst.Entries[$1]->param_list.size() > 0) {
                              error(@$, string("Function \"" + $1 + "\" called with too few arguments")) ;
                         }
                         $$->basetype = gst.Entries[$1]->basetype ;
                         $$->type = gst.Entries[$1]->type ;
                         $$->type_str = gst.Entries[$1]->type_str ;
                         $$->ptr_level = gst.Entries[$1]->pointer_level ;
                         $$->arr_level = gst.Entries[$1]->array_level ;
                         $$->adr_level = 0 ;
                         $$->lvalue = 0;   
                    }
                    else if ($1 == func_name) {
                         if (param_list.size() > 0) {
                              error(@$, string("Function \"" + $1 + "\" called with too few arguments")) ;
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
                         error(@$, string("Procedure \"" + $1 + "\" not declared")) ;
                    }
               }
               else if($1 == "printf" || $1 == "scanf") {
                    $$->basetype = "void" ;
                    $$->type.push_back("void") ;
                    $$->type_str = "void" ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
               else {
                    $$->basetype = "int" ;
                    $$->type.push_back("int") ;
                    $$->type_str = "int" ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
          }
     | 
     IDENTIFIER '(' expression_list ')'
          { 
               $$ = new funcall_astnode(new identifier_astnode($1),$3);
               $$->lvalue = 0;
               ////update this like previous
               if ($1 != "printf" && $1 != "scanf" && $1 != "mod") {
                    if ($1 == func_name || (gst.Entries.count($1) && gst.Entries[$1]->varfun == "fun")) {
                         vector<Entry*> params ;
                         if ($1 == func_name) {
                              params = param_list ;
                              $$->basetype = return_type ;
                              $$->type.push_back(return_type) ;
                              $$->type_str = return_type ;
                              $$->ptr_level = 0 ;
                              $$->arr_level = 0 ;
                              $$->adr_level = 0 ;
                              $$->lvalue = 0;
                         }
                         else {
                              params = gst.Entries[$1]->param_list ;
                              $$->basetype = gst.Entries[$1]->basetype ;
                              $$->type = gst.Entries[$1]->type ;
                              $$->type_str = gst.Entries[$1]->type_str ;
                              $$->ptr_level = 0 ;
                              $$->arr_level = 0 ;
                              $$->adr_level = 0 ;
                              $$->lvalue = 0;
                         }
                         if (params.size() > $3->size()) {
                              error(@$, string("Function \"" + $1 + "\" called with too few arguments")) ;
                         }
                         else if (params.size() < $3->size()) {
                              error(@$, string("Function \"" + $1 + "\" called with too many arguments")) ;
                         }
                         else {


                              for (int i=0; i<$3->size();i++) {
                                   Entry* param = params[$3->size()-i-1] ;

                                   vector<string> temp1 ;
                                   vector<string> temp2 ;
                                   temp1 = param->type ;
                                   temp2 = (*$3)[i]->type ;
                                   if (param->array_level>0) {
                                        temp1[param->pointer_level+1] = "(*)" ;
                                        if (param->array_level==1) {
                                             temp1[param->pointer_level+1] = "*" ;
                                        }
                                   }
                                   if ((*$3)[i]->adr_level==0 && (*$3)[i]->arr_level>0) {
                                        temp2[(*$3)[i]->ptr_level+1] = "(*)" ;
                                        if ((*$3)[i]->arr_level==1) {
                                             temp2[(*$3)[i]->ptr_level+1] = "*" ;
                                        }
                                   }
                                   if(temp1 == temp2){
                                        ;
                                   }
                                   
                                   else if(param->array_level+param->pointer_level==0 && (*($3))[i]->arr_level+(*($3))[i]->ptr_level==0){
                                        ///new code handling strings
                                        if(param->basetype=="float" && (*($3))[i]->basetype=="int"){
                                             exp_astnode* child_node = (*($3))[i];
                                             op_unary_astnode* to_float = new op_unary_astnode("TO_FLOAT",child_node);
                                             (*($3))[i] = to_float;

                                        }
                                        else if(param->basetype=="int" && (*($3))[i]->basetype=="float"){
                                             exp_astnode* child_node = (*($3))[i];
                                             op_unary_astnode* to_int = new op_unary_astnode("TO_INT",child_node);
                                             (*($3))[i] = to_int;
                                        }
                                        else if(param->basetype==(*($3))[i]->basetype){
                                             ;
                                        }
                                        else{
                                             error(@$,string("Expected \"")+param->type_str+string("\" but  argument is of type \"")+(*($3))[i]->type_str+string("\""));
                                        }
                                        ;
                                        
                                   }
                                   else if(param->basetype!="string" && param->basetype==(*($3))[i]->basetype && ((param->array_level+param->pointer_level==(*($3))[i]->arr_level+(*($3))[i]->ptr_level && param->array_level==0 && (*($3))[i]->arr_level==1) || (param->array_level==0 && (*($3))[i]->arr_level==0 && param->pointer_level==(*($3))[i]->ptr_level)))
                                   {
                                        ;
                                   }
                                   else if((param->basetype=="void" && param->pointer_level==1 && param->array_level==0 && (*($3))[i]->arr_level+(*($3))[i]->ptr_level>0) || ((*($3))[i]->basetype=="void" && (*($3))[i]->ptr_level==1 && (*($3))[i]->arr_level==0 && param->array_level==0 && (*($3))[i]->ptr_level>0))
                                   {
                                        ;
                                   }
                                   else if(param->array_level+param->pointer_level>0 && (*($3))[i]->basetype=="int" && (*($3))[i]->ptr_level+(*($3))[i]->arr_level==0 && (*($3))[i]->null_ptr)
                                   {
                                        ;
                                   }
                                   else
                                   {
                                        error(@$,string("Expected  \"")+param->type_str+string("\" but  argument is of type \"")+(*($3))[i]->type_str+string("\""));
                                   }

                              }
                              
                              
                         }
                    }
                    else {
                         error(@$, string("Procedure \"" + $1 + "\" not declared")) ;
                    }
               }
               else if($1 == "printf" || $1 == "scanf") {
                    $$->basetype = "void" ;
                    $$->type.push_back("void") ;
                    $$->type_str = "void" ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
               else {
                    $$->basetype = "int" ;
                    $$->type.push_back("int") ;
                    $$->type_str = "int" ;
                    $$->ptr_level = 0 ;
                    $$->arr_level = 0 ;
                    $$->adr_level = 0 ;
                    $$->lvalue = 0;
               }
          }
     | 
     postfix_expression '.' IDENTIFIER
          { 
               ///handle existance,  basetype, ptr and arr levels
               if ($1->ptr_level == 0 && $1->arr_level == 0 && gst.Entries.count($1->basetype) && gst.Entries[$1->basetype]->varfun == "struct") {
                    if (gst.Entries[$1->basetype]->symbtab->Entries.count($3)) {
                         $$ = new member_astnode($1,new identifier_astnode($3));
                         $$->basetype = gst.Entries[$1->basetype]->symbtab->Entries[$3]->basetype;
                         $$->type = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type;
                         $$->type_str = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type_str;
                         $$->ptr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->pointer_level;
                         $$->arr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->array_level;
                         $$->adr_level = 0;
                         $$->lvalue = 1;
                    }
                    else {
                         error(@$, string("Struct \"") + $1->basetype + string("\" has no member named \"" + $3 + "\"")) ;
                    }
               }
               else {
                    error(@$,string("Left operand of \".\" is not a structure"));
               }
          }
     | 
     postfix_expression PTR_OP IDENTIFIER
          { 
               ///handle existance, basetype, ptr and arr levels
               ///perhaps also something about lval
               if ($1->ptr_level + $1->arr_level == 1 && gst.Entries.count($1->basetype) && gst.Entries[$1->basetype]->varfun == "struct") {
                    if (gst.Entries[$1->basetype]->symbtab->Entries.count($3)) {
                         $$ = new arrow_astnode($1,new identifier_astnode($3));
                         $$->basetype = gst.Entries[$1->basetype]->symbtab->Entries[$3]->basetype;
                         $$->type = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type;
                         $$->type_str = gst.Entries[$1->basetype]->symbtab->Entries[$3]->type_str;
                         $$->ptr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->pointer_level;
                         $$->arr_level = gst.Entries[$1->basetype]->symbtab->Entries[$3]->array_level;
                         $$->adr_level = 0;
                         $$->lvalue = 1;
                    }
                    else {
                         error(@$, string("Struct \"") + $1->basetype + string("\" has no member named \"" + $3 + "\"")) ;
                    }
               }
               else {
                    error(@$,string("Left operand of \"->\" is not a pointer to structure"));
               }

          }
     | 
     postfix_expression INC_OP
          { 
               $$ = new op_unary_astnode("PP",$1);
               $$->basetype = $1->basetype;
               $$->type = $1->type;
               $$->type_str = $1->type_str;
               $$->ptr_level = $1->ptr_level;
               $$->arr_level = $1->arr_level;
               $$->adr_level = $1->adr_level;
               $$->lvalue = 0;
          }
     ;

primary_expression: 
     IDENTIFIER
          { 
               $$ = new identifier_astnode($1);
               if(lst->Entries.find($1)!=lst->Entries.end()){
                    $$->basetype = lst->Entries[$1]->basetype;
                    $$->type = lst->Entries[$1]->type;
                    $$->type_str = lst->Entries[$1]->type_str;
                    $$->ptr_level = lst->Entries[$1]->pointer_level;
                    $$->arr_level = lst->Entries[$1]->array_level;
                    $$->adr_level = 0;
                    $$->lvalue = 1;
               }
               else{
                    ///perhaps global check
                    error(@$,string("Variable \"")+$1+string("\" not declared"));
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

          }
     | 
     FLOAT_CONSTANT
          { 
               $$ = new floatconst_astnode(stof($1));
               $$->basetype = "float";
               $$->type_str = "float";
               $$->type.push_back("float");
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->lvalue = 0;

          }
     | 
     STRING_LITERAL
          { 
               $$ = new stringconst_astnode($1);
               $$->basetype = "string";
               $$->type_str = "string";
               $$->type.push_back("string");
               $$->ptr_level = 0;
               $$->arr_level = 0;
               $$->adr_level = 0;
               $$->lvalue = 0;

          }
     | 
     '(' expression ')'
          { 
               $$ = $2;
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
               if($1=="void"){
                    for(auto x:$2){
                         if(x.size()==1 || x[1]!="*")
                              error(@$,string("Cannot declare variable of type \"void\""));
                    }
               }
               // Case of pointer to a struct within the same struct
               if($1!=struct_name && $1!="int" && $1!="float" && $1!="void" && $1!="string" && gst.Entries.find($1)==gst.Entries.end()){
                    error(@$,string("\"")+$1+string("\" is not defined"));
               }
          }
     ;


declarator_list: 
     declarator
          {
               
               lEntry->setSize() ;
               lEntry->offset = lOffset-lEntry->size ;
               lEntry->scope = "local" ;
               lOffset -= lEntry->size ;
               if (lEntry->basetype == struct_name && lEntry->array_level + lEntry->pointer_level == 0) {
                    error(@$,string("\"")+lEntry->basetype+string("\" is not defined"));
               }
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


