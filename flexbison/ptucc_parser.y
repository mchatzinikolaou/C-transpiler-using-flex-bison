%{
#include <stdarg.h>
#include <stdio.h>
#include "cgen.h"

extern int yylex(void);
extern int line_num;
%}

%union
{
	char* str;
	// int boolean;
}

%token <str> IDENT
%token <str> POSINT
%token <str> REAL
%token <str> STRING
%token <str> BOOL


%left <str> RELATIONAL
%left KW_AND
%left KW_DIV
%left KW_MOD
%left KW_OR
%left TK_EQUAL
%left TK_MULTIPLY


%right KW_NOT
%right <str> TK_SIGN

%token STORE
%token KW_TYPE
%token KW_PROGRAM
%token KW_BEGIN
%token KW_END
%token KW_FUNC
%token KW_PROC
%token KW_RESULT
%token KW_ARRAY
%token KW_DO
%token KW_GOTO
%token <str> KW_RETURN
%token KW_BOOLEAN
%token KW_ELSE
%token KW_IF
%token KW_OF
%token KW_REAL
%token KW_THEN
%token KW_CHAR
%token KW_FOR
%token KW_INTEGER
%token KW_REPEAT
%token KW_UNTIL
%token KW_VAR
%token KW_WHILE
%token KW_TO
%token KW_DOWNTO

%start program


%type <str>  dimensions dimension single_argument expression
%type <str> optional_prologue argument_list
%type <str> program_decl body statements statement_list
%type <str> statement proc_call arguments routine_args
%type <str> arglist  typedefs definitions definition
%type <str>  variable_declarations variable_list variable identifiers  array simple_var_type pointer
%type <str>  function_declarations proceedure_declarations proceedure_declaration function_declaration
%type <str> func_arg   function_body store array_call 
%type <str>  control_statements if_statements for_statements while_statements control_body
%%

program:  program_decl optional_prologue body '.'
{ 
	/* We have a successful parse!
		Check for any errors and generate output.
	*/
	if(yyerror_count==0) {
		puts(c_prologue);
		printf("/* program  %s */ \n\n", $1);
		printf("#define true 1\n#define false 0\n");
		printf("%s\n",$2);
		printf("int main() %s \n", $3);
	}
};

optional_prologue: 									{ $$ = ""; }
			| variable_declarations 		optional_prologue		{ $$ = template("%s %s", $1,$2); };
			| function_declarations 		optional_prologue		{ $$ = template("%s %s", $1,$2); };
			| proceedure_declarations 	optional_prologue		{ $$ = template("%s %s", $1,$2); };
			| typedefs 			optional_prologue		{ $$ = template("%s %s", $1,$2); };


proceedure_declarations: 	proceedure_declaration 				{$$=$1;}
			   	|proceedure_declarations ';' proceedure_declaration 	{$$ = template("%s;%s", $1,$3);};

function_declarations: 		function_declaration 					{$$=$1;}
				|function_declarations 	';' function_declaration 		{$$ = template("%s;%s", $1,$3);};


proceedure_declaration: 	KW_PROC IDENT '(' routine_args ')' ';' optional_prologue body ';'	{$$=template("void %s(%s)\n{\n%s\n%s}",$2,$4,$7,$8);}


function_declaration: 	KW_FUNC IDENT '(' routine_args ')'':' array  simple_var_type  ';'	optional_prologue function_body ';'	{$$=template("%s* %s(%s)\n{\n%s* result ;\n%s\n%s}",$8,$2,$4,$8,$10,$11);}
			|KW_FUNC IDENT '(' routine_args ')'':' pointer simple_var_type   ';' optional_prologue function_body ';'	{$$=template("%s* %s(%s)\n{\n%s* result ;\n%s\n%s}",$8,$2,$4,$8,$10,$11);}
			|KW_FUNC IDENT '(' routine_args ')'':' simple_var_type  ';' optional_prologue function_body ';'		{$$=template("%s %s(%s)\n{\n%s result ;\n%s\n%s}",$7,$2,$4,$7,$9,$10);}


