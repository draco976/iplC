%{
// This part goes directly into the generated parser

#include "scanner.hh"
#include "parser.tab.hh"

// YY_DECL is bound to the type of the scanner. The default is 
// #define YY_DECL int Scanner::yylex()
// which is generated anyway.

//If you want the type of the generated scanner to be different, do this

#undef  YY_DECL
#define YY_DECL int IPL::Scanner::yylex( IPL::Parser::semantic_type * const lval, IPL::Parser::location_type *loc )

//We want these to be the first action after a token is recognized. 

#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

// token_type is a short hand for IPL::Parser::token

using token = IPL::Parser::token;

%}


/* %option debug */
%option nodefault
%option yyclass="Scanner"
%option noyywrap
%option c++
%option yylineno

%%

%{ /** Code executed at the beginning of yylex **/

      yylval = lval;

%}

[ \t]                                      ; //skip
[\n]                                      loc->lines(); //skip
"/*"([^*]|\*+[^*/])*\*+"/"                   ;  //skip
\"(\\\\|\\\"|\\t|\\n|[^"\\])*\"             {
       yylval->emplace< std::string >( YYText() );
       return token::STRING_LITERAL ;
}
"||"                                        {
       yylval->emplace< std::string >( YYText() );
       return token::OR_OP ;
}
"&&"                                        {
       yylval->emplace< std::string >( YYText() );
       return token::AND_OP ;
}
"=="                                        {
       yylval->emplace< std::string >( YYText() );
       return token::EQ_OP ;
}
"!="                                        {
       yylval->emplace< std::string >( YYText() );
       return token::NE_OP ;
}
"<="                                        {
       yylval->emplace< std::string >( YYText() );
       return token::LE_OP ;
}
">="                                        {
       yylval->emplace< std::string >( YYText() );
       return token::GE_OP ;
}
"++"                                        {
       yylval->emplace< std::string >( YYText() );
       return token::INC_OP ;
}
"->"                                        {
       yylval->emplace< std::string >( YYText() );
       return token::PTR_OP ;
}
";"                                         return ';' ;
","                                         return ',' ;
"("                                         return '(' ;
")"                                         return ')' ;
"{"                                         return '{' ;
"}"                                         return '}' ;
"["                                         return '[' ;
"]"                                         return ']' ;
"<"                                         return '<' ;
">"                                         return '>' ;
"!"                                         return '!' ;
"&"                                         return '&' ;
"*"                                         return '*' ;
"+"                                         return '+' ;
"-"                                         return '-' ;
"/"                                         return '/' ;
"="                                         return '=' ;
"."                                         return '.' ;
"main" {
      yylval->emplace< std::string >( YYText() );
      return token::MAIN ;
      }
"printf" {
      yylval->emplace< std::string >( YYText() );
      return token::PRINTF ;
      }
"struct" {
      yylval->emplace< std::string >( YYText() );
      return token::STRUCT ;
      }
"void"   {
      yylval->emplace< std::string >( YYText() );
      return token::VOID ;
      }
"int" {
      yylval->emplace< std::string >( YYText() );
      return token::INT ;
      }
"float"   {
      yylval->emplace< std::string >( YYText() );
      return token::FLOAT ;
      }
"return"  {
      yylval->emplace< std::string >( YYText() );
      return token::RETURN ;
      }
"if"  {
      yylval->emplace< std::string >( YYText() );
      return token::IF ;
      }
"else"  {
      yylval->emplace< std::string >( YYText() );
      return token::ELSE ;
      }
"for" {
      yylval->emplace< std::string >( YYText() );
            return token::FOR ;     
             }
"while"                                 {
      yylval->emplace< std::string >( YYText() );   
         return token::WHILE ;
      }
[1-9][0-9]*                                  {
      yylval->emplace< std::string >( YYText() );
      return token::INT_CONSTANT ;
      }
"0"[bB][01]*                                {
      yylval->emplace< std::string >( YYText() );
      return token::INT_CONSTANT ;
      }
"0"[0-7]*                                   {
      yylval->emplace< std::string >( YYText() );
      return token::INT_CONSTANT ;
      }
"0"[xX][0-9a-fA-F]*                       {
      yylval->emplace< std::string >( YYText() );
      return token::INT_CONSTANT ;
      }
([0-9]+[.][0-9]*|[0-9]*[.][0-9]+)(e[+-]?[0-9]+)?                {
      yylval->emplace< std::string >( YYText() );
      return token::FLOAT_CONSTANT ;
      }
[a-zA-Z_][0-9a-zA-Z_]*                      {
      yylval->emplace< std::string >( YYText() );
      return token::IDENTIFIER ;    
      }
<<EOF>>                                  yyterminate();
.	{
      yylval->emplace< std::string >( YYText() );
      return token::OTHERS;    
      }			                          


%%