routine_args: 								{$$="";}
			|argument_list					{$$=$1;}

argument_list:  	func_arg					{$$=template("%s",$1);}
			| argument_list ';' func_arg 			{$$=template("%s,%s",$1,$3);}


func_arg:  	identifiers ':' array  simple_var_type  			{$$=template("%s %s %s",$4,$1,$3);}
		|identifiers ':' pointer simple_var_type 			{$$=template("%s* %s",$4,$1);}
		|identifiers ':' simple_var_type 				{$$=template("%s %s",$3,$1);}


variable_declarations: 	KW_VAR  variable_list ';'				{$$=template("%s;\n\n",$2);}

variable_list: 		variable 					{$$=template("%s",$1);}
			| variable_list ';' variable 			{$$=template("%s;%s",$1,$3);}

variable:  		identifiers ':' array  simple_var_type  		{$$=template("%s %s %s",$4,$1,$3);}
			|identifiers ':' pointer simple_var_type 		{$$=template("%s* %s",$4,$1);}
			|identifiers ':' simple_var_type 			{$$=template("%s %s",$3,$1);}

identifiers: 		IDENT 						{$$=template("%s",$1);}
			|identifiers ',' IDENT				{$$=template("%s,%s",$1,$3);}

array:  	 		KW_ARRAY dimensions KW_OF  		{ $$ =template("%s" ,$2); }

pointer: 		KW_ARRAY KW_OF 		 		{ $$=""; }

dimensions: 		dimension 					{$$ = template("%s",$1);}
			|dimensions dimension 			{$$ = template("%s %s", $1,$2); };

array_call: 		IDENT dimensions				{$$ = template("%s%s",$1,$2);}


function_body: 		KW_BEGIN statements  KW_END	{$$=template("\n%s \n result;\n",$2); }

body : 			KW_BEGIN statements KW_END 	{ $$ = template("{\n %s \n }\n", $2); };

statements: 				        			{ $$ = "";}
statements:		statement_list				{ $$ = $1;}

statement_list: 		statement       				{ $$ = $1;}
			|statement_list ';' statement  		{ $$ = template("%s %s", $1,$3);}


/*Here we put the body of the program*/
statement: 		proc_call  				{ $$ = template("%s;\n", $1); }
			|store 					{ $$ = template("%s;\n",$1); }
			|control_statements			{$$ = template("%s;\n",$1); }
			|KW_RETURN				{$$=$1;}
/*Here we put the body of the program*/


/*fun_statements: 				        			{ $$ = "";}
fun_statements:	fun_statement_list				{ $$ = $1;}

fun_statement_list: 	fun_statement       				{ $$ = $1;}
			|fun_statement_list ';' fun_statement  		{ $$ = template("%s %s", $1,$3);}


/*Here we put the body of the program*//*
fun_statement: 		statement
			|KW_RETURN				{$$=$1;}*/



typedefs:  		KW_TYPE definitions ';' 			{ $$ = template("%s;\n\n",$2);}

definitions: 		definition 			   	{ $$ = template("%s",$1);}
			|definitions ';' definition   		{ $$ = template("%s;\n%s",$1,$3);}

definition: 		IDENT TK_EQUAL array  simple_var_type 	{ $$ = template("typedef %s %s %s",$4,$1,$3);}
			|IDENT TK_EQUAL pointer simple_var_type 	{ $$ = template("typedef %s* %s",$4,$1);}
			|IDENT TK_EQUAL simple_var_type 		{ $$ = template("typedef %s %s",$3,$1);}


store: 			IDENT STORE expression		{ $$ = template("%s=%s",$1,$3);}
			|KW_RESULT STORE expression		{ $$ = template("result=%s",$3);}
			|array_call STORE expression 		{ $$ = template("%s=%s",$1,$3);}

proc_call: 		IDENT '(' arguments ')' 			{ $$ = template("%s(%s)", $1, $3); };

arguments :							{ $$ = ""; }
	 	  	| arglist 				{ $$ = $1; };

arglist: 			expression				{ $$ = $1; }
       			| arglist ',' expression 			{ $$ = template("%s,%s", $1, $3); };


dimension:		'[' POSINT ']' 				{ $$= template("[%s]",$2);}

program_decl : 		KW_PROGRAM IDENT ';'  		{ $$ = $2; };


control_statements: 	if_statements 				{$$=$1;}
			|for_statements 			{$$=$1;}
			|while_statements 			{$$=$1;}

if_statements:		KW_IF expression KW_THEN control_body				{$$=template("if(%s){\n%s}",$2,$4);}
			|KW_IF expression KW_THEN control_body KW_ELSE control_body	{$$=template("if(%s){\n%s}else{\n%s}",$2,$4,$6);}
			/*|KW_IF expression KW_THEN control_body KW_ELSE if_statements	{$$=template("if(%s){\n%s}else{\n%s}",$2,$4,$6);}*/


for_statements:		KW_FOR IDENT STORE expression KW_TO expression KW_DO control_body 		{$$=template("for(%s=%s;!%s;%s++){\n%s}",$2,$4,$6,$2,$8);}
			|KW_FOR IDENT STORE expression KW_DOWNTO expression KW_DO control_body 	{$$=template("for(%s=%s;!%s;%s--){\n%s}",$2,$4,$6,$2,$8);}

while_statements:	KW_WHILE expression KW_DO control_body 		{$$=template("while(%s){\n%s}",$2,$4);}
			|KW_REPEAT control_body KW_UNTIL  expression 	{$$=template("do{\n%s}while(!%s)",$2,$4);}



control_body: 	KW_BEGIN statements KW_END	{ $$ = template("\n %s; \n", $2); }

expression: 		single_argument			{ $$ = template("%s",$1);}
			/*|type_cast expression			{ $$ = template("%s%s",$1,$2);}*/
			|expression TK_MULTIPLY expression	{$$ = template("%s*%s",$1,$3);}	
			|expression KW_DIV expression		{ $$ = template("%s/%s",$1,$3);}
			|expression TK_SIGN expression		{ $$ = template("%s%s%s",$1,$2,$3);}
			|expression KW_MOD expression	{ $$ = template("%s%s%s",$1,"%",$3);}
			|expression TK_EQUAL expression	{ $$ = template("%s==%s",$1,$3);}
			|expression RELATIONAL expression	{ $$ = template("%s%s%s",$1,$2,$3);}
			|expression KW_AND expression	{ $$ = template("%s&&%s",$1,$3);}
			|expression KW_OR expression		{ $$ = template("%s||%s",$1,$3);}
			|'('expression')'				{ $$ = template("(%s)",$2);}
			

single_argument: 	POSINT		{$$=$1;}
			|REAL 		{$$=$1;}
			|IDENT 		{$$=$1;}
			|KW_NOT IDENT{ $$ = template("!%s",$2);}
			|TK_SIGN IDENT{ $$ = template("%s%s",$1,$2);}
			|proc_call 	{$$=$1;}
			|BOOL 		{$$=$1;}
			|STRING 	{$$ = string_ptuc2c($1); }
			|array_call	{$$=$1;}
			|KW_RESULT 	{$$=template("result");}


simple_var_type: 	KW_INTEGER				{ $$ = template("int");}
			|KW_BOOLEAN				{ $$ = template("int");}
			|KW_REAL				{ $$ = template("double");}
			|KW_CHAR				{ $$ = template("char");}


	
			/*Maybe change idents to expressions*/
/*type_cast: 		|(' simple_var_type ')'
			|'(' KW_ARRAY KW_OF KW_INTEGER ')'  	{$$ = template("(int*)");}
			|'(' KW_ARRAY KW_OF KW_REAL ')'  	{$$ = template("(double*)");}
			|'(' KW_ARRAY KW_OF KW_BOOLEAN ')' 	{$$ = template("(int*)");}
			Maybe change to ...simple var type ...| ...pointer simple_var_type ....
			*/		
%%
